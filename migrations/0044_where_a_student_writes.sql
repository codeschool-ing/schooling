-- Where a student writes to use the seven days, kept where it can be changed.
--
-- # THE VALUE EXISTS ALREADY AND IT IS IN THE WRONG KIND OF PLACE
--
-- `SCHOOLING_SUPPORT_EMAIL` arrived with the withdrawal notice: the terms of
-- use promise a week to give the subscription back, for the whole amount and
-- with no reason (art. 49 of the Código de Defesa do Consumidor), and the
-- account screen names the deadline whatever happens and names an ADDRESS only
-- when the deployment configured one.
--
-- So the address is a promise the platform publishes to consumers, and changing
-- it means an apply against the infrastructure and a new revision of the
-- service. That is the wrong shape for this particular fact twice over:
--
--   * it is a fact about WHO ANSWERS, not about the deployment. The host, the
--     database and the sending domain are properties of where the platform
--     runs. An inbox is a property of a person reading it, and it changes when
--     that person does — a handover, a shared box, a support desk — with no
--     code and no infrastructure changing at all.
--
--   * the file that holds it lives on ONE machine. `infra/terraform.tfvars` is
--     gitignored, on purpose, because an address in a public repository is an
--     address that gets scraped. The cost is that an apply run from anywhere
--     else plans the value back to empty and takes the address off the screen
--     without anything failing — the notice then publishes the right and no way
--     to use it, silently, which is the exact defect the notice was built to
--     close.
--
-- # AND IT PASSES THE TEST K-13 SETS, WHICH IS NOT AUTOMATIC
--
-- `internal/console/writes.go` opens by refusing the shape that suggests itself
-- — a `system_parameters` table with a name, a value, and a screen that edits
-- any row of it — because a configuration surface grows to fill the space it is
-- given. The bar it sets instead is that a settable value must have NO RIGHT
-- ANSWER, since a value with one belongs in code where a test can hold it.
--
-- This clears that bar: no test can say that any particular address is the
-- correct one to publish. It is the same kind of fact as a school's accent
-- colour, which is settable for the same reason.
--
-- So this is a table named for what it holds, with a column per fact — not a
-- registry that the next value can be added to by INSERT.
--
-- # ONE ROW, ENFORCED BY THE DATABASE
--
-- There is one platform (N-02: one subscription opens every school), so there
-- is one address. `only_row` is a primary key that can only be true, which
-- makes a second row an error the database raises rather than a rule the Go
-- has to remember — and makes the write an ordinary upsert with nothing to
-- decide.
--
-- # REPLACED, NOT APPENDED, AND THAT IS THE DIFFERENCE FROM A PRICE
--
-- `plan_prices` is a series because K-14 says money is effective-dated: a March
-- invoice has to stay explicable in November, and the row that priced it has to
-- still be there. An address owes nothing like that. What somebody might ask
-- later is "which address was on the screen in March", and the AUDIT LOG
-- answers it — every console write records who, when, what was there and what
-- replaced it (K-01), so the history exists without a second table that would
-- have to be read to find the one row that matters.
--
-- The accent colour is overwritten for exactly this reason and said so first.
--
-- # WHAT IT DOES NOT HOLD
--
-- A NAME, A TELEPHONE, AN OPENING HOUR. Each would be a column somebody has to
-- decide the screen shows, and N-05 is still true — there is no staff to answer
-- a message, and the platform should not publish a switchboard it does not
-- have. One address is what the terms promise and it is what this holds.
--
-- IT IS ALSO NOT THE MAIL CONFIGURATION. `SCHOOLING_MAIL_FROM` and
-- `SCHOOLING_MAIL_REPLY_TO` stay in the infrastructure and have to: they are
-- tied to a domain that publishes SPF and DKIM, they are read once when the
-- process starts, and a wrong one stops mail being delivered rather than being
-- read. This address is only ever DRAWN ON A SCREEN, which is what makes it
-- safe to move and useless to keep beside them.
--
-- # THE ENVIRONMENT VARIABLE STAYS
--
-- Empty here falls back to it, and empty in both is still allowed — the notice
-- then says the deadline and no address, which is the behaviour that shipped
-- and is better than nothing, because knowing the date is worth something on
-- its own. Keeping the variable is also what lets a laptop and CI draw the
-- notice without writing a row, and what gives the first deployment an answer
-- before anybody has opened the console.

-- +goose Up

CREATE TABLE support_contact (
    -- ONE ROW, AND THE KEY IS WHAT ENFORCES IT. A boolean primary key with a
    -- CHECK that it is true admits exactly one value, so a second INSERT is a
    -- duplicate key. Nothing in Go has to know this.
    only_row boolean PRIMARY KEY DEFAULT true CHECK (only_row),

    -- WHERE A STUDENT WRITES. Not validated here beyond being non-empty: what
    -- makes an address usable is not a shape a CHECK can describe, the handler
    -- refuses the obvious rubbish, and a constraint that rejected a valid
    -- address would take the notice off the screen to defend a regex.
    --
    -- Empty is not stored — a row that says nothing is the absent row with
    -- extra steps, and the read falls back either way.
    email text NOT NULL CHECK (length(trim(email)) > 0),

    -- WHEN IT LAST MOVED, so the console can say how long this has been the
    -- answer. The audit log holds who and why; this is here so the screen can
    -- show the age of the value without joining to it.
    set_at timestamptz NOT NULL DEFAULT now()
);

-- NONE, AND THE COLUMN IS AN E-MAIL ADDRESS, which is worth a sentence rather
-- than a word. What makes an address personal data is whose it is and why it is
-- held; this one is a channel the platform PUBLISHES to every subscriber, held
-- so it can be printed on a screen. `internal/privacy` carries the same
-- classification and the edge case with it — an operator who types their own
-- personal address is publishing it, not being recorded.
COMMENT ON TABLE support_contact IS 'personal-data: none';

-- +goose Down

DROP TABLE support_contact;
