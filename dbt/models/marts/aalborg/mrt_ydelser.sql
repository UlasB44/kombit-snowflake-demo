SELECT * FROM {{ ref('stg_ydelser') }} WHERE KOMMUNE_ID = 'AALBORG'
