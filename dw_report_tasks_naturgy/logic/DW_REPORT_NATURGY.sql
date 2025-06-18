-- Schema Creation
CREATE SCHEMA IF NOT EXISTS dw_naturgy;
SET search_path TO dw_naturgy;

-- Dimension: dim_atividades
CREATE TABLE dw_naturgy.dim_atividades (
  id_atividade SERIAL PRIMARY KEY,
  natureza VARCHAR,
  atividade VARCHAR,
  cod_catalogo VARCHAR,
  cod_procedimento VARCHAR,
  criticidade VARCHAR,
  desc_atividade VARCHAR(255),
  frequencia VARCHAR,
  input VARCHAR,
  kpis VARCHAR(255),
  normativa VARCHAR,
  output VARCHAR(255),
  responsabilidades VARCHAR(255),
  slas INTERVAL,
  tipo VARCHAR,
  tipo_atividade VARCHAR,
  tmo_min INT,
  vol_mensal INT,
  vol_anual_prev INT,
  status VARCHAR,
  periodo_real VARCHAR
);

-- Dimension: dim_cliente
CREATE TABLE dw_naturgy.dim_cliente (
  id_cliente SERIAL PRIMARY KEY,
  meio_comunicacao VARCHAR,
  tempo_comunicacao TIME,
  urg_com VARCHAR,
  customer VARCHAR,
  nivel_engajamento VARCHAR,
  coordenador VARCHAR
);

-- Dimension: dim_colaborador
CREATE TABLE dw_naturgy.dim_colaborador (
  id_colaborador SERIAL PRIMARY KEY,
  nome_colaborador VARCHAR,
  nome_ver VARCHAR,
  perfil VARCHAR,
  gestor VARCHAR
);

-- Dimension: dim_organizacional
CREATE TABLE  dw_naturgy.dim_organizacional (
  id_organizacional SERIAL PRIMARY KEY,
  id_nts INT,
  diretoria VARCHAR,
  gerencia VARCHAR,
  area VARCHAR,
  celula VARCHAR,
  processo VARCHAR,
  sub_processo VARCHAR
);

-- Dimension: dim_calendario
CREATE TABLE dw_naturgy.dim_calendario (
  data DATE PRIMARY KEY,
  ano INT,
  mes INT,
  mes_nome VARCHAR,
  dia INT,
  dia_nome VARCHAR,
  semana_mes INT
);

-- Dimension: dim_matriz
CREATE TABLE  dw_naturgy.dim_matriz (
  id_rhn VARCHAR PRIMARY KEY,
  id_atividade INT REFERENCES dw_naturgy.dim_atividades(id_atividade),
  id_cliente INT REFERENCES dw_naturgy.dim_cliente(id_cliente),
  id_colaborador INT REFERENCES dw_naturgy.dim_colaborador(id_colaborador),
  id_organizacional INT REFERENCES dw_naturgy.dim_organizacional(id_organizacional)
);

-- Fact table: fat_atividades_realizadas
CREATE TABLE  dw_naturgy.fat_atividades_realizadas (
  id_bitrix24 INT NOT NULL PRIMARY KEY,
  atividade_b24 VARCHAR(255),
  inicio_atividade_br24 DATE REFERENCES dw_naturgy.dim_calendario(data),
  conclusao_br24 DATE REFERENCES dw_naturgy.dim_calendario(data),
  dia INT,
  semana_mes INT,
  faturamento NUMERIC,
  hora_atividade_br24 INT,
  pessoa_id_br24 INT,
  pessoa_responsavel_br24 VARCHAR,
  qtd_realizadas_br24 INT,
  id_rhn VARCHAR REFERENCES dim_matriz(id_rhn),
  sla INT,
  status_br24 VARCHAR,
  tempo_gasto_br24 TIME,
  tipo_atividade VARCHAR
);
