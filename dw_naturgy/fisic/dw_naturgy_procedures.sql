
-- Procedure SCD Matriz Sipoc
    CREATE OR REPLACE PROCEDURE dw_naturgy.sp_aplica_scd2_matriz()
    LANGUAGE plpgsql
    AS $procedure$
    DECLARE
        record dw_naturgy.stg_matriz%ROWTYPE;  -- 🔹 declara record como tipo da linha
    BEGIN
        FOR record IN SELECT * FROM dw_naturgy.stg_matriz
        LOOP
            -- Verifica se já existe ativo na dim_matriz
            IF NOT EXISTS (
                SELECT 1
                FROM dw_naturgy.dim_matriz d
                WHERE d.id_rhn = record.id_rhn
                AND d.atividade = record.atividade
                AND d.is_active = TRUE
            ) THEN
                -- Insere novo registro
                INSERT INTO dw_naturgy.dim_matriz (
                    status, id_rhn, id_nts, atividade, frequencia,
                    diretoria, gerencia, area, celula, processo,
                    sub_processo, unitario, tmo_min, vol_mensal,
                    data_inicio, is_active
                )
                VALUES (
                    record.status, record.id_rhn, record.id_nts, record.atividade, record.frequencia,
                    record.diretoria, record.gerencia, record.area, record.celula, record.processo,
                    record.sub_processo, record.unitario, record.tmo_min, record.vol_mensal,
                    NOW(), TRUE
                );
            ELSE
                -- Verifica se houve alteração nos campos
                IF EXISTS (
                    SELECT 1
                    FROM dw_naturgy.dim_matriz d
                    WHERE d.id_rhn = record.id_rhn
                    AND d.atividade = record.atividade
                    AND d.is_active = TRUE
                    AND (
                            d.status IS DISTINCT FROM record.status OR
                            d.id_nts IS DISTINCT FROM record.id_nts OR
                            d.frequencia IS DISTINCT FROM record.frequencia OR
                            d.diretoria IS DISTINCT FROM record.diretoria OR
                            d.gerencia IS DISTINCT FROM record.gerencia OR
                            d.area IS DISTINCT FROM record.area OR
                            d.celula IS DISTINCT FROM record.celula OR
                            d.processo IS DISTINCT FROM record.processo OR
                            d.sub_processo IS DISTINCT FROM record.sub_processo OR
                            d.unitario IS DISTINCT FROM record.unitario OR
                            d.tmo_min IS DISTINCT FROM record.tmo_min OR
                            d.vol_mensal IS DISTINCT FROM record.vol_mensal
                        )
                ) THEN
                    -- Fecha registro atual
                    UPDATE dw_naturgy.dim_matriz
                    SET is_active = FALSE,
                        data_fim = NOW()
                    WHERE id_rhn = record.id_rhn
                    AND atividade = record.atividade
                    AND is_active = TRUE;

                    -- Insere novo registro ativo
                    INSERT INTO dw_naturgy.dim_matriz (
                        status, id_rhn, id_nts, atividade, frequencia,
                        diretoria, gerencia, area, celula, processo,
                        sub_processo, unitario, tmo_min, vol_mensal,
                        data_inicio, is_active
                    )
                    VALUES (
                        record.status, record.id_rhn, record.id_nts, record.atividade, record.frequencia,
                        record.diretoria, record.gerencia, record.area, record.celula, record.processo,
                        record.sub_processo, record.unitario, record.tmo_min, record.vol_mensal,
                        NOW(), TRUE
                    );
                END IF;
            END IF;
        END LOOP;
    END;
    $procedure$;

-- Function call -> Procedure SCD Matriz Sipoc
    CREATE OR REPLACE FUNCTION dw_naturgy.trg_aplica_scd2_matriz()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $function$
    BEGIN
        -- Chama a procedure corretamente
        CALL dw_naturgy.sp_aplica_scd2_matriz();
        RETURN NULL;
    END;
    $function$;

-- Trigger execute function -> trg_aplica_scd2_matriz
    CREATE TRIGGER trg_after_insert_update_stg_matriz AFTER
    INSERT
    OR
    UPDATE ON dw_naturgy.stg_matriz
    FOR EACH STATEMENT EXECUTE FUNCTION dw_naturgy.trg_aplica_scd2_matriz()

--- Function to insert ativdades in fat
    CREATE OR REPLACE FUNCTION dw_naturgy.insert_data_in_fat_faturamento()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $function$
    DECLARE
        regex_matches TEXT[];
        v_valor_unitario NUMERIC;
        id_rhn_result TEXT;
        qtd_realizadas INT;
        v_id_matriz INT;
    BEGIN
        IF NEW.real_status = 5 THEN
            -- Extrai RHN e quantidade do título
            SELECT REGEXP_MATCHES(NEW.title, '([A-Z]+)\s*-?\s*(\d+)\s*-?\s*(\d+)', 'i')
            INTO regex_matches;

            IF regex_matches IS NOT NULL THEN
                id_rhn_result := UPPER(regex_matches[1]) || ' - ' || regex_matches[2]::INTEGER;
                qtd_realizadas := COALESCE(regex_matches[3], '0')::INTEGER;
            ELSE
                id_rhn_result := 'RHN - NAO CATALOGADO';
                qtd_realizadas := 0;
            END IF;

            -- Busca registro mais recente da matriz ativo
            SELECT id_matriz, unitario
            INTO v_id_matriz, v_valor_unitario
            FROM dw_naturgy.dim_matriz
            WHERE id_rhn = id_rhn_result
            AND is_active = TRUE
            ORDER BY data_inicio DESC
            LIMIT 1;

            IF NOT FOUND THEN
                v_id_matriz := NULL;
                v_valor_unitario := 0;
            END IF;

            -- Se já existir fato para o mesmo task_id, atualiza
            IF EXISTS (SELECT 1 FROM dw_naturgy.fat_faturamento WHERE id_atividade = NEW.task_id) THEN
                UPDATE dw_naturgy.fat_faturamento
                SET
                    data_conclusao_atividade = CAST(NEW.closed_date AS DATE),
                    valor_unitario = v_valor_unitario,
                    qtds_realizadas = qtd_realizadas,
                    data_inicio_atividade = CAST(NEW.date_start AS DATE),
                    id_matriz = v_id_matriz
                WHERE id_atividade = NEW.task_id;
            ELSE
                -- Senão, insere novo
                INSERT INTO dw_naturgy.fat_faturamento (
                    data_conclusao_atividade,
                    valor_unitario,
                    qtds_realizadas,
                    data_inicio_atividade,
                    id_atividade,
                    id_matriz
                ) VALUES (
                    CAST(NEW.closed_date AS DATE),
                    v_valor_unitario,
                    qtd_realizadas,
                    CAST(NEW.date_start AS DATE),
                    NEW.task_id,
                    v_id_matriz
                );
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$;

-- Trigger execute function -> insert_data_in_fat_faturamento
    CREATE TRIGGER trg_insert_fat_faturamento AFTER
    INSERT
        OR
    UPDATE
        ON
        dw_naturgy.dim_atividade FOR EACH ROW EXECUTE FUNCTION dw_naturgy.insert_data_in_fat_faturamento()