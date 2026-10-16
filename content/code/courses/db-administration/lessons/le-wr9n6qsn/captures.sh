#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 ends (shop loaded) and installs MySQL 8.0 and
# pgloader from apt's cache, as the lesson tells the student to; apt's own
# output is not quoted. Every file the lesson prints (legacy.sql, mysql8.lisp,
# legacy.load, check-mysql.sql, check-pg.sql) is taken out of the lesson's own
# .md and run as it is printed there.
#
# STAGED:
#   - /etc/default/locale is set to LANG=en_US.UTF-8, which is what Ubuntu's
#     server installer writes and the lab's debootstrapped machine lacks.
#     Without it the mysql client talks latin1 and prints the names in the
#     lesson as mojibake, which is a migration bug of its own and not the one
#     this lesson is about.
#   - The mysql> sessions are typed by a copy of the lab's psql driver that
#     runs `sudo mysql` instead of psql and drops the terminal bell the mysql
#     client rings after an error. The prompt line printed before each one is
#     the command the student types.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh

L=le-wr9n6qsn
lab reset 5
lab root 'echo LANG=en_US.UTF-8 > /etc/default/locale'
lab root 'cat > /root/mysession.sh' <<'SED'
sed -e "s/os.execvpe('psql', \['psql', '-n', '-P', 'pager=off'\] + args, env)/os.execvpe('sudo', ['sudo', 'mysql'] + args, env)/" \
    -e "s/(?:^|\\\\n)(/(?:^|\\\\n)\\\\x07?(/" \
    -e "s/chunk = os.read(fd, 65536)/chunk = os.read(fd, 65536).replace(b'\\\\x07', b'')/" \
    /usr/local/lib/lab/session.py > /usr/local/lib/lab/mysession.py
SED
lab root 'bash /root/mysession.sh'
mysql_session() { # mysql_session DB: lines on stdin are typed at mysql>
  printf 'ana@db:~$ sudo mysql %s\n' "$1"
  lab root "su - ana -c 'python3 /usr/local/lib/lab/mysession.py $1'"
}

lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q mysql-server-8.0 pgloader >/dev/null 2>&1'

block mysql-installed
on 'mysql --version'
on 'sudo mysql -e "SELECT @@version, @@sql_mode, @@collation_server\G"'

fence $L/a-mysql-database.md '-- legacy.sql' | lab as 'cat > legacy.sql'
block legacy-load
on 'sudo mysql < legacy.sql'
mysql_session legacy <<'EOF'
SHOW TABLES;
SELECT COUNT(*) FROM Customers;
SELECT COUNT(*) FROM Orders;
SELECT * FROM Customers LIMIT 3;
EOF

block zero-dates
mysql_session legacy <<'EOF'
SELECT COUNT(*) FROM Customers WHERE BirthDate = '0000-00-00';
SELECT COUNT(*) FROM Customers WHERE BirthDate = 0;
SELECT COUNT(*) FROM Orders WHERE ShippedAt = 0;
INSERT INTO Customers (Email, FullName, BirthDate, CreatedAt) VALUES ('CUSTOMER1@example.com', 'Ana Again', '1990-05-04', NOW());
EOF

block pgloader-first
on "sudo mysql -e \"CREATE USER 'migrator'@'localhost' IDENTIFIED BY 'change-me'; GRANT SELECT, SHOW VIEW ON legacy.* TO 'migrator'@'localhost';\""
on 'createdb legacy'
on 'pgloader --version'
on 'pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy'

block pgloader-alter-only
on "sudo mysql -e \"ALTER USER 'migrator'@'localhost' IDENTIFIED WITH mysql_native_password BY 'change-me';\""
on 'pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy 2>&1 | grep ERROR'

block pgloader-native
on "printf '[mysqld]\\ndefault_authentication_plugin = mysql_native_password\\n' | sudo tee /etc/mysql/mysql.conf.d/pgloader.cnf"
on 'sudo systemctl restart mysql'
on 'pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy'

