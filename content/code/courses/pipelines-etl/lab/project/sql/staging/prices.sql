-- The publishers' prices, parsed out of JSON and made to agree with each other:
-- ISBNs without hyphens, names without stray spaces, one spelling of the
-- currency, a number where a number was sent as text. A price that is missing
-- is not a price, and is left out.
DROP TABLE IF EXISTS staging.prices CASCADE;
CREATE TABLE staging.prices AS
SELECT replace(trim(doc->>'isbn'), '-', '')     AS isbn,
       trim(doc->>'publisher')                  AS publisher,
       (doc->>'list_price_cents')::integer      AS list_price_cents,
       upper(doc->>'currency')                  AS currency,
       (doc->>'updated_at')::timestamptz        AS updated_at
  FROM raw.prices
 WHERE doc->>'list_price_cents' IS NOT NULL;
