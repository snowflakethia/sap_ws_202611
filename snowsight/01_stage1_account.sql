-- =============================================================================
-- STAGE 1 - Account objects: role, warehouse, compute pool, project database
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN. Takes about 1 minute.
-- Runs the shared, tested scripts in sql/stage1_account/ straight from the Git repository.
--
-- CHECKPOINT 1 (expected result of the LAST statement - every row PASS or INFO):
--   S1-A role DEMO_19865_ROLE exists          1                          PASS
--   S1-A warehouse size/auto_suspend/owner    SMALL/300/DEMO_19865_ROLE  PASS
--   S1-A compute pool family/nodes            CPU_X64_M/1-1              PASS
--   S1-B integrations                         DEMO_19865_PIP_INSTALLATION:true -> PASS
--                                             or "none" -> INFO on TRIAL accounts (expected)
--   S1-C key grants to DEMO_19865_ROLE        4 (or 3 on trial accounts) PASS
--   S1-D Cortex cross-region inference        ANY_REGION                 PASS
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage1_account/10_roles.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage1_account/11_warehouse_compute_pool.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage1_account/12_network_rule_pypi.sql;

-- PyPI egress is only needed for optional Lab 4. Trial accounts reject it; that is expected.
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage1_account/12b_eai_pypi.sql;
  RETURN 'PyPI external access integration created';
EXCEPTION
  WHEN OTHER THEN
    RETURN 'INFO (expected on trial accounts): PyPI integration not created. Only optional Lab 4 needs it.';
END;
$$;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage1_account/13_cortex_grants.sql;

-- CHECKPOINT 1
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v1_account.sql;
