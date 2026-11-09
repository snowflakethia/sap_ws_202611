-- =============================================================================
-- Stage 7.0 - Database and schema that hold the shared workspace
-- Source: F9A3UBGT DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE (owner ACCOUNTADMIN)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS DEMO_SHARED_WORKSPACES
    COMMENT = 'Holds shared workspaces for the GNN Supply Chain Risk training';
CREATE SCHEMA IF NOT EXISTS DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE;

GRANT USAGE ON DATABASE DEMO_SHARED_WORKSPACES TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON SCHEMA DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE TO ROLE DEMO_19865_ROLE;
