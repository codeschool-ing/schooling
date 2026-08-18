package identity_test

import (
	"encoding/base32"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/identity"
)

// THE REASON TOTP IS WRITTEN OUT RATHER THAN IMPORTED.
//
// RFC 6238 publishes test vectors, so a hand-written implementation can be
// PROVED against the specification — which is a stronger position than trusting
// a dependency nobody here has read. These are Appendix B, the SHA-1 rows, with
// the seed "12345678901234567890".
//
// The RFC's vectors are eight digits; this system uses six, which is what
// authenticator apps show — so the expectation is the last six of each.
func TestTOTPMatchesTheRFCVectors(t *testing.T) {
	seed := base32.StdEncoding.WithPadding(base32.NoPadding).
		EncodeToString([]byte("12345678901234567890"))

	for _, c := range []struct {
		seconds int64
		eight   string // as printed in RFC 6238 Appendix B
	}{
		{59, "94287082"},
		{1111111109, "07081804"},
		{1111111111, "14050471"},
		{1234567890, "89005924"},
		{2000000000, "69279037"},
		{20000000000, "65353130"},
	} {
		at := time.Unix(c.seconds, 0).UTC()
		want := c.eight[len(c.eight)-6:]

		if err := identity.VerifyTOTP(seed, want, at); err != nil {
			t.Errorf("at %d the RFC says %s (last six: %s) and this rejected it: %v",
				c.seconds, c.eight, want, err)
		}
	}
}

// A code from the wrong moment is refused — which is the whole point of the
// factor being time-based, and the thing an off-by-one in the counter breaks
// silently while the happy path still passes.
func TestACodeFromAnotherMomentIsRefused(t *testing.T) {
	seed := base32.StdEncoding.WithPadding(base32.NoPadding).
		EncodeToString([]byte("12345678901234567890"))

	// 59s and 1111111109s are far apart; each other's codes must not work.
	early := time.Unix(59, 0).UTC()
	late := time.Unix(1111111109, 0).UTC()

	if err := identity.VerifyTOTP(seed, "287082", late); !errors.Is(err, identity.ErrWrongCode) {
		t.Errorf("a code from 1970 was accepted in 2005: %v", err)
	}
	if err := identity.VerifyTOTP(seed, "081804", early); !errors.Is(err, identity.ErrWrongCode) {
		t.Errorf("a code from 2005 was accepted in 1970: %v", err)
	}
}

// One step either side, and no more. Widening this is the change that looks
// harmless and multiplies the guessing window.
func TestTheAcceptedWindowIsOneStepEitherSide(t *testing.T) {
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	now := time.Unix(1_700_000_000, 0).UTC()

	// The code for `now`, obtained the only way a test legitimately can: by
	// asking which of the codes around now this accepts.
	code := codeAt(t, secret, now)

	for _, offset := range []time.Duration{-totpStep, 0, totpStep} {
		if err := identity.VerifyTOTP(secret, code, now.Add(offset)); err != nil {
			t.Errorf("the code was refused %v away from its own step: %v", offset, err)
		}
	}
	for _, offset := range []time.Duration{-3 * totpStep, 3 * totpStep} {
		if err := identity.VerifyTOTP(secret, code, now.Add(offset)); !errors.Is(err, identity.ErrWrongCode) {
			t.Errorf("the code was accepted %v away from its own step, which widens the "+
				"guessing window: %v", offset, err)
		}
	}
}

func TestSomethingThatIsNotACodeIsRefused(t *testing.T) {
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	now := time.Now()

	for _, code := range []string{"", "12345", "1234567", "abcdef", "      "} {
		if err := identity.VerifyTOTP(secret, code, now); !errors.Is(err, identity.ErrWrongCode) {
			t.Errorf("%q was not refused as a code: %v", code, err)
		}
	}
}

// The URI an authenticator app scans. Getting it wrong produces an entry called
// "unknown" in somebody's app, which they cannot tell from the four others.
func TestTheProvisioningURICarriesWhatAnAppNeeds(t *testing.T) {
	uri := identity.TOTPURI("ABCDEFGHIJKLMNOP", "schooling", "ana@example.tld")

	for _, want := range []string{
		"otpauth://totp/",
		"schooling:ana@example.tld", // the label names the issuer, separated by a literal colon
		"secret=ABCDEFGHIJKLMNOP",
		"issuer=schooling",
		"algorithm=SHA1",
		"digits=6",
		"period=30",
	} {
		if !strings.Contains(uri, want) {
			t.Errorf("the provisioning URI is missing %q:\n  %s", want, uri)
		}
	}

	// A colon inside either half would make "which part is the issuer" a guess,
	// so it is escaped while the separator stays literal. An address with a
	// colon in it is legal in the format and rare in life, which is exactly the
	// kind of input that is never tried by hand.
	odd := identity.TOTPURI("ABCDEF", "schooling", "a:b@example.tld")
	if strings.Count(odd[len("otpauth://totp/"):strings.Index(odd, "?")], ":") != 1 {
		t.Errorf("the label has more than one separator, so an app cannot tell the issuer "+
			"from the account: %s", odd)
	}
}

// codeAt is the code belonging to the step containing `at`.
//
// It used to search all million six-digit codes, which was honest and cost 76
// seconds under -race — a suite people stop running, which is worse than the
// small circularity of using the implementation. What removes the circularity
// is that TestTOTPMatchesTheRFCVectors proves the implementation against the
// published vectors with no help from here; after that, generating a code for a
// test about a staff door is arithmetic.
func codeAt(t *testing.T, secret string, at time.Time) string {
	t.Helper()
	code := identity.CodeFor(secret, at)
	if code == "" {
		t.Fatalf("no code for %v — the secret is unreadable", at)
	}
	return code
}

// The step, repeated here because the package's own constant is unexported and
// a test that reached for it would be asserting against its own subject.
const totpStep = 30 * time.Second
