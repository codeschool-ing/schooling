#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. seats.proto,
# boxoffice's Go files and the seats client are assembled from lessons 1 to 10
# by ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - protoc 3.21.12 was installed with `apt install protobuf-compiler` before
#     the run, the command the lesson shows; its output is not transcribed.
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     section 02 has ana do in ~/.profile; the database is dropped and made
#     again so that ids start at 1.
#   - the server is started in the background and stopped by the script. The
#     watch of section 07 runs in the background too, its output kept in a file
#     and printed after the two purchases made while it ran; the lesson has the
#     student run it in one terminal and the purchases in another.
#   - seats_v2.proto, for the last section, is the lesson's seats.proto with
#     one field added by the sed the lesson shows.
# Timestamps, durations and tokens are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, protoc 3.21.12,
# PostgreSQL 16.15, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
project 10 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate'

block install
on . 'protoc --version'
on . 'go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12'
on . 'go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2'
on . 'protoc-gen-go --version; protoc-gen-go-grpc --version'

block missing
on boxoffice 'PATH=/usr/bin:/bin protoc --go_out=. --go_opt=module=example.com/boxoffice proto/seats.proto'

block generate
on boxoffice 'protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto'
on boxoffice 'ls internal/seatspb; wc -l internal/seatspb/*.go'
on boxoffice 'sed -n "/^type Event struct/,/^}/p" internal/seatspb/seats.pb.go'
on boxoffice 'sed -n "/^type SeatsServer interface/,/^}/p;/^type SeatsClient interface/,/^}/p" internal/seatspb/seats_grpc.pb.go'

block wire
on boxoffice "echo 'id: 1 name: \"Jazz at the Docks\" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | od -An -tx1"
on boxoffice "echo 'id: 1 name: \"Jazz at the Docks\" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | wc -c"
on boxoffice "echo 'id: 1 name: \"Jazz at the Docks\" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | protoc --decode_raw"
on boxoffice "printf '%s' '{\"id\":1,\"name\":\"Jazz at the Docks\",\"seats\":120,\"sold\":2}' | wc -c"

block unary
quiet boxoffice 'go mod tidy'
on boxoffice 'go vet ./...'
on boxoffice 'go build -o seats ./cmd/seats'
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice './seats get 1'
on boxoffice './seats get 9'
on boxoffice './seats get 4294967297'

block streaming
lab exec boxoffice "cd ~/boxoffice
./seats watch 1 4 > watch.out 2>&1 &
sleep 1.2
echo \"ana@vm:~/boxoffice\\$ curl -s --json '{\\\"quantity\\\": 2, \\\"email\\\": \\\"ana@example.com\\\"}' localhost:8080/events/1/tickets\" > buy.out
curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets >> buy.out
sleep 1
echo \"ana@vm:~/boxoffice\\$ curl -s --json '{\\\"quantity\\\": 3, \\\"email\\\": \\\"rui@example.com\\\"}' localhost:8080/events/1/tickets\" >> buy.out
curl -s --json '{\"quantity\": 3, \"email\": \"rui@example.com\"}' localhost:8080/events/1/tickets >> buy.out
sleep 3"
printf 'ana@vm:~/boxoffice$ ./seats watch 1 4\n'
lab exec boxoffice 'cat watch.out'
block buys
lab exec boxoffice 'cat buy.out'
block streaming2
on boxoffice './seats watch 9 4'
on boxoffice './seats scan 1 2 3 99 2'

block log
stop
on boxoffice 'cat .server.log'

block evolving
on boxoffice "sed 's/  int32 sold = 4;/  int32 sold = 4;\n  string venue = 5;/' proto/seats.proto > /tmp/seats_v2.proto && grep -A6 '^message Event' /tmp/seats_v2.proto"
on boxoffice "echo 'id: 1 name: \"Jazz at the Docks\" seats: 120 sold: 2 venue: \"Main Hall\"' | protoc -I/tmp --encode=boxoffice.v1.Event /tmp/seats_v2.proto | protoc --decode=boxoffice.v1.Event proto/seats.proto"
quiet boxoffice 'rm -f /tmp/seats_v2.proto'
