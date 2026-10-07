---
title: "O laboratório, parte 3: certificados e um servidor web"
version: 1
---

O `www.example.com` é servido por HTTPS, então antes de existir um servidor web precisa existir alguém
que responda por ele. **O `web.sh` cria primeiro as autoridades certificadoras do laboratório**, e
depois o servidor web.

`build_tls` cria uma autoridade certificadora raiz, a *Example Root CA*, e uma intermediária assinada
por ela, a *Example Issuing CA 1*. Esse é o formato de todo certificado público da internet, uma raiz
guardada com cuidado e uma intermediária que faz a assinatura do dia a dia, e a aula 6 segue a cadeia
elo por elo. A raiz entra no repositório de confiança do Ubuntu com o `update-ca-certificates`, que é
como toda máquina do laboratório passa a confiar no servidor web, e é por isso que o `down` a tira de
novo. `cert` emite um certificado de servidor válido por 90 dias, o prazo que o Let's Encrypt usa.

**Quatro certificados estão quebrados de propósito**, porque a aula 6 seção 06 precisa de uma falha de
cada tipo: um que venceu em 2025, um que o próprio servidor assinou, um servido sem a intermediária e
um assinado pela autoridade certificadora do próprio escritório, em que ninguém confia até alguém
instalá-la. `ca_dated` usa o `openssl ca`, a única ferramenta aqui que aceita datas explícitas, já que
um certificado vencido não se faz pedindo uma validade no passado.

`build_web` então configura o nginx no `www`: a porta 80 redireciona para HTTPS, a porta 443 serve um
site de uma página, e mais quatro nomes servem a mesma página com os certificados quebrados. O bloco
`location /app/` aponta para um programa na porta 9000 que não está lá, um defeito que a aula 5 usa.

Salve-o como `~/netlab/web.sh`:

```sh
nano ~/netlab/web.sh
```

