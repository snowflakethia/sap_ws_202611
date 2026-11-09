-- =============================================================================
-- Teardown - removes EVERYTHING the training kit created in this account.
-- Irreversible apart from Time Travel UNDROP on databases. teardown.sh asks first.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Integrations first: they reference network rules inside DEMO_19865_DB.
DROP INTEGRATION IF EXISTS DEMO_19865_PIP_INSTALLATION;

DROP DATABASE IF EXISTS DEMO_SHARED_WORKSPACES;
DROP DATABASE IF EXISTS DEMO_19865_DB;   -- tables, views, stages, search service, semantic view, agent, network rules
DROP DATABASE IF EXISTS S4_ZVENDORINFO_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZMATERIALS_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1;

ALTER COMPUTE POOL IF EXISTS DEMO_19865_POOL STOP ALL;
DROP COMPUTE POOL IF EXISTS DEMO_19865_POOL;
DROP WAREHOUSE IF EXISTS DEMO_19865_WH;

DROP ROLE IF EXISTS DEMO_READER_ROLE;
DROP ROLE IF EXISTS DEMO_19865_ROLE;

REMOVE @~/training_kit/;

SELECT 'Teardown complete' AS STATUS;
