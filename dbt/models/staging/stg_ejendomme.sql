WITH source AS (
    SELECT * FROM {{ source('raw', 'ejendomme') }}
),

transformed AS (
    SELECT
        EJENDOM_ID,
        MATRIKELNUMMER,
        EJER_CPR,
        KOMMUNE_ID,
        
        TRIM(INITCAP(ADRESSE)) AS ADRESSE_STANDARDIZED,
        TRIM(UPPER(POSTNUMMER)) AS POSTNUMMER,
        TRIM(INITCAP(BY_NAVN)) AS BY_NAVN_STANDARDIZED,
        
        TRIM(INITCAP(ADRESSE)) || ', ' || TRIM(UPPER(POSTNUMMER)) || ' ' || TRIM(INITCAP(BY_NAVN)) AS FULD_ADRESSE,
        
        TRIM(UPPER(EJENDOMSTYPE)) AS EJENDOMSTYPE_KODE,
        
        CASE TRIM(UPPER(EJENDOMSTYPE))
            WHEN 'VILLA' THEN 'Parcelhus/Villa'
            WHEN 'LEJLIGHED' THEN 'Ejerlejlighed'
            WHEN 'RAEKKEHUS' THEN 'Rækkehus'
            WHEN 'SOMMERHUS' THEN 'Sommerhus'
            WHEN 'LANDBRUG' THEN 'Landbrugsejendom'
            WHEN 'ERHVERV' THEN 'Erhvervsejendom'
            ELSE 'Anden Ejendom'
        END AS EJENDOMSTYPE_BESKRIVELSE,
        
        VURDERING,
        CASE WHEN VURDERING < 0 THEN 0 ELSE VURDERING END AS VURDERING_VALIDERET,
        
        CASE 
            WHEN VURDERING >= 5000000 THEN 'LUKSUS'
            WHEN VURDERING >= 2500000 THEN 'HOEJ_VAERDI'
            WHEN VURDERING >= 1500000 THEN 'MELLEM_VAERDI'
            WHEN VURDERING >= 750000 THEN 'STANDARD'
            ELSE 'BUDGET'
        END AS VAERDI_NIVEAU,
        
        AREAL_M2,
        
        CASE 
            WHEN AREAL_M2 >= 200 THEN 'STOR'
            WHEN AREAL_M2 >= 100 THEN 'MELLEM'
            WHEN AREAL_M2 >= 50 THEN 'LILLE'
            ELSE 'KOMPAKT'
        END AS STOERRELSE_KATEGORI,
        
        CASE 
            WHEN AREAL_M2 > 0 THEN ROUND(VURDERING / AREAL_M2, 2)
            ELSE 0
        END AS PRIS_PR_M2,
        
        CURRENT_TIMESTAMP() AS TRANSFORMERET_TIDSPUNKT,
        'dbt_staging' AS TRANSFORM_KILDE
        
    FROM source
    WHERE EJENDOM_ID IS NOT NULL
)

SELECT * FROM transformed
