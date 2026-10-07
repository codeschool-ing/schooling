---
title: Um programa que prova quem é com uma chave
version: 1
---

O `etl_loader` conecta toda noite às três, e até agora faz isso com uma senha no `~/.pgpass` da
Ana. Uma senha de programa tem duas fraquezas que a de uma pessoa não tem. Ela precisa ficar
guardada onde o programa a leia sem ninguém digitar, o que costuma ser um arquivo ou uma variável
de ambiente que acaba em mais lugares do que se pretendia. E ela é um **segredo compartilhado**: o
servidor tem um verificador dela, o programa a tem, e quem copiar o arquivo a tem também.

Um **certificado de cliente** a troca por um par de chaves. O programa guarda uma chave privada
que nunca sai da máquina dele; a CA da empresa assina um certificado dizendo que essa chave
pertence a `etl_loader`; o servidor confere a assinatura e que o programa tem a chave. Nada do
que o servidor guarda, e nada do que atravessa o fio, basta para logar.

## Emitindo um

Três passos: o dono do programa faz uma chave e um pedido, a CA assina o pedido, e o dono confere
o que voltou.

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

A chave é feita na máquina onde vai ser usada e **nunca viaja**: só o pedido, que carrega a metade
pública, vai à CA. O `CN` é `etl_loader`, e isso não é um rótulo — o método `cert` do PostgreSQL
compara o nome comum do certificado com o papel que o cliente pede para ser. O certificado vale por
noventa dias a partir do momento em que foi assinado, como mostra a linha `notAfter`: uma
credencial de programa deve expirar numa cadência curta o bastante para renová-la ser rotina, e não
uma emergência que alguém redescobre a cada poucos anos.

A assinatura precisa da chave privada da CA, e no laboratório ela é um arquivo que só o root lê,
então a Ana usa `sudo`. Numa empresa de verdade a chave da CA nem mora no servidor de banco; o
pedido de certificado vai para quem opera a CA, e a emissão também fica registrada.

## Logando com ele

A quarta linha do novo `pg_hba.conf` dizia `hostssl ipe etl_loader 127.0.0.1/32 cert`.

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

Com o certificado e a chave, o `etl_loader` entra, e nenhuma senha foi envolvida. Sem eles, o
servidor recusa — mesmo com o `~/.pgpass` da Ana ainda guardando a senha antiga, porque para esse
papel o método não é mais senha. O `ssl_ca_file` definido na seção 5 é contra o que o servidor
confere certificados de cliente: a mesma raiz que assinou o dele.

## Vendo quem está conectado, e como

O `pg_stat_ssl` tem mais uma coluna que importa agora, `client_dn`: o subject do certificado do
cliente. Um superusuário lista a criptografia e a identidade de toda sessão de uma vez:

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

Bruno por TLS com senha, `etl_loader` por TLS com um certificado que o nomeia, e o superusuário no
socket local, onde não há rede para cifrar. **Uma consulta assim, rodada num calendário, é como
"toda conexão é cifrada" se mostra em vez de se afirmar** — e uma linha com `f` e um endereço de
cliente é a que se vai investigar.
