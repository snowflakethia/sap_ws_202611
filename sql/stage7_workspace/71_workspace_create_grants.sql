-- =============================================================================
-- Stage 7.1 - Shared workspace DEMO_19865 + grants
-- =============================================================================
-- After this script, deploy.sh uploads training_kit/workspace/** into the workspace's
-- live version and runs ALTER WORKSPACE ... COMMIT so the files are published.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE WORKSPACE IF NOT EXISTS DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865
    COMMENT = 'GNN Supply Chain Risk - setup scripts, notebooks and sample data';

-- Same grant as the source (03_demo_reader_role.sql): the project role can edit.
GRANT WRITE ON WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865
    TO ROLE DEMO_19865_ROLE;
