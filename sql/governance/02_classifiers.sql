-- ============================================================================
-- KOMBIT Demo: Danish PII Classifier
-- Custom classifier for Danish personal identifiers
-- ============================================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS KOMBIT_GOVERNANCE COMMENT = 'Central governance objects';
CREATE SCHEMA IF NOT EXISTS KOMBIT_GOVERNANCE.CLASSIFIERS;

-- Custom Semantic Category for Danish PII
CREATE OR REPLACE SNOWFLAKE.DATA_PRIVACY.CUSTOM_CLASSIFIER 
    KOMBIT_GOVERNANCE.CLASSIFIERS.DANISH_PII_CLASSIFIER(
        'CPR_NUMMER',           -- Danish personal ID (DDMMYY-XXXX)
        'CVR_NUMMER',           -- Business registration number
        'SAGSNUMMER',           -- Case number
        'MATRIKELNUMMER'        -- Property registration number
    );

-- Classification Profile (Business Critical+ required)
-- Uncomment if on Business Critical edition:
/*
CREATE OR REPLACE SNOWFLAKE.DATA_PRIVACY.CLASSIFICATION_PROFILE 
    KOMBIT_GOVERNANCE.CLASSIFIERS.KOMBIT_CLASSIFICATION_PROFILE({
        'minimum_object_age_for_classification_days': 1,
        'maximum_classification_validity_days': 30,
        'auto_tag': true
    });
*/
