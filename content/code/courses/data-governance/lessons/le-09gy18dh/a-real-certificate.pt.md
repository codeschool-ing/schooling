---
title: Um certificado que vale a conferência
version: 1
---

O laboratório precisa de uma autoridade certificadora própria, e a Ana cria uma com o OpenSSL:
uma raiz, **Ipe Lab Root CA**, e dois certificados que ela assina — um para o nome do banco,
`db.ipe.example`, e um para `bao.ipe.example`, o servidor de chaves que a aula 4 inicia. Numa
empresa, essa é a CA interna que o time de plataforma opera, ou uma pública quando o banco é
alcançado de fora, e a chave dela fica offline. O laboratório a guarda em `/etc/ipe-pki`, legível só
pelo root.

```sh
sudo mkdir -p /etc/ipe-pki && cd /etc/ipe-pki
sudo openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
  -keyout ca.key -subj "/O=Farmacia Ipe/CN=Ipe Lab Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -days 3650 -sha256 -out ca.crt
for name in db bao; do
  sudo openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout $name.key -subj "/O=Farmacia Ipe/CN=$name.ipe.example" -out $name.csr
  printf 'subjectAltName=DNS:%s.ipe.example\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth,clientAuth\n' $name \
    | sudo tee $name.ext >/dev/null
  sudo openssl x509 -req -in $name.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 825 -sha256 -out $name.crt -extfile $name.ext
  sudo rm $name.csr $name.ext
done
sudo chmod 0600 *.key && sudo chmod 0644 *.crt
cd ~/gov
```

A raiz diz que é uma CA e que pode assinar certificados (`basicConstraints`, `keyUsage`); cada
certificado nomeia o host no seu Subject Alternative Name e diz que pode ser usado por um servidor e
por um cliente. A biblioteca de TLS do Python recusa uma CA que não diga isso, e a aula 4 a usa.

Antes de instalar qualquer coisa, leia o que o certificado do banco diz:

```
ana@lab:~/gov$ openssl x509 -in /etc/ipe-pki/db.crt -noout -subject -issuer -ext subjectAltName
subject=O = Farmacia Ipe, CN = db.ipe.example
issuer=O = Farmacia Ipe, CN = Ipe Lab Root CA
X509v3 Subject Alternative Name: 
    DNS:db.ipe.example
ana@lab:~/gov$ openssl verify -CAfile /etc/ipe-pki/ca.crt /etc/ipe-pki/db.crt
/etc/ipe-pki/db.crt: OK
```

Três fatos, cada um uma conferência que o cliente vai fazer:

- **o subject e o Subject Alternative Name dizem `db.ipe.example`** — o nome a que os clientes
  conectam. Clientes modernos comparam o nome do host com o SAN, não com o subject;
- **o emissor é a raiz do laboratório**, então um cliente que confia na raiz confia neste;
- **`openssl verify` diz OK**: a assinatura nele foi mesmo feita por aquela raiz.

## Instalando-o no servidor

```sql
-- The server's own certificate, signed by the lab CA, instead of the one
-- Ubuntu generated on the day the cluster was made.
ALTER SYSTEM SET ssl_cert_file = '/etc/postgresql/16/gov/db.crt';
ALTER SYSTEM SET ssl_key_file  = '/etc/postgresql/16/gov/db.key';
ALTER SYSTEM SET ssl_ca_file   = '/etc/postgresql/16/gov/ca.crt';
ALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.3';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 644 /etc/ipe-pki/db.crt /etc/ipe-pki/ca.crt /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 600 /etc/ipe-pki/db.key /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql < tls.sql
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)
```

A chave privada é o único arquivo que importa, e ela entra com modo `600`, dona `postgres`: o
servidor se recusa a subir com uma chave que outros usuários consigam ler, pelo mesmo motivo por
que a libpq recusou o arquivo de senhas da Ana na aula 1. `ssl_min_protocol_version` recusa
qualquer coisa mais velha que TLS 1.3. Todo cliente do laboratório fala essa versão; uma empresa
com clientes antigos poria 1.2 e anotaria quais clientes são o motivo.

## Dando a autoridade ao cliente

```
ana@lab:~/gov$ mkdir -p ~/.postgresql && cp /etc/ipe-pki/ca.crt ~/.postgresql/root.crt
ana@lab:~/gov$ psql "service=bruno sslmode=verify-full" -c "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl | version 
-----+---------
 t   | TLSv1.3
(1 row)
```

O `verify-full` agora funciona. O cliente conferiu que o certificado foi assinado pela raiz do
`root.crt` e que foi emitido para `db.ipe.example`, o nome na entrada de serviço do Bruno.

Então toda entrada do arquivo de serviço da Ana ganha a mesma linha, e daqui em diante toda
conexão deste curso confere o servidor com quem fala:

```
ana@lab:~/gov$ sed -i '/^user=/a sslmode=verify-full' ~/.pg_service.conf && grep -c verify-full ~/.pg_service.conf
3
ana@lab:~/gov$ psql service=carla -c "SELECT current_user, ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 current_user | ssl 
--------------+-----
 carla        | t
(1 row)
```

## A conferência que pega o nome errado

A segunda metade do `verify-full` é a que as pessoas desligam quando atrapalha. O mesmo servidor,
alcançado pelo endereço em vez do nome:

```
ana@lab:~/gov$ psql "host=127.0.0.1 port=5433 dbname=ipe user=bruno sslmode=verify-full" -c "SELECT 1"
psql: error: connection to server at "127.0.0.1", port 5433 failed: server certificate for "db.ipe.example" (and 1 other name) does not match host name "127.0.0.1"
```

O certificado é válido, assinado pela raiz confiável, e **recusado**, porque foi emitido para
`db.ipe.example` e o cliente pediu `127.0.0.1`. Essa recusa é a proteção: um certificado roubado de
um host, ou emitido legitimamente para outro, não funciona para este. O "conserto" de sempre —
descer para `verify-ca` ou `require` porque o nome não bate — tira exatamente a conferência que
impede alguém de apresentar o certificado de outra máquina. O conserto certo é conectar pelo nome
que o certificado carrega, ou emitir um que carregue o nome que você usa.
