WITH source AS (
    SELECT * FROM {{ source('raw', 'ydelser') }}
),

transformed AS (
    SELECT
        YDELSE_ID,
        YDELSESNUMMER,
        CITIZEN_ID,
        CPR_NUMMER,
        KOMMUNE_ID,
        
        TRIM(UPPER(YDELSE_TYPE)) AS YDELSE_TYPE_KODE,
        
        CASE TRIM(UPPER(YDELSE_TYPE))
            WHEN 'DAGPENGE' THEN 'Arbejdsløshedsdagpenge'
            WHEN 'PENSION' THEN 'Pensionsydelser'
            WHEN 'BOERNETILSKUD' THEN 'Børne- og Familietilskud'
            WHEN 'BOLIGSTOETTE' THEN 'Boligstøtte'
            WHEN 'HANDICAP' THEN 'Handicapydelser'
            WHEN 'SUNDHED' THEN 'Sundhedstilskud'
            WHEN 'SU' THEN 'Uddannelsesstøtte (SU)'
            WHEN 'KONTANTHJAELP' THEN 'Kontanthjælp'
            ELSE 'Andre Ydelser'
        END AS YDELSE_BESKRIVELSE,
        
        BELOEB,
        CASE WHEN BELOEB < 0 THEN 0 ELSE BELOEB END AS BELOEB_VALIDERET,
        
        CASE 
            WHEN BELOEB >= 20000 THEN 'HOEJ_VAERDI'
            WHEN BELOEB >= 10000 THEN 'MELLEM_VAERDI'
            WHEN BELOEB >= 5000 THEN 'LAV_VAERDI'
            ELSE 'MINIMAL_VAERDI'
        END AS BELOEB_NIVEAU,
        
        BELOEB * 12 AS AARLIGT_BELOEB_EST,
        
        UDBETALING_DATO,
        PERIODE_START,
        PERIODE_SLUT,
        
        TRIM(UPPER(STATUS)) AS STATUS_KODE,
        CASE 
            WHEN PERIODE_SLUT IS NULL THEN TRUE
            WHEN PERIODE_SLUT >= CURRENT_DATE() THEN TRUE
            ELSE FALSE
        END AS ER_AKTIV,
        
        DATEDIFF(DAY, PERIODE_START, COALESCE(PERIODE_SLUT, CURRENT_DATE())) AS YDELSE_VARIGHED_DAGE,
        
        CURRENT_TIMESTAMP() AS TRANSFORMERET_TIDSPUNKT,
        'dbt_staging' AS TRANSFORM_KILDE
        
    FROM source
    WHERE YDELSE_ID IS NOT NULL
)

SELECT * FROM transformed
