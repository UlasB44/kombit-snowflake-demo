-- ============================================================================
-- KOMBIT Demo: Row Access Policies
-- Municipality-level data isolation
-- ============================================================================

USE ROLE SYSADMIN;

-- Row Access Policy: Users only see data from their municipality
CREATE OR REPLACE ROW ACCESS POLICY KOMBIT_GOVERNANCE.POLICIES.KOMMUNE_DATA_ACCESS
AS (kommune_id VARCHAR) RETURNS BOOLEAN ->
    CASE
        -- Admins and analysts see all data
        WHEN CURRENT_ROLE() IN ('KOMBIT_ADMIN', 'KOMBIT_ANALYST', 'KOMBIT_DATA_STEWARD', 'KOMBIT_AUDITOR') 
            THEN TRUE
        -- Municipality roles see only their data
        WHEN CURRENT_ROLE() = 'KOMBIT_COPENHAGEN_ROLE' AND UPPER(kommune_id) = 'COPENHAGEN' THEN TRUE
        WHEN CURRENT_ROLE() = 'KOMBIT_AARHUS_ROLE' AND UPPER(kommune_id) = 'AARHUS' THEN TRUE
        WHEN CURRENT_ROLE() = 'KOMBIT_ODENSE_ROLE' AND UPPER(kommune_id) = 'ODENSE' THEN TRUE
        WHEN CURRENT_ROLE() = 'KOMBIT_AALBORG_ROLE' AND UPPER(kommune_id) = 'AALBORG' THEN TRUE
        WHEN CURRENT_ROLE() = 'KOMBIT_ESBJERG_ROLE' AND UPPER(kommune_id) = 'ESBJERG' THEN TRUE
        ELSE FALSE
    END;

-- Example: Apply to a table
-- ALTER TABLE schema.CITIZENS ADD ROW ACCESS POLICY KOMBIT_GOVERNANCE.POLICIES.KOMMUNE_DATA_ACCESS ON (KOMMUNE_ID);
