package identity

import (
	"encoding/base32"
	"strings"
	"time"
)

// CodeFor is the code belonging to the step containing `at`. It exists only
// while the tests are compiled.
//
// WHY THIS IS NOT CIRCULAR. It is the same `hotp` the tests exercise, so it
// could not prove TOTP correct — and it does not: TestTOTPMatchesTheRFCVectors
// does that, against the published vectors, with no help from here. Once the
// implementation is proved against the specification, using it to produce a
// code for a test about a staff door is arithmetic rather than an assumption.
//
// It replaces a helper that searched all million six-digit codes. That was
// honest and cost 76 seconds under -race, which is a suite people stop running.
func CodeFor(secret string, at time.Time) string {
	key, err := base32.StdEncoding.WithPadding(base32.NoPadding).
		DecodeString(strings.ToUpper(strings.ReplaceAll(secret, " ", "")))
	if err != nil {
		return ""
	}
	seconds := at.Unix()
	if seconds < 0 {
		return ""
	}
	return hotp(key, uint64(seconds)/uint64(totpPeriod.Seconds()))
}
