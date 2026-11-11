#!/bin/bash
# Roda só com o volume vazio (docker-entrypoint-initdb.d). Senhas iguais ao nome do
# usuário: valem só no ambiente local (docs/lld.md, seção 10).
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<'SQL'
CREATE ROLE chat LOGIN PASSWORD 'chat';
CREATE ROLE agents LOGIN PASSWORD 'agents';
CREATE ROLE business LOGIN PASSWORD 'business';
CREATE ROLE business_readonly LOGIN PASSWORD 'business_readonly';

CREATE DATABASE chat OWNER chat;
CREATE DATABASE chat_test OWNER chat;
CREATE DATABASE agents OWNER agents;
CREATE DATABASE business OWNER business;

-- Ninguém conecta num banco que não é o seu: o dono conecta por ser dono;
-- PUBLIC perde o CONNECT padrão.
REVOKE CONNECT ON DATABASE postgres, template1, chat, chat_test, agents, business FROM PUBLIC;
GRANT CONNECT ON DATABASE business TO business_readonly;
SQL

# Somente leitura no Banco de negócio (ADR 0013), inclusive nas tabelas que o
# script de carga criar depois como `business` no schema public.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname business <<'SQL'
GRANT USAGE ON SCHEMA public TO business_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO business_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE business IN SCHEMA public
  GRANT SELECT ON TABLES TO business_readonly;
SQL
