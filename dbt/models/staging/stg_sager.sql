WITH source AS (
    SELECT * FROM {{ source('raw', 'sager') }}
),

transformed AS (
    SELECT
        SAG_ID,
        SAGSNUMMER,
        CITIZEN_ID,
        CPR_NUMMER,
        KOMMUNE_ID,
        
        TRIM(UPPER(SAG_TYPE)) AS SAG_TYPE_KODE,
        
        CASE TRIM(UPPER(SAG_TYPE))
            WHEN 'SOCIAL' THEN 'Social Bistand'
            WHEN 'BESKAEFTIGELSE' THEN 'Beskæftigelsesstøtte'
            WHEN 'BOLIG' THEN 'Boligstøtte'
            WHEN 'SUNDHED' THEN 'Sundhedsydelser'
            WHEN 'BARN_FAMILIE' THEN 'Børn og Familie'
            WHEN 'AELDRE' THEN 'Ældreservice'
            ELSE 'Andre Ydelser'
        END AS SAG_TYPE_BESKRIVELSE,
        
        TRIM(UPPER(SAG_STATUS)) AS STATUS_KODE,
        CASE TRIM(UPPER(SAG_STATUS))
            WHEN 'AABEN' THEN 'Aktiv'
            WHEN 'LUKKET' THEN 'Afsluttet'
            WHEN 'AFVENTER' THEN 'Under Behandling'
            WHEN 'GODKENDT' THEN 'Godkendt'
            WHEN 'AFVIST' THEN 'Afvist'
            ELSE 'Ukendt'
        END AS STATUS_BESKRIVELSE,
        
        CASE WHEN TRIM(UPPER(SAG_STATUS)) IN ('AABEN', 'AFVENTER') THEN TRUE ELSE FALSE END AS ER_AKTIV,
        
        OPRETTET_DATO,
        AFSLUTTET_DATO,
        
        DATEDIFF(DAY, OPRETTET_DATO, COALESCE(AFSLUTTET_DATO, CURRENT_DATE())) AS SAG_VARIGHED_DAGE,
        
        CASE 
            WHEN DATEDIFF(DAY, OPRETTET_DATO, COALESCE(AFSLUTTET_DATO, CURRENT_DATE())) <= 7 THEN 'INDEN_UGE'
            WHEN DATEDIFF(DAY, OPRETTET_DATO, COALESCE(AFSLUTTET_DATO, CURRENT_DATE())) <= 30 THEN 'INDEN_MAANED'
            WHEN DATEDIFF(DAY, OPRETTET_DATO, COALESCE(AFSLUTTET_DATO, CURRENT_DATE())) <= 90 THEN 'INDEN_KVARTAL'
            ELSE 'LANGVARIG'
        END AS VARIGHED_KATEGORI,
        
        SAGSBEHANDLER,
        BESKRIVELSE,
        
        CURRENT_TIMESTAMP() AS TRANSFORMERET_TIDSPUNKT,
        'dbt_staging' AS TRANSFORM_KILDE
        
    FROM source
    WHERE SAG_ID IS NOT NULL
)

SELECT * FROM transformed
