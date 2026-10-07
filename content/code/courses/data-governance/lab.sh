#!/usr/bin/env bash
# The machine every transcript in data-governance was recorded on, and the one
# lesson 1 has the student build for themselves.
#
# ONE LINUX COMPUTER, ONE PERSON AND A FEW ROLES. Ana is the data engineer of
# Farmácia Ipê, an online pharmacy that does not exist, with customers all
# over Brazil. ~/gov is her working directory. The course governs Ipê's
# database: who may connect to it, what each of them may read, what is
# encrypted and with which key, what is personal and what the law says about
# it, how long it is kept and who changed what.
#
#   PostgreSQL 16   a cluster of its own, `16/gov` on port 5433, made with
#                   Ubuntu's pg_createcluster, so it sits beside any cluster
#                   already on the machine and its files are where Ubuntu
#                   puts them: /etc/postgresql/16/gov and
#                   /var/lib/postgresql/16/gov. Database `ipe`, built from
#                   lab/schema.sql and loaded from the files lab/generate.py
#                   writes. pgaudit and pgcrypto are installed for lessons 3,
#                   5 and 10.
#   OpenBao 2.5.5   the open-source fork of HashiCorp Vault, pinned by
#                   checksum, in /usr/local/bin/bao. Lesson 4 starts it,
#                   initialises it and unseals it; this script only installs
#                   it and writes its configuration.
#   a lab CA        /etc/ipe-pki, made with openssl at `up`: a root that
#                   signs the certificates of db.ipe.example and
#                   bao.ipe.example. Both names point at 127.0.0.1 in
#                   /etc/hosts. Lesson 3 is where the server certificate is
#                   put to use.
#   Python 3        the standard library only: generate.py, and the small
#                   checkers lessons 9 and 11 write.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16, its roles, grants, row security and pgaudit;
#             OpenSSL and the TLS it negotiates; OpenBao and its transit
#             engine; LUKS through cryptsetup, as far as lesson 3 says.
#   written   every row of data, drawn from fixed seeds (lab/generate.py
#             says how, and what was made so that it cannot be real). The
#             lab's TODAY is 2026-07-01; queries that need a date write it.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: AWS KMS, Google Cloud KMS, Azure Key
# Vault and any cloud data platform. Lesson 4 shows their commands and says
# so; what it runs instead runs here, on OpenBao.
#
#   sudo bash lab.sh up               install, build and load (idempotent)
#   sudo bash lab.sh reset            rebuild the cluster, `ipe` and ~/gov
#   sudo bash lab.sh state N          bring the database to where lesson N
#                                     ends, by running lab/state/01.sh to N
#   sudo bash lab.sh down             stop PostgreSQL and OpenBao
#   sudo bash lab.sh exec 'COMMAND'   run COMMAND as ana, in ~/gov
#
# Recorded on Ubuntu 24.04, 4 cores, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. A server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA=/var/lib/ipe-data
GOV=/home/ana/gov
PKI=/etc/ipe-pki
PORT=5433
BAO_VERSION=2.5.5
BAO_SHA256=2c5577707e97fc95c2086950f39880ead5e45b356c94388e5cb606f5a5c2b697
PACKAGES="postgresql-16 postgresql-16-pgaudit openssl cryptsetup python3 curl sudo"

ENVFILE=/etc/ipe-lab.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
PGPORT=$PORT
PGDATABASE=ipe
PAGER=cat
BAO_ADDR=https://bao.ipe.example:8200
BAO_CACERT=$PKI/ca.crt
EOF
  # The same, for the person typing: lesson 1 has the student do this by hand.
  grep -q 'BAO_ADDR' /home/ana/.bashrc 2>/dev/null || cat >> /home/ana/.bashrc <<EOF
export PGPORT=$PORT PGDATABASE=ipe
export BAO_ADDR=https://bao.ipe.example:8200 BAO_CACERT=$PKI/ca.crt
EOF
}

as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana $(cat "$ENVFILE") \
    bash -c "$1"
}
as_pg() {
  runuser -u postgres -- env PGPORT=$PORT TZ=America/Sao_Paulo LC_ALL=C.UTF-8 \
    psql -X -q -v ON_ERROR_STOP=1 "$@"
}

install_packages() {
  local missing=""
  for p in $PACKAGES; do
    dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
  done
  if [ -n "$missing" ]; then
    apt-get update -q >/dev/null
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q $missing >/dev/null
  fi
}

install_bao() {
  if ! /usr/local/bin/bao version 2>/dev/null | grep -q "v$BAO_VERSION"; then
    local tmp
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/bao.tgz" \
      "https://github.com/openbao/openbao/releases/download/v$BAO_VERSION/bao_${BAO_VERSION}_Linux_x86_64.tar.gz"
    echo "$BAO_SHA256  $tmp/bao.tgz" | sha256sum -c --quiet
    tar -xzf "$tmp/bao.tgz" -C "$tmp" bao
    install -m 0755 "$tmp/bao" /usr/local/bin/bao
    rm -rf "$tmp"
  fi
  id bao >/dev/null 2>&1 || useradd --system --home /var/lib/bao --shell /usr/sbin/nologin bao
  mkdir -p /etc/bao /var/lib/bao/data
  chown -R bao:bao /var/lib/bao
  cat > /etc/bao/bao.hcl <<EOF
# OpenBao for the lab: one node, its data in a directory, TLS on the
# listener with the lab CA's certificate for bao.ipe.example.
storage "file" {
  path = "/var/lib/bao/data"
}
listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_cert_file = "/etc/bao/bao.crt"
  tls_key_file  = "/etc/bao/bao.key"
}
api_addr      = "https://bao.ipe.example:8200"
disable_mlock = true
ui            = false
EOF
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # In the virtual machine the student is an administrator of it; so is ana.
  echo 'ana ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ana
  chmod 0440 /etc/sudoers.d/ana
}

