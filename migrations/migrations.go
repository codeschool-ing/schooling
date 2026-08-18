// Package migrations carries the schema files into the binary.
//
// It exists because `//go:embed` cannot reach outside its own directory, so
// the files have to be embedded from where they live. That is a constraint of
// the tool and it produces the right shape anyway: the SQL and the code that
// knows how to read it sit together, and the command that applies them holds
// no paths.
package migrations

import "embed"

//go:embed *.sql
var Files embed.FS
