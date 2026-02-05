-- ============================================================================
-- KOMBIT Demo: Pattern A - Bottom-Up Aggregation
-- 5 Municipality DBs → 1 Aggregated Central DB via Dynamic Tables
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- STEP 1: Create Municipality Databases
-- ============================================================================

CREATE OR REPLACE DATABASE KOMBIT_A_COPENHAGEN COMMENT = 'Copenhagen municipality data';
CREATE OR REPLACE DATABASE KOMBIT_A_AARHUS COMMENT = 'Aarhus municipality data';
CREATE OR REPLACE DATABASE KOMBIT_A_ODENSE COMMENT = 'Odense municipality data';
CREATE OR REPLACE DATABASE KOMBIT_A_AALBORG COMMENT = 'Aalborg municipality data';
CREATE OR REPLACE DATABASE KOMBIT_A_ESBJERG COMMENT = 'Esbjerg municipality data';

-- Aggregated central database
CREATE OR REPLACE DATABASE KOMBIT_A_AGGREGATED COMMENT = 'Central aggregated view of all municipalities';

-- ============================================================================
-- STEP 2: Create Schemas in each DB
-- ============================================================================

-- Copenhagen
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_COPENHAGEN.RAW;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_COPENHAGEN.STAGING;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_COPENHAGEN.CURATED;

-- Aarhus
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AARHUS.RAW;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AARHUS.STAGING;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AARHUS.CURATED;

-- Odense
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ODENSE.RAW;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ODENSE.STAGING;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ODENSE.CURATED;

-- Aalborg
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AALBORG.RAW;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AALBORG.STAGING;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AALBORG.CURATED;

-- Esbjerg
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ESBJERG.RAW;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ESBJERG.STAGING;
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_ESBJERG.CURATED;

-- Aggregated
CREATE SCHEMA IF NOT EXISTS KOMBIT_A_AGGREGATED.UNIFIED;

-- ============================================================================
-- STEP 3: Create Source Tables (example for Copenhagen, repeat for others)
-- ============================================================================

CREATE OR REPLACE TABLE KOMBIT_A_COPENHAGEN.RAW.CITIZENS (
    CITIZEN_ID VARCHAR(36) DEFAULT UUID_STRING(),
    CPR_NUMMER VARCHAR(11),
    FORNAVN VARCHAR(100),
    EFTERNAVN VARCHAR(100),
    FULDE_NAVN VARCHAR(200),
    FOEDSELSDATO DATE,
    KOEN VARCHAR(10),
    ADRESSE VARCHAR(200),
    POSTNUMMER VARCHAR(4),
    BY_NAVN VARCHAR(100),
    KOMMUNE_ID VARCHAR(50) DEFAULT 'COPENHAGEN',
    TELEFON VARCHAR(20),
    EMAIL VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- (Repeat similar table structures for SAGER, YDELSER, EJENDOMME)
-- (Repeat for other municipalities with appropriate KOMMUNE_ID defaults)

-- ============================================================================
-- STEP 4: Dynamic Tables for Aggregation
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE KOMBIT_A_AGGREGATED.UNIFIED.ALL_CITIZENS
    TARGET_LAG = '1 hour'
    WAREHOUSE = COMPUTE_WH
AS
SELECT *, 'COPENHAGEN' AS SOURCE_DB FROM KOMBIT_A_COPENHAGEN.RAW.CITIZENS
UNION ALL
SELECT *, 'AARHUS' AS SOURCE_DB FROM KOMBIT_A_AARHUS.RAW.CITIZENS
UNION ALL
SELECT *, 'ODENSE' AS SOURCE_DB FROM KOMBIT_A_ODENSE.RAW.CITIZENS
UNION ALL
SELECT *, 'AALBORG' AS SOURCE_DB FROM KOMBIT_A_AALBORG.RAW.CITIZENS
UNION ALL
SELECT *, 'ESBJERG' AS SOURCE_DB FROM KOMBIT_A_ESBJERG.RAW.CITIZENS;

-- (Similar Dynamic Tables for SAGER, YDELSER, EJENDOMME)

-- ============================================================================
-- STEP 5: Apply Governance
-- ============================================================================

-- Apply masking policies
ALTER TABLE KOMBIT_A_COPENHAGEN.RAW.CITIZENS 
    MODIFY COLUMN CPR_NUMMER SET MASKING POLICY KOMBIT_GOVERNANCE.POLICIES.CPR_MASK;
ALTER TABLE KOMBIT_A_COPENHAGEN.RAW.CITIZENS 
    MODIFY COLUMN FORNAVN SET MASKING POLICY KOMBIT_GOVERNANCE.POLICIES.NAME_MASK;
ALTER TABLE KOMBIT_A_COPENHAGEN.RAW.CITIZENS 
    MODIFY COLUMN EFTERNAVN SET MASKING POLICY KOMBIT_GOVERNANCE.POLICIES.NAME_MASK;

-- Apply row access policy to aggregated table
ALTER TABLE KOMBIT_A_AGGREGATED.UNIFIED.ALL_CITIZENS 
    ADD ROW ACCESS POLICY KOMBIT_GOVERNANCE.POLICIES.KOMMUNE_DATA_ACCESS ON (KOMMUNE_ID);
