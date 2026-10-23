#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l11.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l11.txt; done
#
# STAGED, as the lesson says: root installs openjdk-25-jdk-headless,
# php8.3-cli and dotnet-sdk-10.0 with apt before ana types anything. Go 1.27.3
# is unpacked into ~/.local/go from the module proxy's copy of the release
# (go.dev is out of this machine's reach), and linked into ~/.local/bin as the
# lesson's commands would link it. This machine's own python3 is 3.13; ana's
# ~/.local/bin/python3 points at /usr/bin/python3.12, which is what Ubuntu
# 24.04 installs. The programs are taken out of the lesson's .md by shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
O='~/server/other'

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-25-jdk-headless php8.3-cli dotnet-sdk-10.0 >/dev/null 2>&1
if [ ! -x /home/ana/.local/go/bin/go ] || ! /home/ana/.local/go/bin/go version | grep -q go1.27.3; then
  t=$(mktemp -d)
  curl -fsSL -o $t/go.zip https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.3.linux-amd64.zip
  (cd $t && unzip -q go.zip)
  rm -rf /home/ana/.local/go && mv $t/golang.org/toolchain@v0.0.1-go1.27.3.linux-amd64 /home/ana/.local/go
  chmod -R u+w /home/ana/.local/go && chown -R ana:ana /home/ana/.local/go && rm -rf $t
fi
quiet '~' 'ln -sf ~/.local/go/bin/go ~/.local/bin/go; ln -sf /usr/bin/python3.12 ~/.local/bin/python3'
quiet '~' 'rm -rf ~/server/other ~/.dotnet ~/.nuget ~/.aspnet ~/.templateengine; mkdir -p ~/server/other/{node,python,go,java,php,primes}'
for f in one-server-five-ways:hello.mjs:node python:hello.py:python go:main.go:go java:Hello.java:java php:hello.php:php \
  concurrency-models:primes.py:python concurrency-models:main.go:primes; do
  IFS=: read -r md name dir <<<"$f"
  shown $md.md $name "$O/$dir/$name"
done

ASK=("curl -s 'http://127.0.0.1:3000/hello?name=ana'" "curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope"
  "time (for i in \$(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)")

# Each language: its version, then the server in one terminal and the three
# questions in the other.
serve() { # NAME DIR COMMAND
  bg srv "$2" "$3"; wait_port 3000; sleep 0.5
  block $1-ask
  session "$2" "${ASK[@]}"
  bg_stop srv INT; sleep 0.5
  block $1-log
  bg_show srv
  printf '^C\n'
}
serve node "$O/node" 'node hello.mjs'
block python-version
session "$O/python" 'python3 --version'
serve python "$O/python" 'python3 hello.py'
block go-version
session "$O/go" 'go version' 'go mod init hello'
serve go "$O/go" 'go run .'
block go-build
session "$O/go" 'go build -o hello && ls -lh hello && file hello'
block java-version
session "$O/java" 'java -version'
serve java "$O/java" 'java Hello.java'
block php-version
session "$O/php" 'php --version'
serve php "$O/php" 'php -S 127.0.0.1:3000 hello.php'
bg srv "$O/php" 'PHP_CLI_SERVER_WORKERS=10 php -S 127.0.0.1:3000 hello.php'; wait_port 3000; sleep 0.5
block php-workers
session "$O/php" "${ASK[2]}"
bg_stop srv INT; sleep 0.3
block php-workers-log
bg_show srv | head -3
printf '^C\n'

block dotnet-new
session "$O" 'dotnet new web -o csharp'
shown csharp.md Program.cs "$O/csharp/Program.cs"
block dotnet-build
session "$O/csharp" 'dotnet build 2>&1 | tail -3'
# Ctrl-C does not reach a program the lab starts in the background (bash sets
# SIGINT to ignored there, and .NET honours that), so this one is stopped the
# way a service manager would, with SIGTERM from the second terminal.
bg srv "$O/csharp" 'dotnet run --no-build'; wait_port 3000; sleep 0.5
block csharp-ask
session "$O/csharp" "${ASK[@]}" 'pgrep -a csharp'
app=$(pgrep -u ana -f 'bin/Debug/net10.0/csharp' | head -1)
session "$O/csharp" "kill -TERM $app"
sleep 1
block csharp-log
bg_show srv
bg_stop srv

# Computing rather than waiting.
block primes-python
session "$O/python" 'python3 primes.py'
quiet "$O/primes" 'go mod init primes'
block primes-go
session "$O/primes" 'go run .'

# One variable, five languages.
FIVE='(cd node && PORT=4001 node hello.mjs) & (cd python && PORT=4002 python3 hello.py) & (cd go && PORT=4003 ./hello) & (cd java && PORT=4004 java Hello.java) & (cd csharp && PORT=4005 dotnet run --no-build) & wait'
bg five "$O" "$FIVE"
for p in 4001 4002 4003 4004 4005; do wait_port $p; done; sleep 0.5
block five-ask
session "$O" 'for p in 4001 4002 4003 4004 4005; do curl -s "http://127.0.0.1:$p/hello?name=port-$p"; done'
bg_stop five INT; sleep 1
block five-log
bg_show five
printf '^C\n'
