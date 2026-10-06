-- The assistant reads through a role of its own, and the database decides which rows that role sees.
-- Run by the loader, which owns the table and is not limited by the policy.
DO $$ BEGIN CREATE ROLE assistant LOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT SELECT ON chunks TO assistant;
ALTER TABLE chunks ENABLE ROW LEVEL SECURITY;
CREATE POLICY by_audience ON chunks FOR SELECT TO assistant
    USING (audience = ANY (string_to_array(current_setting('rag.audiences', true), ',')));
