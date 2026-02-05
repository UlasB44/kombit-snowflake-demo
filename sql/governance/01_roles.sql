-- ============================================================================
-- KOMBIT Demo: Roles Setup
-- Creates hierarchical RBAC structure for multi-tenant municipality access
-- ============================================================================

USE ROLE SECURITYADMIN;

-- Administrative Roles
CREATE ROLE IF NOT EXISTS KOMBIT_ADMIN COMMENT = 'Full admin access to all KOMBIT data';
CREATE ROLE IF NOT EXISTS KOMBIT_ANALYST COMMENT = 'Cross-municipality analyst with masked PII';
CREATE ROLE IF NOT EXISTS KOMBIT_DATA_STEWARD COMMENT = 'Data governance and policy management';
CREATE ROLE IF NOT EXISTS KOMBIT_AUDITOR COMMENT = 'Read-only audit access';

-- Municipality-specific Roles
CREATE ROLE IF NOT EXISTS KOMBIT_COPENHAGEN_ROLE COMMENT = 'Copenhagen municipality data access';
CREATE ROLE IF NOT EXISTS KOMBIT_AARHUS_ROLE COMMENT = 'Aarhus municipality data access';
CREATE ROLE IF NOT EXISTS KOMBIT_ODENSE_ROLE COMMENT = 'Odense municipality data access';
CREATE ROLE IF NOT EXISTS KOMBIT_AALBORG_ROLE COMMENT = 'Aalborg municipality data access';
CREATE ROLE IF NOT EXISTS KOMBIT_ESBJERG_ROLE COMMENT = 'Esbjerg municipality data access';

-- Role Hierarchy
GRANT ROLE KOMBIT_COPENHAGEN_ROLE TO ROLE KOMBIT_ADMIN;
GRANT ROLE KOMBIT_AARHUS_ROLE TO ROLE KOMBIT_ADMIN;
GRANT ROLE KOMBIT_ODENSE_ROLE TO ROLE KOMBIT_ADMIN;
GRANT ROLE KOMBIT_AALBORG_ROLE TO ROLE KOMBIT_ADMIN;
GRANT ROLE KOMBIT_ESBJERG_ROLE TO ROLE KOMBIT_ADMIN;

GRANT ROLE KOMBIT_ADMIN TO ROLE SYSADMIN;
GRANT ROLE KOMBIT_ANALYST TO ROLE SYSADMIN;
GRANT ROLE KOMBIT_DATA_STEWARD TO ROLE SYSADMIN;
GRANT ROLE KOMBIT_AUDITOR TO ROLE SYSADMIN;
