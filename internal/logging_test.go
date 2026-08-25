package internal_test

import (
	"go/ast"
	"strings"
	"testing"
)

/*
EVERY COMMAND TAKES ITS LOGGER FROM ONE PLACE.

	There were four, each writing `slog.New(slog.NewJSONHandler(os.Stdout,
	nil))`, and they agreed — which is the state in which nobody notices they
	are four things. Then one of them turned out to be wrong in a way all four
	were: `slog` writes `level` and `msg`, Cloud Logging reads `severity` and
	`message`, so every line this platform had ever written was filed with no
	severity at all.

	THAT IS WHY THIS IS A RULE AND NOT A TIDY-UP. K-08 puts operational alerts
	outside the console, because they have to reach a phone when the console is
	down — and the thing Google's alerting filters on is the field nobody was
	writing. A fifth command copying the old line would put itself back outside
	every alert policy, silently, and look exactly like the other four in a code
	review.

	TESTS MAY BUILD THEIR OWN. A test wants a logger writing to a buffer it can
	read, or to `io.Discard`, and neither has anything to do with how a
	deployment is watched.
*/
func TestEveryCommandTakesItsLoggerFromOnePlace(t *testing.T) {
	const allowed = "internal/platform/logs/"

	eachGoFile(t,
		func(rel string) bool { return isTest(rel) || strings.HasPrefix(rel, allowed) },
		func(rel string, file *ast.File) {
			ast.Inspect(file, func(n ast.Node) bool {
				if calls(n, "slog", "New") {
					t.Errorf("%s builds its own logger — every command takes one from %s, "+
						"because the field names in it are Google's and a copy that misses "+
						"them writes lines no alert policy can see. Use logs.New(os.Stdout)",
						rel, strings.TrimSuffix(allowed, "/"))
				}
				return true
			})
		})
}
