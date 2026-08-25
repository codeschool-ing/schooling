package logs_test

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/logs"
)

// wrote runs one call and gives back the object that came out.
func wrote(t *testing.T, write func(*slog.Logger)) map[string]any {
	t.Helper()

	var buffer bytes.Buffer
	write(logs.New(&buffer))

	var line map[string]any
	if err := json.Unmarshal(buffer.Bytes(), &line); err != nil {
		t.Fatalf("the log line is not JSON: %v\n%s", err, buffer.String())
	}
	return line
}

/*
THE FIELD CLOUD LOGGING READS IS `severity`, AND WE WERE WRITING `level`.

	Which means every line this platform has ever written was filed with no
	severity at all — a warning and an error indistinguishable from a health
	check, in the viewer and, far worse, in an alert policy.

	K-08 says operational alerts do not live in the console because they have to
	reach a phone when the console is down. The place they live instead filters
	on this field. "Alert me when the server logs an error" was not a policy
	anybody could have written, and the night it was needed is when that would
	have been discovered.
*/
func TestTheSeverityIsTheOneGoogleReads(t *testing.T) {
	for _, c := range []struct {
		name  string
		write func(*slog.Logger)
		want  string
	}{
		{"info", func(l *slog.Logger) { l.Info("x") }, "INFO"},
		{"warn", func(l *slog.Logger) { l.Warn("x") }, "WARNING"},
		{"error", func(l *slog.Logger) { l.Error("x") }, "ERROR"},

		// A level between two of the constants belongs with the more urgent of
		// them, and this is exactly the line somebody deliberately raised.
		{"above error", func(l *slog.Logger) { l.Log(t.Context(), slog.LevelError+4, "x") }, "ERROR"},
		{"between warn and error", func(l *slog.Logger) {
			l.Log(t.Context(), slog.LevelWarn+1, "x")
		}, "WARNING"},
	} {
		t.Run(c.name, func(t *testing.T) {
			line := wrote(t, c.write)

			if got := line["severity"]; got != c.want {
				t.Errorf("severity = %v, want %q", got, c.want)
			}
			if _, ok := line["level"]; ok {
				t.Errorf("the line still carries `level`, which Cloud Logging does not "+
					"read: %v", line)
			}
		})
	}
}

// AND `Debug` WRITES NOTHING, which is why there is no DEBUG row above. The
// handler takes the default threshold and this repository asks for no other:
// a level nothing emits is a knob whose only setting is off (K-13), and the
// translation for it exists in `severityOf` for the day one is asked for.
//
// It is pinned rather than assumed because the alternative reading of an empty
// buffer is a logger that is broken, and those two look identical.
func TestDebugIsBelowTheFloorAndWritesNothing(t *testing.T) {
	var buffer bytes.Buffer
	logs.New(&buffer).Debug("this is not written")

	if buffer.Len() != 0 {
		t.Errorf("something was written at debug level: %s", buffer.String())
	}
}

func TestTheMessageIsTheOneGoogleReads(t *testing.T) {
	line := wrote(t, func(l *slog.Logger) { l.Info("the country database") })

	if got := line["message"]; got != "the country database" {
		t.Errorf("message = %v, want the message", got)
	}
	if _, ok := line["msg"]; ok {
		t.Errorf("the line still carries `msg`: %v", line)
	}
}

// AND THE ATTRIBUTES ARE UNTOUCHED. What a caller passes is data, and this
// function's job is the two keys `slog` itself writes — not editing the
// message it was asked to carry.
func TestWhatTheCallerSaidIsLeftAlone(t *testing.T) {
	line := wrote(t, func(l *slog.Logger) {
		l.Warn("the country of a request cannot be trusted",
			"reason", "the address is not a public one",
			"hops_configured", 1,
			"entries_seen", 2)
	})

	for key, want := range map[string]any{
		"reason":          "the address is not a public one",
		"hops_configured": float64(1),
		"entries_seen":    float64(2),
	} {
		if got := line[key]; got != want {
			t.Errorf("%s = %v, want %v", key, got, want)
		}
	}
}

// A caller's OWN field called `level` is theirs, and renaming it would be this
// package rewriting somebody's data because the name collided.
func TestAnAttributeInsideAGroupKeepsItsName(t *testing.T) {
	line := wrote(t, func(l *slog.Logger) {
		l.Info("a question", slog.Group("item", "level", "hard", "msg", "read this"))
	})

	item, ok := line["item"].(map[string]any)
	if !ok {
		t.Fatalf("the group did not survive: %v", line)
	}
	if item["level"] != "hard" {
		t.Errorf("item.level = %v, want %q", item["level"], "hard")
	}
	if item["msg"] != "read this" {
		t.Errorf("item.msg = %v, want %q", item["msg"], "read this")
	}
}

// The time stays where it is, deliberately: see the package comment.
func TestTheTimeIsStillCalledTime(t *testing.T) {
	line := wrote(t, func(l *slog.Logger) { l.Info("x") })

	if _, ok := line["time"]; !ok {
		t.Errorf("the line lost its time: %v", line)
	}
}
