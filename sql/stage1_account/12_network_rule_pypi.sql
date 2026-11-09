-- =============================================================================
-- Stage 1.2 - Project database/schema + PyPI network rule
-- Source: workspace SQL/01_account_setup.sql (sections 2 and 5)
-- The network rule is a schema object, so the database and schema are created here.
-- The external access integration that uses the rule is in 12b_eai_pypi.sql.
-- The source's HANA Cloud rule is not recreated (only Copy_to_Hana.ipynb used it; excluded).
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS DEMO_19865_DB;
CREATE SCHEMA IF NOT EXISTS DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

GRANT OWNERSHIP ON DATABASE DEMO_19865_DB
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;

CREATE OR REPLACE NETWORK RULE DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.PIP_INSTALLATION
    TYPE = HOST_PORT
    MODE = EGRESS
    VALUE_LIST = (
        'pypi.org:443',
        'files.pythonhosted.org:443',
        'download.pytorch.org:443',
        'data.pyg.org:443'
    )
    COMMENT = 'Required for PyTorch Geometric and dependencies';