fence $L/pgloader.md ';; mysql8.lisp' | lab as 'cat > mysql8.lisp'
block pgloader-lisp
on 'pgloader --load-lisp-file mysql8.lisp mysql://migrator:change-me@localhost/legacy postgresql:///legacy; echo "exit status $?"'

fence $L/pgloader.md '-- legacy.load' | lab as 'cat > legacy.load'
block pgloader-load
on 'pgloader --load-lisp-file mysql8.lisp legacy.load > load.log 2>&1; echo "exit status $?"'
on "grep -E 'errors|legacy\.' load.log"

block pg-side
printf 'ana@db:~$ psql legacy\n'
printf '\\dt legacy.*\n\\d customers\n\\d orders\nSHOW search_path;\nSELECT customerid, fullname, birthdate, createdat FROM customers ORDER BY customerid LIMIT 3;\n' | session legacy

fence $L/checking-the-copy.md '-- check-mysql.sql' | lab as 'cat > check-mysql.sql'
fence $L/checking-the-copy.md '-- check-pg.sql' | lab as 'cat > check-pg.sql'
block check
on 'sudo mysql -t legacy < check-mysql.sql'
on 'psql legacy -f check-pg.sql'

block narrow
mysql_session legacy <<'EOF'
SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
SHOW WARNINGS;
SET SESSION group_concat_max_len = 1024 * 1024 * 64;
SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
EOF
printf 'ana@db:~$ psql legacy\n'
printf '%s\n' "SELECT customerid / 500 AS block, md5(string_agg(concat_ws('|', customerid, email, fullname, isactive::int, coalesce(birthdate::text, '\\N'), to_char(createdat, 'YYYY-MM-DD HH24:MI:SS')), E'\\n' ORDER BY customerid)) AS checksum FROM customers GROUP BY block ORDER BY block;" | session legacy

block culprit
mysql_session legacy <<'EOF'
SELECT CustomerID, Email, IsActive FROM Customers WHERE CustomerID >= 2000 AND IsActive NOT IN (0, 1);
EOF

block recheck
on "sed -i 's/FullName, IsActive,/FullName, IsActive <> 0,/' check-mysql.sql"
on 'sudo mysql -t legacy < check-mysql.sql'

block dialect-mysql
mysql_session legacy <<'EOF'
SELECT 5 / 2, 'abc' = 'ABC', IFNULL(NULL, 'none'), CONCAT('a', NULL);
SELECT CustomerID FROM Customers WHERE Email = 'CUSTOMER1@EXAMPLE.COM';
SELECT `Email` FROM Customers ORDER BY CustomerID LIMIT 2, 1;
EOF

block dialect-pg
printf 'ana@db:~$ psql legacy\n'
session legacy <<'EOF'
SELECT 5 / 2, 'abc' = 'ABC', coalesce(NULL, 'none'), concat('a', NULL), 'a' || NULL;
SELECT IFNULL(NULL, 'none');
SELECT customerid FROM customers WHERE email = 'CUSTOMER1@EXAMPLE.COM';
SELECT `email` FROM customers;
SELECT email FROM customers ORDER BY customerid LIMIT 2, 1;
SELECT email FROM customers ORDER BY customerid LIMIT 1 OFFSET 2;
SELECT "CustomerID" FROM customers LIMIT 1;
SELECT CustomerID FROM Customers LIMIT 1;
\q
EOF

block case-unique
printf 'ana@db:~$ psql legacy\n'
session legacy <<'EOF'
INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now()) RETURNING customerid;
DELETE FROM customers WHERE email = 'CUSTOMER1@example.com';
CREATE UNIQUE INDEX customers_email_lower ON customers (lower(email));
INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now());
\q
EOF

block mysql-off
on 'sudo systemctl disable --now mysql'

lab down
