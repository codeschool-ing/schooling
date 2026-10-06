#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and a `go mod init` in each directory, which
# lesson 4 showed and this one does not repeat. The two `go mod edit -go=…`
# runs are typed and shown; the line is put back to 1.27.1 straight after.
# Nothing in the output varies between runs.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on DIR 'command': what ana typed in ~/DIR, and what it printed.
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
put() { lab put "$1"; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# --- array-to-slice ---------------------------------------------------------
lab fresh slicearray
put slicearray/main.go <<'EOF'
package main

import "fmt"

func main() {
	a := [4]int{1, 2, 3, 4}
	s := a[:]
	s[0] = 100
	fmt.Println(a, s, len(s), cap(s))
}
EOF
quiet slicearray 'go mod init example.com/slicearray'

block whole
on slicearray 'go run .'

lab fresh slicearray-hash
put slicearray-hash/main.go <<'EOF'
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum))
	fmt.Println(hex.EncodeToString(sha256.Sum256([]byte("hello"))[:]))
}
EOF
quiet slicearray-hash 'go mod init example.com/hash'

block hash-wrong
on slicearray-hash 'go doc crypto/sha256.Sum256'
on slicearray-hash 'go run .'

put slicearray-hash/main.go <<'EOF'
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	sum := sha256.Sum256([]byte("hello"))
	fmt.Println(hex.EncodeToString(sum[:]))
}
EOF

block hash-right
on slicearray-hash 'go run .'

# --- slice-to-array ---------------------------------------------------------
lab fresh slicearray-conv
put slicearray-conv/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := []int{1, 2, 3, 4, 5, 6}

	c := [4]int(s)
	c[0] = 100
	fmt.Println(s, c)

	p := (*[4]int)(s)
	p[0] = 100
	fmt.Println(s, *p)
}
EOF
quiet slicearray-conv 'go mod init example.com/conv'

block conv
on slicearray-conv 'go run .'

block conv-versions
on slicearray-conv 'go mod edit -go=1.19 && go build'
on slicearray-conv 'go mod edit -go=1.16 && go build'
on slicearray-conv 'go mod edit -go=1.27.1 && go build && echo built'

lab fresh slicearray-short
put slicearray-short/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := []int{1, 2}
	fmt.Println([4]int(s))
}
EOF
quiet slicearray-short 'go mod init example.com/short'

block short
on slicearray-short 'go run .'

lab fresh slicearray-ip
put slicearray-ip/main.go <<'EOF'
package main

import (
	"fmt"
	"net/netip"
)

func main() {
	raw := []byte{192, 168, 0, 10, 0, 80}
	addr := netip.AddrFrom4([4]byte(raw))
	fmt.Println(addr)
}
EOF
quiet slicearray-ip 'go mod init example.com/ip'

block ip
on slicearray-ip 'go doc net/netip.AddrFrom4'
on slicearray-ip 'go run .'

lab fresh slicearray-stale
put slicearray-stale/main.go <<'EOF'
package main

import "fmt"

func main() {
	buf := []byte{192, 168, 0, 10, 0, 80}
	short := buf[:3]

	fmt.Println([4]byte(short[:4]))
	fmt.Println([4]byte(short))
}
EOF
quiet slicearray-stale 'go mod init example.com/stale'

block stale
on slicearray-stale 'go run .'

# --- where-it-matters -------------------------------------------------------
lab fresh slicearray-eq
put slicearray-eq/main.go <<'EOF'
package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
)

func main() {
	x := []byte("hello")
	y := []byte("hello")
	fmt.Println(sha256.Sum256(x) == sha256.Sum256(y))
	fmt.Println(bytes.Equal(x, y))
}
EOF
quiet slicearray-eq 'go mod init example.com/eq'

block eq
on slicearray-eq 'go run .'

lab fresh slicearray-dedup
put slicearray-dedup/main.go <<'EOF'
package main

import (
	"crypto/sha256"
	"fmt"
)

func main() {
	names := []string{"a.txt", "b.txt", "c.txt", "d.txt"}
	bodies := []string{"hello", "world", "hello", "hello\n"}

	seen := map[[32]byte]string{}
	for i := 0; i < len(names); i++ {
		sum := sha256.Sum256([]byte(bodies[i]))
		if seen[sum] != "" {
			fmt.Println(names[i], "has the same contents as", seen[sum])
			continue
		}
		seen[sum] = names[i]
	}
	fmt.Println(len(seen), "different contents")
}
EOF
quiet slicearray-dedup 'go mod init example.com/dedup'

block dedup
on slicearray-dedup 'go run .'
