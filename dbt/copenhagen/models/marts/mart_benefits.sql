WITH benefits AS (
    SELECT * FROM {{ ref('stg_ydelser') }}
),
citizens AS (
    SELECT CITIZEN_ID, FULDE_NAVN FROM {{ ref('stg_citizens') }}
)
SELECT
    y.YDELSE_ID,
    y.YDELSESNUMMER,
    y.KOMMUNE_ID,
    y.CITIZEN_ID,
    c.FULDE_NAVN AS BORGER_NAVN,
    y.YDELSE_TYPE,
    y.BELOEB,
    y.AARLIGT_BELOEB,
    y.BELOEB_NIVEAU,
    y.PERIODE_START,
    y.PERIODE_SLUT,
    y.ER_AKTIV,
    CURRENT_TIMESTAMP() AS OPDATERET
FROM benefits y
LEFT JOIN citizens c ON y.CITIZEN_ID = c.CITIZEN_ID
