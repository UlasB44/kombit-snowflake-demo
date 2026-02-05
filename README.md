# KOMBIT Snowflake Demo

Multi-tenant data platform for Danish municipalities showcasing Snowflake governance, Dynamic Tables, and dbt.

## Architecture Patterns

### Pattern A: Bottom-Up Aggregation
- 5 separate municipality databases → 1 aggregated database
- Dynamic Tables aggregate data in real-time
- Manual masking policies applied to columns
- RLS for municipality-based data isolation

### Pattern C: dbt-driven Transformations  
- Central database with RAW → STAGING → MARTS flow
- 5 separate dbt projects (one per municipality)
- Real transformations: data cleansing, computed columns, enrichment
- Municipality-specific mart tables with analytics

### Pattern D: Auto-Classification (Experimental)
- Same structure as Pattern A
- Uses Snowflake's native Sensitive Data Classification feature
- Classification profile with auto_tag enabled
- Tag-based masking policies

#### Auto-Classification Limitations

**Snowflake's auto-classification is heavily biased toward English column names and US/international data formats.**

| Column | Danish Name | Detected? | Reason |
|--------|-------------|-----------|--------|
| CPR_NUMMER | CPR_NUMMER | ✅ YES | DK_PERSONAL_IDENTIFICATION_NUMBER is explicitly built-in |
| EMAIL | EMAIL | ✅ YES | Email format is universal |
| FORNAVN | FORNAVN | ❌ NO | Danish column name (needs FIRST_NAME) |
| EFTERNAVN | EFTERNAVN | ❌ NO | Danish column name (needs LAST_NAME) |
| TELEFON | TELEFON | ❌ NO | Danish column name + Danish format (+45 XXXXXXXX) |
| ADRESSE | ADRESSE | ❌ NO | Danish column name + Danish address format |
| POSTNUMMER | POSTNUMMER | ❌ NO | Danish column name + Danish postal code format |
| FOEDSELSDATO | FOEDSELSDATO | ❌ NO | Danish column name (needs DATE_OF_BIRTH) |
| KOEN | KOEN | ❌ NO | Danish column name (needs GENDER) |

**For non-English data, you must either:**
1. Use English column names (FIRST_NAME, PHONE_NUMBER, etc.)
2. Create custom classifiers for your specific formats
3. Use manual masking policies (like Pattern A)

## Quick Start

### 1. Run SQL Scripts (in order)

```sql
-- Step 1: Create governance (roles, policies)
-- Run: sql/01_governance.sql

-- Step 2: Create Pattern A structure
-- Run: sql/02_pattern_a.sql

-- Step 3: Create Pattern C structure
-- Run: sql/03_pattern_c_setup.sql

-- Step 4: Generate sample data
-- Run: sql/04_sample_data.sql
```

### 2. Deploy and Run dbt Projects

5 separate dbt projects for each municipality:

```bash
# Add connection to ~/.snowflake/connections.toml
[KOMBIT_DBT]
account = "your-account"
user = "your-user"
authenticator = "snowflake"
password = "your-password"
database = "KOMBIT_C_DBT"
schema = "RAW"
warehouse = "COMPUTE_WH"
role = "SYSADMIN"

# Deploy each municipality project
cd dbt/copenhagen && snow dbt deploy kombit_copenhagen -c KOMBIT_DBT --force
cd ../aarhus && snow dbt deploy kombit_aarhus -c KOMBIT_DBT --force
cd ../odense && snow dbt deploy kombit_odense -c KOMBIT_DBT --force
cd ../aalborg && snow dbt deploy kombit_aalborg -c KOMBIT_DBT --force
cd ../esbjerg && snow dbt deploy kombit_esbjerg -c KOMBIT_DBT --force

# Execute each dbt project on Snowflake:
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_COPENHAGEN ARGS = 'run';
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_AARHUS ARGS = 'run';
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_ODENSE ARGS = 'run';
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_AALBORG ARGS = 'run';
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_ESBJERG ARGS = 'run';
```

## dbt Project Structure

Each municipality has its own dbt project:

```
dbt/
├── copenhagen/    # KOMBIT_COPENHAGEN project → COPENHAGEN schema
├── aarhus/        # KOMBIT_AARHUS project → AARHUS schema
├── odense/        # KOMBIT_ODENSE project → ODENSE schema
├── aalborg/       # KOMBIT_AALBORG project → AALBORG schema
└── esbjerg/       # KOMBIT_ESBJERG project → ESBJERG schema
```

Each project contains:
- `models/staging/` - 4 staging views (stg_citizens, stg_sager, stg_ydelser, stg_ejendomme)
- `models/marts/` - 4 mart tables (mart_citizens, mart_cases, mart_benefits, mart_analytics)

## Roles & Access

| Role | CPR View | Data Access |
|------|----------|-------------|
| KOMBIT_ADMIN | Full | All municipalities |
| KOMBIT_DATA_STEWARD | Full | All municipalities |
| KOMBIT_ANALYST | XXXXXX-**** | All municipalities |
| KOMBIT_AUDITOR | ******-**** | All municipalities |
| KOMBIT_COPENHAGEN_ROLE | Full | Copenhagen only |
| KOMBIT_AARHUS_ROLE | Full | Aarhus only |
| KOMBIT_ODENSE_ROLE | Full | Odense only |
| KOMBIT_AALBORG_ROLE | Full | Aalborg only |
| KOMBIT_ESBJERG_ROLE | Full | Esbjerg only |

## Key Features

- **Dynamic Data Masking**: CPR, names, addresses, phone, email
- **Row-Level Security**: Municipality-based data isolation  
- **Dynamic Tables**: Real-time aggregation across municipalities
- **dbt Transformations**: Age calculation, data standardization, SLA tracking

## Testing RLS

```sql
-- Test as municipality role
USE ROLE KOMBIT_COPENHAGEN_ROLE;
SELECT COUNT(*) FROM KOMBIT_A_AGGREGATED.DYNAMIC_TABLES.DT_ALL_CITIZENS;
-- Returns ~100K (Copenhagen only)

-- Test as analyst role
USE ROLE KOMBIT_ANALYST;
SELECT COUNT(*) FROM KOMBIT_A_AGGREGATED.DYNAMIC_TABLES.DT_ALL_CITIZENS;
-- Returns ~500K (all municipalities, masked PII)
```

## Important Notes

- All policies use `CURRENT_ROLE()` (not `IS_ROLE_IN_SESSION()`)
- KOMMUNE_ID values are UPPERCASE: COPENHAGEN, AARHUS, ODENSE, AALBORG, ESBJERG
- Snowsight Data Preview runs as table owner - use worksheets to test RLS
