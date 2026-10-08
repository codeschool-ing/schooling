-- milestones.sql: Thursday's incident in intervals, from the logs and the incident record
.headers on
.mode column
CREATE TEMP TABLE milestone (name TEXT, at TEXT);  -- every time in UTC
INSERT INTO milestone
  SELECT 'first guess', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
  UNION ALL
  SELECT 'first login', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success';
INSERT INTO milestone VALUES                   -- from the incident record, INC-2026-014
  ('alert fired',  '2026-09-17 05:35:00'),
  ('alert taken',  '2026-09-17 11:12:00'),
  ('declared',     '2026-09-17 12:12:00'),
  ('contained',    '2026-09-17 12:45:00'),
  ('recovered',    '2026-10-02 13:00:00');
SELECT "from", "to", "from (UTC)",
       printf('%d d %02d h %02d min', s / 86400, s % 86400 / 3600, s % 3600 / 60) AS took
FROM (SELECT a.name AS "from", b.name AS "to", a.at AS "from (UTC)",
             strftime('%s', b.at) - strftime('%s', a.at) AS s   -- seconds between the two
      FROM milestone a, milestone b
      WHERE (a.name, b.name) IN (VALUES
        ('first guess', 'first login'), ('first login', 'alert fired'), ('alert fired', 'alert taken'),
        ('alert taken', 'declared'), ('declared', 'contained'), ('first login', 'contained'),
        ('contained', 'recovered')))
ORDER BY "from (UTC)", s;
