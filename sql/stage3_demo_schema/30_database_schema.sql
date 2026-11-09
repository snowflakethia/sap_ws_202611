-- =============================================================================
-- Stage 3.0 - Project database and schema (re-asserted; created in Stage 1.2)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS DEMO_19865_DB;
CREATE SCHEMA IF NOT EXISTS DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

GRANT OWNERSHIP ON DATABASE DEMO_19865_DB
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;
