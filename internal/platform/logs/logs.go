// Package logs builds the logger every command uses.
//
// # WHY THIS IS NOT FOUR CALLS TO `slog.New`
//
// It was, and they agreed, which is the state in which nobody notices they are
// four things. The moment one of them needed a change, three would have been
// left behind — and the way that shows is a job whose lines look subtly unlike
// the server's in the one console where somebody is comparing them.
//
// # AND THE FIELD NAMES ARE GOOGLE'S, BECAUSE THAT IS WHERE THEY LAND
//
// `slog`'s JSON handler writes `level` and `msg`. Cloud Logging reads
// `severity` and `message` and nothing else: a payload calling it `level` is
// a payload with NO severity, so every line this platform has ever written —
// warnings and errors included — is filed as the default and shows up in the
// viewer with a grey dot.
//
// THAT IS NOT COSMETIC. K-08 is that operational alerts do not live in the
// console, because they have to reach a phone when the console is down. The
// place they live instead is Google's alerting, and the thing it filters on is
// `severity`. An alert policy for "the server logged an error" could not have
// been written at all, and nobody would have discovered that until the first
// night it was needed.
//
// It was found by reading a log for something else entirely — which is the
// only way a defect like this is ever found, and the reason it is worth
// writing down.
//
// # WHAT IS DELIBERATELY LEFT ALONE
//
// `time`. Cloud Logging would read a `timestamp` field, and renaming ours to
// it would move each entry's official time from when the platform received the
// line to when the process wrote it — a difference of milliseconds, bought
// with a new way to be wrong: a timestamp it cannot parse is an entry it
// rejects. The value stays in the payload under `time` either way, so nothing
// is lost.
package logs

import (
	"io"
	"log/slog"
)

// Cloud Logging's names for the two fields it actually reads.
const (
	severityKey = "severity"
	messageKey  = "message"
)

// New builds the logger, writing JSON.
//
// JSON AND NOT TEXT, EVERYWHERE, including on a laptop. A format that differs
// between development and production is a format whose parsing is only ever
// exercised in production.
func New(w io.Writer) *slog.Logger {
	return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{ReplaceAttr: googles}))
}

// googles renames the two keys Cloud Logging looks for.
//
// ONLY AT THE TOP LEVEL. An attribute called `level` inside a group is
// somebody's data — a log line about a course's difficulty, say — and renaming
// it would be this function editing the message it was asked to carry.
func googles(groups []string, a slog.Attr) slog.Attr {
	if len(groups) > 0 {
		return a
	}
	switch a.Key {
	case slog.LevelKey:
		level, ok := a.Value.Any().(slog.Level)
		if !ok {
			// Something replaced the level with a value of its own. Leaving it
			// as it is beats guessing a severity for it.
			return a
		}
		return slog.String(severityKey, severityOf(level))
	case slog.MessageKey:
		return slog.String(messageKey, a.Value.String())
	}
	return a
}

// severityOf translates one vocabulary into the other.
//
// IT COMPARES RATHER THAN MATCHES, because `slog` levels are numbers and a
// caller may log at `LevelWarn + 1`. A switch on the four constants would send
// that to the default branch — which would be the wrong answer for exactly the
// lines somebody bothered to make more urgent.
func severityOf(level slog.Level) string {
	switch {
	case level >= slog.LevelError:
		return "ERROR"
	case level >= slog.LevelWarn:
		return "WARNING"
	case level >= slog.LevelInfo:
		return "INFO"
	default:
		return "DEBUG"
	}
}
