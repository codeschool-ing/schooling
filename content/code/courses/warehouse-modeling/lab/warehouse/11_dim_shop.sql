CREATE TABLE dim_shop AS
SELECT row_number() OVER (ORDER BY opened_on) AS shop_key,
       shop_id,
       name                                   AS shop_name,
       coalesce(city, 'Online')               AS city,
       coalesce(state, '--')                  AS state,
       CASE WHEN state IN ('SP', 'MG') THEN 'Southeast'
            WHEN state IN ('PR', 'RS') THEN 'South'
            ELSE 'Online' END                 AS region,
       channel,
       opened_on
FROM staging.shops;
