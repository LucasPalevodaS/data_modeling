-- DROP SCHEMA dw_nts;

CREATE SCHEMA dw_nts AUTHORIZATION "admin";

-- dw_nts.dim_atividade definição

-- Drop table

-- DROP TABLE dw_nts.dim_atividade;

CREATE TABLE dw_nts.dim_atividade (
	title varchar,
	task_id int4 NOT NULL,
	status_changed_date date,
	responsible_login int4,
	responsible_last_name varchar,
	responsible_id varchar,
	real_status INT,
	deadline timestamp,
	date_start timestamp,
	created_by_second_name varchar,
	created_by_name varchar,
	created_by_login int4,
	created_by_last_name varchar,
	created_by int4,
	closed_date timestamp,
	closed_by varchar,
	changed_date timestamp,
	changed_by varchar,
	responsible_name varchar,
	status_changed_by int4,
	created_date timestamp,
	time_spent_in_logs timestamp,
	responsible_second_name varchar,
	CONSTRAINT dim_atividade_pkey PRIMARY KEY (task_id)
);


-- dw_nts.dim_calendario definição

-- Drop table

-- DROP TABLE dw_nts.dim_calendario;

CREATE TABLE dw_nts.dim_calendario (
	"data" date NOT NULL,
	ano int4,
	mes int4,
	mes_nome varchar,
	dia int4,
	dia_nome varchar,
	semana_mes int4,
	CONSTRAINT dim_calendario_pkey PRIMARY KEY (data)
);

-- dw_nts.dim_catalogo definição

-- Drop table

-- DROP TABLE dw_nts.dim_catalogo;

CREATE TABLE dw_nts.dim_matriz (
	id_matriz int4 NOT NULL,
	status varchar,
	id_rhn varchar NOT NULL,
	id_nts varchar,
	atividade varchar,
	frequencia varchar,
	diretoria varchar,
	gerencia varchar,
	area varchar,
	celula varchar,
	processo varchar,
	sub_processo varchar,
	unitario numeric,
	tmo_min int4,
	vol_mensal int4,
	data_modificacao TIMESTAMP NOT NULL DEFAULT NOW(),
	is_active,
	CONSTRAINT dim_catalogo_pkey PRIMARY KEY (id_matriz)
);

-- Staging Area Matriz Sipoc
CREATE TABLE dw_naturgy.stg_matriz (
    id_matriz INT4 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR,
    id_rhn VARCHAR NOT NULL UNIQUE,
    id_nts VARCHAR,
    atividade VARCHAR,
    frequencia VARCHAR,
    diretoria VARCHAR,
    gerencia VARCHAR,
    area VARCHAR,
    celula VARCHAR,
    processo VARCHAR,
    sub_processo VARCHAR,
    unitario NUMERIC,
    tmo_min INT4,
    vol_mensal INT4,
    data_modificacao TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Dim Matriz Sipoc
CREATE TABLE dw_naturgy.dim_matriz (
    id_matriz INT4 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR,
    id_rhn VARCHAR NOT NULL,
    id_nts VARCHAR,
    atividade VARCHAR,
    frequencia VARCHAR,
    diretoria VARCHAR,
    gerencia VARCHAR,
    area VARCHAR,
    celula VARCHAR,
    processo VARCHAR,
    sub_processo VARCHAR,
    unitario NUMERIC,
    tmo_min INT4,
    vol_mensal INT4,
    data_inicio TIMESTAMP NOT NULL DEFAULT NOW(), 
    data_fim TIMESTAMP,                          
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


-- Fat Faturamento

CREATE TABLE dw_naturgy.fat_faturamento (
	id_fato INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	data_conclusao_atividade date, 
	valor_unitario numeric, 
	qtds_realizadas int4, 
	data_inicio_atividade date, 
	id_atividade int4, 
	id_matriz int4, 
	CONSTRAINT fat_faturamento_pkey PRIMARY KEY (id_fato)
);

-- Constraints FK
ALTER TABLE dw_nts.fat_faturamento ADD CONSTRAINT fat_faturamento_fk_data_inicio_atividade_fkey FOREIGN KEY (data_inicio_atividade) REFERENCES dw_nts.dim_calendario("data");
ALTER TABLE dw_nts.fat_faturamento ADD CONSTRAINT fat_faturamento_fk_dim_atividade_task_id_fkey FOREIGN KEY (id_atividade) REFERENCES dw_nts.dim_atividade(task_id);
ALTER TABLE dw_nts.fat_faturamento ADD CONSTRAINT fat_faturamento_fk_dim_catalogo_id_matriz_fkey FOREIGN KEY (id_matriz) REFERENCES dw_nts.dim_catalogo(id_matriz);