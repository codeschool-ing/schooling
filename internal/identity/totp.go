package identity

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1" //nolint:gosec // RFC 6238's default and what every authenticator app speaks; see below
	"crypto/subtle"
	"encoding/base32"
	"encoding/binary"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"
)

// The second factor, RFC 6238, implemented here rather than imported.
//
// WHY WRITTEN OUT. It is HMAC over a counter and a truncation, and the RFC
// publishes test vectors for it — so a hand-written version can be PROVED
// correct against the specification, which is a stronger position than trusting
// a dependency nobody in this project has read. The test below is those
// vectors, and it is the reason this is defensible.
//
// SHA-1 IS THE RIGHT CHOICE HERE and the linter is right to ask. TOTP's
// security comes from the shared secret and the six-digit window, not from
// collision resistance of the hash — and every authenticator app a person
// already has installed speaks HMAC-SHA1. Choosing SHA-256 would mean a second
// factor that half the apps enrol wrongly, which is a real failure traded for
// an imaginary one.

const (
	totpDigits = 6
	totpPeriod = 30 * time.Second

	// How far either side of now a code is accepted. One step, which is the
	// usual compromise: it covers a clock a little out and a person typing
	// slowly, and it widens the guessing window from one in a million to three.
	totpSkew uint64 = 1
)

// ErrWrongCode is a second factor that does not match. Like ErrWrongPassword,
// it says nothing about why.
var ErrWrongCode = errors.New("identity: that code is not right")

// NewTOTPSecret makes a secret for a new enrolment. 20 bytes is RFC 4226's
// recommendation and what authenticator apps expect.
func NewTOTPSecret() (string, error) {
	raw := make([]byte, 20)
	if _, err := rand.Read(raw); err != nil {
		return "", fmt.Errorf("identity: no randomness for a second factor: %w", err)
	}
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(raw), nil
}

// TOTPURI is what goes into the QR code an authenticator app scans.
//
// The issuer appears twice — as a prefix on the label and as a parameter —
// because that is what the de-facto specification says and what apps actually
// read. Getting it wrong produces an entry called "unknown" in somebody's app,
// which they cannot tell apart from the four others.
func TOTPURI(secret, issuer, account string) string {
	// The separator colon stays literal — that is what the key URI format says
	// and what apps split on. A colon INSIDE either half is escaped, because
	// two of them in a label makes "which part is the issuer" a guess.
	label := escapeLabel(issuer) + ":" + escapeLabel(account)
	q := url.Values{
		"secret": {secret},
		"issuer": {issuer},
		"digits": {fmt.Sprint(totpDigits)},
		"period": {fmt.Sprint(int(totpPeriod.Seconds()))},
		// Named explicitly rather than left to the app's default, because the
		// default is not written down anywhere binding.
		"algorithm": {"SHA1"},
	}
	return "otpauth://totp/" + label + "?" + q.Encode()
}

// VerifyTOTP answers nil when the code matches the secret, at that moment.
func VerifyTOTP(secret, code string, at time.Time) error {
	code = strings.TrimSpace(code)
	if len(code) != totpDigits {
		return ErrWrongCode
	}

	key, err := base32.StdEncoding.WithPadding(base32.NoPadding).
		DecodeString(strings.ToUpper(strings.ReplaceAll(secret, " ", "")))
	if err != nil {
		return fmt.Errorf("identity: the stored second factor is not base32: %w", err)
	}

	seconds := at.Unix()
	if seconds < 0 {
		// The counter is unsigned by definition, so a moment before 1970 has no
		// code rather than a wrapped one.
		return ErrWrongCode
	}
	counter := uint64(seconds) / uint64(totpPeriod.Seconds())

	first := uint64(0)
	if counter > totpSkew {
		first = counter - totpSkew
	}

	// Every candidate is computed and compared even after one matches, so the
	// time taken says nothing about WHICH step matched — which would tell an
	// attacker how far off the clock they are.
	matched := 0
	for c := first; c <= counter+totpSkew; c++ {
		want := hotp(key, c)
		matched |= subtle.ConstantTimeCompare([]byte(want), []byte(code))
	}
	if matched != 1 {
		return ErrWrongCode
	}
	return nil
}

// escapeLabel makes one half of a label safe to put beside a separator colon.
func escapeLabel(s string) string {
	return strings.ReplaceAll(url.PathEscape(s), ":", "%3A")
}

// hotp is RFC 4226: HMAC the counter, take four bytes from an offset the last
// nibble names, and print the low digits.
func hotp(key []byte, counter uint64) string {
	var buf [8]byte
	binary.BigEndian.PutUint64(buf[:], counter)

	mac := hmac.New(sha1.New, key)
	mac.Write(buf[:])
	sum := mac.Sum(nil)

	offset := sum[len(sum)-1] & 0x0f
	truncated := binary.BigEndian.Uint32(sum[offset:offset+4]) & 0x7fffffff

	return fmt.Sprintf("%0*d", totpDigits, truncated%1_000_000)
}
