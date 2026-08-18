package identity

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/argon2"
)

// Password hashing, and the parameters are stored beside every hash rather than
// compiled in.
//
// THE COST OF HASHING GOES UP OVER TIME, and a constant in the code means that
// raising it invalidates every password ever stored — so nobody raises it. The
// encoded form below carries the parameters it was made with, which means a new
// password uses the new cost, an old one still verifies against the old, and
// the two can coexist for as long as it takes people to sign in again.
//
// The format is the PHC string the reference implementation uses, so a hash
// here is readable by anything else that speaks argon2id — this project is not
// inventing an encoding for something that has one.

// The parameters new hashes are made with: OWASP's minimum recommendation for
// argon2id. 19 MiB rather than the 64 MiB often quoted, because every
// concurrent sign-in allocates it and the instances this runs on are small —
// a sign-in that fails on memory is a worse outcome than a cheaper hash.
const (
	hashMemory      = 19 * 1024 // KiB
	hashIterations  = 2
	hashParallelism = 1
	hashSaltLength  = 16
	hashKeyLength   = 32
)

// ErrWrongPassword is what a bad password looks like. It is deliberately the
// same error whether the account exists or not — see Store.Authenticate.
var ErrWrongPassword = errors.New("identity: that is not the password")

func hashPassword(password string) (string, error) {
	salt := make([]byte, hashSaltLength)
	if _, err := rand.Read(salt); err != nil {
		return "", fmt.Errorf("identity: no randomness for a salt: %w", err)
	}

	key := argon2.IDKey([]byte(password), salt,
		hashIterations, hashMemory, hashParallelism, hashKeyLength)

	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version, hashMemory, hashIterations, hashParallelism,
		base64.RawStdEncoding.EncodeToString(salt),
		base64.RawStdEncoding.EncodeToString(key)), nil
}

// verifyPassword answers nil when the password matches the encoded hash.
//
// The comparison is constant-time. Comparing with == leaks how many leading
// bytes were right, one request at a time, to anybody who can measure it.
func verifyPassword(encoded, password string) error {
	memory, iterations, parallelism, salt, want, err := parseHash(encoded)
	if err != nil {
		return err
	}

	//nolint:gosec // parseHash refuses anything outside 16..64 bytes, so this
	// conversion cannot overflow. The guard is three lines up; gosec does not
	// follow it.
	got := argon2.IDKey([]byte(password), salt,
		iterations, memory, parallelism, uint32(len(want)))

	if subtle.ConstantTimeCompare(got, want) != 1 {
		return ErrWrongPassword
	}
	return nil
}

func parseHash(encoded string) (memory uint32, iterations uint32, parallelism uint8,
	salt, key []byte, err error) {

	parts := strings.Split(encoded, "$")
	// "", "argon2id", "v=19", "m=…,t=…,p=…", salt, key
	if len(parts) != 6 || parts[1] != "argon2id" {
		return 0, 0, 0, nil, nil, errors.New("identity: the stored password is not an argon2id hash")
	}

	var version int
	if _, err := fmt.Sscanf(parts[2], "v=%d", &version); err != nil || version != argon2.Version {
		return 0, 0, 0, nil, nil, fmt.Errorf(
			"identity: the stored password was made by argon2 %q, and this build speaks v=%d",
			parts[2], argon2.Version)
	}

	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &memory, &iterations, &parallelism); err != nil {
		return 0, 0, 0, nil, nil, fmt.Errorf("identity: unreadable hash parameters %q", parts[3])
	}

	if salt, err = base64.RawStdEncoding.DecodeString(parts[4]); err != nil {
		return 0, 0, 0, nil, nil, fmt.Errorf("identity: unreadable salt: %w", err)
	}
	if key, err = base64.RawStdEncoding.DecodeString(parts[5]); err != nil {
		return 0, 0, 0, nil, nil, fmt.Errorf("identity: unreadable hash: %w", err)
	}

	// A stored hash outside this range is corrupt, not merely old, and saying
	// so beats deriving a key of that length and comparing it to nothing. It
	// also makes the conversion to uint32 below provably safe rather than
	// probably safe, which is what the linter was asking about.
	if len(key) < 16 || len(key) > 64 {
		return 0, 0, 0, nil, nil, fmt.Errorf(
			"identity: the stored password has a %d-byte hash, which no version of this "+
				"code produced", len(key))
	}

	return memory, iterations, parallelism, salt, key, nil
}
