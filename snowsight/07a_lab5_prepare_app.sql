-- =============================================================================
-- Lab 5 - make sure the CoCo-built app can start on the first try
--
-- WHEN TO USE: right after CoCo says the app is deployed, before you open it. Safe to run any time.
-- WHAT IT DOES: new Streamlit apps run on the container runtime by default, which installs the packages listed in
--   pyproject.toml. This account has no internet access, so the app must use Snowflake's built-in PyPI mirror.
--   This file attaches that mirror (SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY) to SUPPLY_RISK_DASHBOARD.
--   On the warehouse runtime there is nothing to do, and the file says so.
-- HOW TO RUN: Lab 5 Step 3.0 runs this file straight from the Git repository (no need to open it):
--   EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/snowsight/07a_lab5_prepare_app.sql;
--   Or open it here: role ACCOUNTADMIN, Run All. Then open (or reload) the app.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.PYPI_REPOSITORY_USER TO ROLE DEMO_19865_ROLE;

EXECUTE IMMEDIATE $$
BEGIN
  ALTER STREAMLIT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD
    SET ARTIFACT_REPOSITORIES = (snowflake.snowpark.pypi_shared_repository);
  RETURN 'DONE - container runtime: PyPI mirror attached. Open or reload the app.';
EXCEPTION
  WHEN OTHER THEN
    IF (CONTAINS(SQLERRM, 'only supported by Streamlit applications running in the container runtime')) THEN
      RETURN 'DONE - warehouse runtime: no change needed. Open the app.';
    END IF;
    RETURN 'CHECK - ' || SQLERRM;
END;
$$;