```bash
# ~/netlab/web.sh: the certificate authorities and the web server for
# www.example.com, with four certificates that are broken on purpose.

# ------------------------------------------------------------------ the web
build_tls() {
  local ca=$LAB/ca
  mkdir -p "$ca" && cd "$ca"
  # A root that signs an intermediate that signs the servers: the shape of
  # every public certificate, drawn at the size of a lab.
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 3650 \
    -subj "/O=Example Trust Services/CN=Example Root CA" -keyout root.key -out root.crt \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -subj "/O=Example Trust Services/CN=Example Issuing CA 1" -keyout issuing.key -out issuing.csr 2>/dev/null
  openssl x509 -req -in issuing.csr -CA root.crt -CAkey root.key -CAcreateserial -days 1825 -out issuing.crt \
    -extfile <(printf 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n') 2>/dev/null
  cp root.crt /usr/local/share/ca-certificates/example-root-ca.crt
  update-ca-certificates >/dev/null 2>&1
}
cert() {  # cert NAME DAYS SAN... -> $LAB/ca/NAME.{key,crt,chain}
  local n=$1 days=$2; shift 2
  local san; san=$(printf 'DNS:%s,' "$@"); san=${san%,}
  cd "$LAB/ca"
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=$1" -keyout "$n.key" -out "$n.csr" 2>/dev/null
  openssl x509 -req -in "$n.csr" -CA issuing.crt -CAkey issuing.key -CAcreateserial -days "$days" -out "$n.crt" \
    -extfile <(printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=critical,digitalSignature\nbasicConstraints=critical,CA:FALSE\n' "$san") 2>/dev/null
  cat "$n.crt" issuing.crt > "$n.chain"
}
# openssl ca, because it is the one tool here that takes explicit dates: an
# expired certificate cannot be made by asking for a validity in the past.
ca_dated() {  # ca_dated NAME START END  (dates as YYYYMMDDHHMMSSZ)
  cd "$LAB/ca"
  mkdir -p newcerts; [ -e index.txt ] || : > index.txt; [ -e serial ] || echo 1000 > serial
  cat > ca.cnf <<CNF
[ca]
default_ca = issuing
[issuing]
dir = $LAB/ca
database = \$dir/index.txt
new_certs_dir = \$dir/newcerts
certificate = \$dir/issuing.crt
private_key = \$dir/issuing.key
serial = \$dir/serial
default_md = sha256
policy = anything
unique_subject = no
[anything]
commonName = supplied
[server]
subjectAltName = DNS:$1
extendedKeyUsage = serverAuth
keyUsage = critical,digitalSignature
basicConstraints = critical,CA:FALSE
CNF
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=$1" -keyout "$1.key" -out "$1.csr" 2>/dev/null
  openssl ca -batch -config ca.cnf -extensions server -startdate "$2" -enddate "$3" -in "$1.csr" -out "$1.crt" -notext 2>/dev/null
  cat "$1.crt" issuing.crt > "$1.chain"
}
# The office's own certificate authority, for its intranet. Nobody trusts it
# until somebody installs it.
office_ca() {
  cd "$LAB/ca"
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 3650 \
    -subj "/O=Example Ltd/CN=Example Ltd Office CA" -keyout office.key -out office.crt \
    -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=intranet.example.com" -keyout intranet.example.com.key -out intranet.csr 2>/dev/null
  openssl x509 -req -in intranet.csr -CA office.crt -CAkey office.key -CAcreateserial -days 365 -out intranet.example.com.crt \
    -extfile <(printf 'subjectAltName=DNS:intranet.example.com\nextendedKeyUsage=serverAuth\nbasicConstraints=critical,CA:FALSE\n') 2>/dev/null
  cp intranet.example.com.crt intranet.example.com.chain
}
# A certificate the server signed itself.
self_signed() {
  cd "$LAB/ca"
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=$1" \
    -addext "subjectAltName=DNS:$1" -keyout "$1.key" -out "$1.crt" 2>/dev/null
  cp "$1.crt" "$1.chain"
}
vhost() {  # vhost NAME CHAINFILE-BASENAME  (serves the same pages under another name and certificate)
  cp "$LAB/ca/$2.chain" "$LAB/www/etc/ssl/private/$1.crt"
  cp "$LAB/ca/${3:-$2}.key" "$LAB/www/etc/ssl/private/$1.key"
  cat >> "$LAB/www/etc/nginx/sites-enabled/example.com" <<SITE
server {
    listen 443 ssl http2;
    server_name $1;
    ssl_certificate     /etc/ssl/private/$1.crt;
    ssl_certificate_key /etc/ssl/private/$1.key;
    root /var/www/example;
}
SITE
}
build_web() {
  cert www.example.com 90 www.example.com example.com shop.example.com
  local n="$LAB/www/etc/nginx"
  mkdir -p "$n" "$LAB/www/var/www/example" "$LAB/www/var/log/nginx" "$LAB/www/etc/ssl/private"
  cp -a /etc/nginx/. "$n/"
  rm -f "$n/sites-enabled/"*
  cp "$LAB/ca/www.example.com.chain" "$LAB/www/etc/ssl/private/example.com.crt"
  cp "$LAB/ca/www.example.com.key" "$LAB/www/etc/ssl/private/example.com.key"
  sed -i 's#^pid .*#pid /run/nginx-www.pid;#; s#^worker_processes .*#worker_processes 1;#' "$n/nginx.conf"
  cat > "$n/sites-enabled/example.com" <<'SITE'
server {
    listen 80;
    server_name example.com www.example.com shop.example.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name example.com www.example.com shop.example.com;
    ssl_certificate     /etc/ssl/private/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    root /var/www/example;
    location / { try_files $uri $uri/ =404; }
    # the booking application, meant to run behind nginx on port 9000
    location /app/ { proxy_pass http://127.0.0.1:9000; }
}
SITE
  cat > "$LAB/www/var/www/example/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Example Ltd</title></head>
<body><h1>Example Ltd</h1><p>Accounting for small offices.</p></body>
</html>
HTML
  chown -R www-data:www-data "$LAB/www/var/log/nginx"
  # lesson 6's four broken certificates
  ca_dated expired.example.com 20250601000000Z 20250830000000Z
  vhost expired.example.com expired.example.com
  self_signed selfsigned.example.com
  vhost selfsigned.example.com selfsigned.example.com
  cert nochain.example.com 90 nochain.example.com
  cp "$LAB/ca/nochain.example.com.crt" "$LAB/ca/nochain.example.com.leaf"
  cp "$LAB/ca/nochain.example.com.crt" "$LAB/ca/nochain.example.com.chain"
  vhost nochain.example.com nochain.example.com
  office_ca
  vhost intranet.example.com intranet.example.com
}

```
