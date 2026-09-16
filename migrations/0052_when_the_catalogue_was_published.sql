-- WHEN THIS SCHOOL'S CATALOGUE WAS LAST PUBLISHED, which nothing recorded.
--
-- The mirror is rewritten whole by `cmd/load`, in one transaction, so no row in
-- it has a meaningful age of its own: every course is as old as the last load,
-- whether its words changed or not. There was therefore no date to put in the
-- `lastmod` of a sitemap, and both alternatives are worse than none —
-- `time.Now()` tells a crawler that everything changed on every crawl, which
-- teaches it to ignore the field, and a per-page date would be this same date
-- wearing a disguise.
--
-- So the one true thing is recorded, once per school, by the thing that makes
-- it true.

-- +goose Up

-- NULLABLE, AND THAT IS THE POINT OF IT. A school that has not been loaded
-- since this column existed does not know when its catalogue was published, and
-- the sitemap leaves `lastmod` out rather than inventing one. The next load
-- fills it in.
ALTER TABLE tenants ADD COLUMN catalog_published_at timestamptz;

-- +goose Down

ALTER TABLE tenants DROP COLUMN catalog_published_at;
