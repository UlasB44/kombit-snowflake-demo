# KOMBIT Snowflake Demo

Multi-tenant data platform for Danish municipalities showcasing Snowflake governance, Dynamic Tables, and dbt.

## Architecture Patterns

### Pattern A: Bottom-Up Aggregation
- 5 separate municipality databases → 1 aggregated database
- Dynamic Tables aggregate data in real-time
- RLS and masking applied to aggregated views

### Pattern C: dbt-driven Transformations  
- Central database with RAW → STAGING → MARTS flow
- Real transformations: data cleansing, computed columns, enrichment
- Municipality-specific mart tables with analytics

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

### 2. Deploy and Run dbt Project

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

# Deploy dbt project
cd dbt
snow dbt deploy kombit_dbt_demo -c KOMBIT_DBT --force

# Execute dbt on Snowflake
# Run this SQL in Snowflake:
EXECUTE DBT PROJECT KOMBIT_C_DBT.RAW.KOMBIT_DBT_DEMO ARGS = 'run'
```

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
