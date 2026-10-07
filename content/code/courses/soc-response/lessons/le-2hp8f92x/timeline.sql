-- timeline.sql: Thursday night in one list, every source, UTC and local side by side
.headers on
.mode column
SELECT timestamp AS utc, time(timestamp, '-3 hours') AS local, host, product, action,
       coalesce(user, '') AS user, coalesce(src_ip, '') AS src, coalesce(dst_ip, '') AS dst,
       coalesce(bytes, '') AS bytes
FROM logs
WHERE timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
  AND (src_ip IN ('203.0.113.66', '198.51.100.22', '192.168.20.10') OR user = 'bruno')
  AND NOT (product = 'sshd' AND action = 'failure')
  AND NOT (product = 'firewall' AND src_ip = '203.0.113.66' AND dst_port = 22)
UNION ALL
SELECT min(timestamp), time(min(timestamp), '-3 hours'), 'gw', 'sshd', count(*) || ' failures',
       count(DISTINCT user) || ' accounts', '203.0.113.66', '', ''
FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
ORDER BY utc;
