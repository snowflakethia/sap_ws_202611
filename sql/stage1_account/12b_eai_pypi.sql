-- =============================================================================
-- Stage 1.2b - PyPI external access integration (BEST EFFORT)
-- =============================================================================
-- Needed only by optional Lab 4 (retraining the GNN notebook).
-- Trial accounts do NOT support external access ("External access is not supported
-- for trial accounts"). deploy.sh treats a failure here as a WARNING and continues.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DEMO_19865_PIP_INSTALLATION
    ALLOWED_NETWORK_RULES = (DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.PIP_INSTALLATION)
    ENABLED = TRUE
    COMMENT = 'PyPI / PyTorch Geometric egress for the GNN notebook';

GRANT USAGE ON INTEGRATION DEMO_19865_PIP_INSTALLATION TO ROLE DEMO_19865_ROLE;
