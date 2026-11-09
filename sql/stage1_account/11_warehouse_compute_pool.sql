-- =============================================================================
-- Stage 1.1 - Warehouse and compute pool
-- Source: workspace SQL/01_account_setup.sql (sections 3-4)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS DEMO_19865_WH
    WAREHOUSE_SIZE = SMALL
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for GNN Supply Chain Risk SQL operations';

GRANT OWNERSHIP ON WAREHOUSE DEMO_19865_WH
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;

-- Only used by the optional GNN retraining lab (notebook on Container Runtime).
-- Suspends itself after 10 minutes idle, so it costs nothing until used.
CREATE COMPUTE POOL IF NOT EXISTS DEMO_19865_POOL
    MIN_NODES = 1
    MAX_NODES = 1
    INSTANCE_FAMILY = CPU_X64_M
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    AUTO_SUSPEND_SECS = 600
    COMMENT = 'CPU compute pool for PyTorch Geometric GNN training (GPU unavailable in region)';

GRANT OWNERSHIP ON COMPUTE POOL DEMO_19865_POOL
    TO ROLE DEMO_19865_ROLE COPY CURRENT GRANTS;
