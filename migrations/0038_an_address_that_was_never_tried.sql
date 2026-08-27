-- An address that was never tried.
--
-- # A FOURTH REASON, AND IT IS NOT LIKE THE OTHER THREE
--
-- `invalid` is the provider refusing to send at all: the address is mistyped,
-- or the domain is not a domain. Nothing left this platform, nothing reached a
-- receiving server, and nothing was held against us.
--
-- That difference is why it was missing rather than excluded. `0037` was
-- written around one harm — that repeated attempts at a dead mailbox cost this
-- domain its standing with the providers who decide whether ANYBODY else's mail
-- arrives — and by that measure `invalid` does not qualify, so it never came
-- up. It was an omission and reads here as one.
--
-- What it buys is the rest of the value the list has:
--
--   * attempts not spent on an address that will never work, and
--   * a support conversation that can answer "that address does not exist"
--     instead of "I cannot tell you why nothing arrived".
--
-- # THE CHECK IS WHY THIS IS A MIGRATION AND NOT A CONSTANT
--
-- `reason` lists its values by name, so a fourth one cannot be written by a
-- deployment that merely believes in it — the database refuses until somebody
-- decides here, in a file with the argument in it. That is the property being
-- exercised rather than worked around, and it is the reason the column was
-- written that way.
--
-- # A SOFT BOUNCE IS STILL NOT HERE
--
-- Nothing about this widens the door. A mailbox that is full or a server having
-- an afternoon is a message to try again, not an address to give up on — the
-- Proton outage of 27 August 2026 would have suppressed every address at a
-- whole provider, and that is still the mistake this column excludes.

-- +goose Up

ALTER TABLE mail_suppressions
    DROP CONSTRAINT mail_suppressions_reason_check;

ALTER TABLE mail_suppressions
    ADD CONSTRAINT mail_suppressions_reason_check
    CHECK (reason IN ('hard_bounce', 'blocked', 'complaint', 'invalid'));

-- +goose Down

-- THE ROWS GO FIRST OR THE CONSTRAINT CANNOT BE ADDED. Going back means the
-- database no longer has a word for these, and a row it has no word for is
-- worse than none: it would be an address barred for a reason nothing can read.
DELETE FROM mail_suppressions WHERE reason = 'invalid';

ALTER TABLE mail_suppressions
    DROP CONSTRAINT mail_suppressions_reason_check;

ALTER TABLE mail_suppressions
    ADD CONSTRAINT mail_suppressions_reason_check
    CHECK (reason IN ('hard_bounce', 'blocked', 'complaint'));
