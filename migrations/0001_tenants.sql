-- The schools, and the addresses they answer at.
--
-- TWO TABLES AND NOT ONE, because a school will have more than one address
-- before it has anything else interesting. `code.example.tld` is the platform
-- address it is born with, and a custom domain is another row rather than a
-- second column that is usually null. Making that a list from the first day
-- costs nothing and saves a migration on the day it matters.
--
-- The slug is the label the platform address is built from, and it is checked
-- here rather than only in the application, because a slug that is not a legal
-- host name produces an address that cannot exist — and the database is the
-- one place that cannot be bypassed.

-- +goose Up

CREATE TABLE tenants (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug       text NOT NULL UNIQUE,
    name       text NOT NULL,
    -- One colour per school, applied as a custom property. It is the whole of
    -- the visual difference between them: one design system, one accent, so a
    -- student knows where they are without the brand fragmenting.
    accent     text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),

    -- A host name label: lowercase letters, digits and hyphens, never starting
    -- or ending with a hyphen, at most 63 characters.
    CONSTRAINT tenants_slug_is_a_host_label
        CHECK (slug ~ '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$')
);

CREATE TABLE tenant_domains (
    -- The host is the key, because the question this table exists to answer is
    -- always "which school is at this address" and never the other way round.
    -- Stored already normalised: lowercase, no port, no trailing dot.
    host       text PRIMARY KEY,
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tenant_domains_host_is_lowercase CHECK (host = lower(host)),
    CONSTRAINT tenant_domains_host_has_no_port  CHECK (host NOT LIKE '%:%')
);

-- The reverse direction: every address a school answers at. Rare, but it is
-- what the console lists on a school's page.
CREATE INDEX tenant_domains_by_tenant ON tenant_domains (tenant_id);

-- +goose Down

DROP TABLE tenant_domains;
DROP TABLE tenants;
