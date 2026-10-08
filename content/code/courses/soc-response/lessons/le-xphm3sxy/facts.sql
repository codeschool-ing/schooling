-- facts.sql: every number the report states, each from one query, numbered so the report can cite it
.headers on
.mode column
SELECT 1 AS n, 'password guesses from 203.0.113.66' AS fact, count(*) AS value
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 2, 'accounts those guesses named', count(DISTINCT user)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 3, 'successful logins from 203.0.113.66', count(*)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'
UNION ALL
SELECT 4, 'hosts reached by bruno that night', count(DISTINCT host)
  FROM logs WHERE user = 'bruno' AND action = 'success'
   AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
UNION ALL
SELECT 5, 'bytes from files to 203.0.113.200', sum(bytes)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200'
UNION ALL
SELECT 6, 'the same, in MB (10^6 bytes)', round(sum(bytes) / 1e6)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200';
