SELECT * FROM {{ ref('stg_sager') }} WHERE KOMMUNE_ID = 'COPENHAGEN'
