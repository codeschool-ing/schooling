---
title: A program that proves who it is with a key
version: 1
---

`etl_loader` connects every night at three, and so far it does it with a password in Ana's
`~/.pgpass`. A password for a program has two weaknesses that a person's does not. It has to be
stored somewhere the program can read without anybody typing it, which is usually a file or an
environment variable that ends up in more places than intended. And it is a **shared secret**:
the server has a verifier for it, the program has it, and anybody who copies the file has it too.

A **client certificate** replaces it with a key pair. The program holds a private key that never
leaves its machine; the company's CA signs a certificate saying that key belongs to `etl_loader`;
the server checks the signature and that the program holds the key. Nothing the server stores, and
nothing that crosses the wire, is enough to log in.

## Issuing one

Three steps: the program's owner makes a key and a request, the CA signs the request, and the
owner checks what came back.

```
ana@lab:~/gov$ openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout etl_loader.key -subj "/O=Farmacia Ipe/CN=etl_loader" -out etl_loader.csr
-----
ana@lab:~/gov$ sudo openssl x509 -req -in etl_loader.csr -CA /etc/ipe-pki/ca.crt -CAkey /etc/ipe-pki/ca.key -days 90 -sha256 -out etl_loader.crt
Certificate request self-signature ok
subject=O = Farmacia Ipe, CN = etl_loader
ana@lab:~/gov$ chmod 600 etl_loader.key && openssl x509 -in etl_loader.crt -noout -subject -enddate
subject=O = Farmacia Ipe, CN = etl_loader
notAfter=Jan  5 03:21:03 2027 GMT
```

The key is made on the machine where it will be used and **never travels**: only the request,
which carries the public half, goes to the CA. The `CN` is `etl_loader`, and that is not a label
— PostgreSQL's `cert` method compares the certificate's common name with the role the client asks
to be. The certificate is valid for ninety days from the moment it was signed, which the `notAfter`
line shows: a credential for a program should expire on a schedule short enough that renewing it
is a routine rather than an emergency somebody rediscovers every few years.

The signing step needs the CA's private key, and in the lab that is a file only root can read, so
Ana uses `sudo`. In a real company the CA key does not live on the database server at all; a
certificate request goes to whoever runs the CA, and the issuing is itself logged.

## Logging in with it

The fourth line of the new `pg_hba.conf` said `hostssl ipe etl_loader 127.0.0.1/32 cert`.

```
ana@lab:~/gov$ psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full sslcert=etl_loader.crt sslkey=etl_loader.key" -c "SELECT current_user"
 current_user 
--------------
 etl_loader
(1 row)

ana@lab:~/gov$ psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full" -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  connection requires a valid client certificate
ana@lab:~/gov$ sudo tail -n 2 /var/log/postgresql/postgresql-16-gov.log
2026-10-07 00:21:03.816 -03 [27014] [unknown]@[unknown] LOG:  connection received: host=127.0.0.1 port=57900
2026-10-07 00:21:03.822 -03 [27014] etl_loader@ipe FATAL:  connection requires a valid client certificate
```

With the certificate and its key, `etl_loader` is in, and no password was involved. Without
them, the server refuses — even though Ana's `~/.pgpass` still holds the old password, because
for this role the method is no longer a password. The `ssl_ca_file` set in section 5 is what the
server checks client certificates against: the same root that signed its own.

## Seeing who is connected, and how

`pg_stat_ssl` has one more column that matters now, `client_dn`: the subject of the client's
certificate. A superuser can list every session's encryption and identity at once:

```sql
SELECT a.usename, a.client_addr, s.ssl, s.version, s.client_dn
FROM pg_stat_ssl s JOIN pg_stat_activity a USING (pid)
WHERE a.backend_type = 'client backend'
ORDER BY a.usename;
```

```
ana@lab:~/gov$ psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full sslcert=etl_loader.crt sslkey=etl_loader.key" -c "SELECT pg_sleep(3)" >/dev/null & psql service=bruno -c "SELECT pg_sleep(3)" >/dev/null & sleep 1; sudo -u postgres psql < sessions.sql; wait
  usename   | client_addr | ssl | version |           client_dn           
------------+-------------+-----+---------+-------------------------------
 bruno      | 127.0.0.1   | t   | TLSv1.3 | 
 etl_loader | 127.0.0.1   | t   | TLSv1.3 | /O=Farmacia Ipe/CN=etl_loader
 postgres   |             | f   |         | 
(3 rows)
```

Bruno over TLS with a password, `etl_loader` over TLS with a certificate naming it, and the
superuser on the local socket, where there is no network to encrypt. **A query like this, run on
a schedule, is how "every connection is encrypted" is shown rather than claimed** — and a row
with `f` and a client address is the one to chase.
