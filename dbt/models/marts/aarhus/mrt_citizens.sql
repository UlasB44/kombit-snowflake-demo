SELECT * FROM {{ ref('stg_citizens') }} WHERE KOMMUNE_ID = 'AARHUS'
