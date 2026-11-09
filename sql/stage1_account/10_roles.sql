-- =============================================================================
-- Stage 1.0 - Project role
-- Source: workspace SQL/01_account_setup.sql (section 1)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS DEMO_19865_ROLE
    COMMENT = 'Role for GNN Supply Chain Risk project';

-- Role hierarchy: SYSADMIN (and therefore ACCOUNTADMIN) inherits the project role.
GRANT ROLE DEMO_19865_ROLE TO ROLE SYSADMIN;

-- Grant the project role to whoever runs the kit. A scripting block is used instead of
-- SET + IDENTIFIER($var), which fails when this file runs via EXECUTE IMMEDIATE FROM.
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE 'GRANT ROLE DEMO_19865_ROLE TO USER "' || REPLACE(CURRENT_USER(), '"', '""') || '"';
  RETURN 'DEMO_19865_ROLE granted to ' || CURRENT_USER();
END;
$$;
