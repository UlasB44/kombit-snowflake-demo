SELECT * FROM {{ ref('stg_ejendomme') }} WHERE KOMMUNE_ID = 'COPENHAGEN'
