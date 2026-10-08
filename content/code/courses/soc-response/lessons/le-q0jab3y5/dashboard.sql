-- dashboard.sql: three panels, each one a question somebody asks every morning
.headers on
.mode column
-- 1. failed SSH logins per day, local time
SELECT date(timestamp, '-3 hours') AS day, count(*) AS failures
FROM logs WHERE product = 'sshd' AND action = 'failure' GROUP BY day;
-- 2. the five addresses that tried the most different accounts
SELECT src_ip, count(DISTINCT user) AS accounts, count(*) AS failures
FROM logs WHERE action = 'failure' GROUP BY src_ip ORDER BY accounts DESC LIMIT 5;
-- 3. megabytes leaving the company, per destination
SELECT dst_ip, count(*) AS transfers, sum(bytes) / 1000000 AS mb
FROM logs WHERE product = 'flow' GROUP BY dst_ip ORDER BY mb DESC;
