# KOMBIT Snowflake Demo

Multi-tenant data platform demo for Danish municipalities showcasing Snowflake capabilities for PII handling, data governance, and CDC patterns.

## Overview

This demo implements **three architectural patterns** for multi-tenant municipality data:

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **A** | Bottom-up Aggregation | 5 separate DBs → 1 aggregated central DB |
| **B** | Top-down Distribution | 1 central DB → 5 municipality schemas via Dynamic Tables |
| **C** | dbt-driven | RAW → STAGING → Municipality schemas via dbt |

## Features Demonstrated

- **PII Classification**: Custom classifier for Danish identifiers (CPR, CVR, Sagsnummer, Matrikelnummer)
- **Dynamic Masking**: Role-based data visibility with masking policies
- **Row Access Policies**: Municipality-level data isolation
- **CDC with Dynamic Tables**: Real-time data aggregation and distribution
- **Cost Attribution**: Per-municipality warehouses for tracking
- **RBAC**: Hierarchical roles with municipality-specific access

## Quick Start

### Prerequisites
- Snowflake account (Business Critical recommended for governance features)
- SYSADMIN and SECURITYADMIN roles
- dbt-snowflake (optional, for Pattern C)

### Deployment

```bash
# 1. Setup governance objects (roles, policies, classifiers)
snowsql -f sql/governance/01_roles.sql
snowsql -f sql/governance/02_classifiers.sql
snowsql -f sql/governance/03_masking_policies.sql
snowsql -f sql/governance/04_row_access_policies.sql

# 2. Deploy your chosen pattern
snowsql -f sql/patterns/pattern_a_aggregation.sql   # OR
snowsql -f sql/patterns/pattern_b_distribution.sql  # OR
cd dbt && dbt run                                    # Pattern C

# 3. Setup cost tracking
snowsql -f sql/setup/warehouses.sql
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      KOMBIT_GOVERNANCE                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Classifiers │  │  Policies   │  │         Roles           │  │
│  │ Danish PII  │  │ CPR_MASK    │  │ KOMBIT_ADMIN            │  │
│  │             │  │ NAME_MASK   │  │ KOMBIT_ANALYST          │  │
│  │             │  │ ADDRESS_MASK│  │ KOMBIT_COPENHAGEN_ROLE  │  │
│  │             │  │ ROW_ACCESS  │  │ KOMBIT_AARHUS_ROLE ...  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

Pattern A: Bottom-Up                Pattern B: Top-Down
┌──────────────────┐               ┌──────────────────────────────┐
│ KOMBIT_A_CPH     │               │     KOMBIT_B_DISTRIBUTED     │
│ KOMBIT_A_AARHUS  │  ──UNION──►   │ ┌────┐ ┌───────┐ ┌─────────┐ │
│ KOMBIT_A_ODENSE  │  Dynamic      │ │RAW │→│STAGING│→│ DT per  │ │
│ KOMBIT_A_AALBORG │  Tables       │ └────┘ └───────┘ │ kommune │ │
│ KOMBIT_A_ESBJERG │               │                  └─────────┘ │
└────────┬─────────┘               └──────────────────────────────┘
         ▼
┌──────────────────┐               Pattern C: dbt
│ KOMBIT_A_AGGREG  │               ┌──────────────────────────────┐
│ (Central View)   │               │       KOMBIT_C_DBT           │
└──────────────────┘               │ RAW → stg_* → mrt_* tables   │
                                   │ (per municipality schema)    │
                                   └──────────────────────────────┘
```

## Data Model

| Entity | Danish Name | Description | Volume |
|--------|-------------|-------------|--------|
| Citizens | Borgere | Citizen registry with CPR | 500K |
| Cases | Sager | Municipal cases/applications | 100K |
| Benefits | Ydelser | Social benefits payments | 75K |
| Properties | Ejendomme | Real estate registry | 25K |

## Roles & Permissions

| Role | Access Level | Data Masking |
|------|--------------|--------------|
| KOMBIT_ADMIN | Full access all municipalities | Unmasked |
| KOMBIT_ANALYST | Read all municipalities | Masked PII |
| KOMBIT_DATA_STEWARD | Governance management | Unmasked |
| KOMBIT_AUDITOR | Read-only audit | Masked |
| KOMBIT_*_ROLE | Single municipality only | Unmasked (own data) |

## Cost Tracking

Each municipality has a dedicated warehouse:
- `KOMBIT_COPENHAGEN_WH`
- `KOMBIT_AARHUS_WH`
- `KOMBIT_ODENSE_WH`
- `KOMBIT_AALBORG_WH`
- `KOMBIT_ESBJERG_WH`

Query costs by municipality:
```sql
SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME LIKE 'KOMBIT_%_WH'
GROUP BY WAREHOUSE_NAME;
```

## Configuration

Update `config/settings.yml` with your Snowflake account details before deployment.

## License

MIT License - See LICENSE file