# Ubuntu's psql asks pg_wrapper which cluster to talk to. This line makes it
# 16/gov and the database ipe for every user, so that `psql` and
# `sudo -u postgres psql` both arrive here without naming a port. A
# connection by host name does not ask pg_wrapper, which is why ana's
# environment also carries PGPORT.
build_default_cluster() {
  echo '* * 16 gov ipe' > /etc/postgresql-common/user_clusters
}

build_hosts() {
  grep -q 'db.ipe.example' /etc/hosts || \
    echo '127.0.0.1 db.ipe.example bao.ipe.example' >> /etc/hosts
}

# The lab CA. A real one keeps its key offline; this one keeps it in a
# directory only root can read, which is what lesson 3 says not to do.
issue() { # issue NAME DNSNAME
  openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout "$PKI/$1.key" -subj "/O=Farmacia Ipe/CN=$2" -out "$PKI/$1.csr" 2>/dev/null
  openssl x509 -req -in "$PKI/$1.csr" -CA "$PKI/ca.crt" -CAkey "$PKI/ca.key" \
    -CAcreateserial -days 825 -sha256 -out "$PKI/$1.crt" \
    -extfile <(printf 'subjectAltName=DNS:%s\nextendedKeyUsage=serverAuth,clientAuth\n' "$2") \
    2>/dev/null
  rm -f "$PKI/$1.csr"
}
build_pki() {
  mkdir -p $PKI
  chmod 0755 $PKI
  if [ ! -f $PKI/ca.crt ]; then
    openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
      -keyout $PKI/ca.key -subj "/O=Farmacia Ipe/CN=Ipe Lab Root CA" \
      -days 3650 -sha256 -out $PKI/ca.crt 2>/dev/null
    issue db db.ipe.example
    issue bao bao.ipe.example
  fi
  chmod 0600 $PKI/*.key
  chmod 0644 $PKI/*.crt
  install -m 0644 -o bao -g bao $PKI/bao.crt /etc/bao/bao.crt
  install -m 0600 -o bao -g bao $PKI/bao.key /etc/bao/bao.key
}

build_data() {
  if [ ! -f $DATA/.done ]; then
    rm -rf $DATA && mkdir -p $DATA
    python3 "$HERE/lab/generate.py" $DATA
    touch $DATA/.done
  fi
  chmod -R a+rX $DATA
}

pg_cluster() {
  if pg_lsclusters -h | awk '{print $1"/"$2}' | grep -qx '16/gov'; then
    pg_ctlcluster 16 gov stop -m fast 2>/dev/null || true
    pg_dropcluster 16 gov
  fi
  pg_createcluster 16 gov --port $PORT --locale C.UTF-8 >/dev/null
  cat >> /etc/postgresql/16/gov/postgresql.conf <<EOF

# --- the lab ---
timezone = 'America/Sao_Paulo'
log_timezone = 'America/Sao_Paulo'
shared_preload_libraries = 'pgaudit'
EOF
  pg_ctlcluster 16 gov start
}

load() {
  as_pg -c "CREATE DATABASE ipe"
  as_pg -d ipe -f "$HERE/lab/schema.sql"
  local t
  for t in sales.customers sales.products sales.orders sales.order_items \
           sales.payments health.prescriptions support.tickets; do
    as_pg -d ipe -c "\\copy $t FROM '$DATA/${t#*.}.csv' WITH (FORMAT csv, HEADER true)"
  done
  as_pg -d ipe -c 'VACUUM ANALYZE'
}

reset() {
  pkill -u bao -x bao 2>/dev/null || true
  rm -rf /var/lib/bao/data && mkdir -p /var/lib/bao/data && chown bao:bao /var/lib/bao/data
  rm -rf $GOV /home/ana/.pgpass /home/ana/.psql_history /home/ana/.pg_service.conf /home/ana/.postgresql
  mkdir -p $GOV
  chown -R ana:ana $GOV
  pg_cluster
  load
}

state() {
  local n=$1 f
  for f in "$HERE"/lab/state/*.sh; do
    [ "$(basename "$f" .sh)" -le "$n" ] || break
    HERE="$HERE" PKI="$PKI" PORT="$PORT" GOV="$GOV" ENVFILE="$ENVFILE" bash "$f"
  done
}

case "${1:-}" in
  up)
    install_packages; build_user; write_env; build_default_cluster; build_hosts; install_bao; build_pki
    build_data; reset ;;
  reset)
    reset ;;
  state)
    state "$2" ;;
  down)
    pkill -u bao -x bao 2>/dev/null || true
    pg_ctlcluster 16 gov stop -m fast 2>/dev/null || true ;;
  exec)
    as_ana "cd $GOV || exit 1; $2" ;;
  *)
    echo "usage: lab.sh up | reset | state N | down | exec 'COMMAND'" >&2; exit 2 ;;
esac
