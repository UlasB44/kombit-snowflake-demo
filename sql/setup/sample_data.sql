-- ============================================================================
-- KOMBIT Demo: Synthetic Data Generator
-- Generates realistic Danish test data for all entities
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- Helper: Danish Names and Addresses
-- ============================================================================

CREATE OR REPLACE TABLE KOMBIT_GOVERNANCE.STAGING.DANISH_FIRST_NAMES AS
SELECT column1 AS NAME FROM VALUES 
('Anders'),('Anne'),('Bo'),('Camilla'),('Christian'),('Dorthe'),('Erik'),('Fie'),
('Frederik'),('Gitte'),('Hans'),('Ida'),('Jakob'),('Karen'),('Lars'),('Lene'),
('Mads'),('Maria'),('Niels'),('Nina'),('Ole'),('Pernille'),('Peter'),('Rikke'),
('Søren'),('Tina'),('Thomas'),('Ulla'),('Vibeke'),('Mikkel'),('Louise'),('Henrik');

CREATE OR REPLACE TABLE KOMBIT_GOVERNANCE.STAGING.DANISH_LAST_NAMES AS
SELECT column1 AS NAME FROM VALUES 
('Jensen'),('Nielsen'),('Hansen'),('Pedersen'),('Andersen'),('Christensen'),
('Larsen'),('Sørensen'),('Rasmussen'),('Jørgensen'),('Petersen'),('Madsen'),
('Kristensen'),('Olsen'),('Thomsen'),('Møller'),('Poulsen'),('Knudsen');

CREATE OR REPLACE TABLE KOMBIT_GOVERNANCE.STAGING.DANISH_STREETS AS
SELECT column1 AS STREET FROM VALUES 
('Hovedgaden'),('Vestergade'),('Østergade'),('Nørregade'),('Søndergade'),
('Strandvejen'),('Skovvej'),('Parkvej'),('Kirkegade'),('Torvet'),
('Åboulevarden'),('Havnegade'),('Banegårdspladsen'),('Frederiksgade');

CREATE OR REPLACE TABLE KOMBIT_GOVERNANCE.STAGING.DANISH_CITIES AS
SELECT column1 AS CITY, column2 AS POSTAL FROM VALUES 
('København', '1000'),('Aarhus', '8000'),('Odense', '5000'),
('Aalborg', '9000'),('Esbjerg', '6700'),('Randers', '8900'),
('Horsens', '8700'),('Vejle', '7100'),('Roskilde', '4000');

-- ============================================================================
-- Generate Citizens (100K per municipality = 500K total)
-- ============================================================================

INSERT INTO KOMBIT_B_DISTRIBUTED.RAW.CITIZENS 
    (CITIZEN_ID, CPR_NUMMER, FORNAVN, EFTERNAVN, FULDE_NAVN, FOEDSELSDATO, KOEN, 
     ADRESSE, POSTNUMMER, BY_NAVN, KOMMUNE_ID, TELEFON, EMAIL)
SELECT
    UUID_STRING() AS CITIZEN_ID,
    LPAD(UNIFORM(1,28,RANDOM())::STRING, 2, '0') || 
    LPAD(UNIFORM(1,12,RANDOM())::STRING, 2, '0') ||
    LPAD(MOD(UNIFORM(1950,2005,RANDOM()), 100)::STRING, 2, '0') || '-' ||
    LPAD(UNIFORM(1000,9999,RANDOM())::STRING, 4, '0') AS CPR_NUMMER,
    fn.NAME AS FORNAVN,
    ln.NAME AS EFTERNAVN,
    fn.NAME || ' ' || ln.NAME AS FULDE_NAVN,
    DATEADD('year', -UNIFORM(18, 80, RANDOM()), CURRENT_DATE()) AS FOEDSELSDATO,
    IFF(RANDOM() > 0.5, 'Mand', 'Kvinde') AS KOEN,
    st.STREET || ' ' || UNIFORM(1, 150, RANDOM())::STRING AS ADRESSE,
    ct.POSTAL AS POSTNUMMER,
    ct.CITY AS BY_NAVN,
    kommune.KOMMUNE AS KOMMUNE_ID,
    '+45 ' || UNIFORM(20,99,RANDOM())::STRING || ' ' || 
              UNIFORM(10,99,RANDOM())::STRING || ' ' || 
              UNIFORM(10,99,RANDOM())::STRING || ' ' || 
              UNIFORM(10,99,RANDOM())::STRING AS TELEFON,
    LOWER(fn.NAME) || '.' || LOWER(ln.NAME) || UNIFORM(1,99,RANDOM())::STRING || '@email.dk' AS EMAIL
FROM 
    TABLE(GENERATOR(ROWCOUNT => 500000)) g,
    (SELECT NAME FROM KOMBIT_GOVERNANCE.STAGING.DANISH_FIRST_NAMES ORDER BY RANDOM() LIMIT 1) fn,
    (SELECT NAME FROM KOMBIT_GOVERNANCE.STAGING.DANISH_LAST_NAMES ORDER BY RANDOM() LIMIT 1) ln,
    (SELECT STREET FROM KOMBIT_GOVERNANCE.STAGING.DANISH_STREETS ORDER BY RANDOM() LIMIT 1) st,
    (SELECT CITY, POSTAL FROM KOMBIT_GOVERNANCE.STAGING.DANISH_CITIES ORDER BY RANDOM() LIMIT 1) ct,
    (SELECT column1 AS KOMMUNE FROM VALUES ('COPENHAGEN'),('AARHUS'),('ODENSE'),('AALBORG'),('ESBJERG')
     ORDER BY RANDOM() LIMIT 1) kommune;
