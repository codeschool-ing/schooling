// Package config reads the environment and refuses to start on a bad one.
//
// IT COLLECTS EVERY PROBLEM AND REPORTS THEM TOGETHER, which is the whole
// reason this is a package rather than a handful of os.Getenv calls at the top
// of main. Failing on the first missing variable turns a misconfigured deploy
// into a sequence of restarts, each teaching one fact — and each costing a
// round trip through a build and a rollout. One look at the log should tell
// you everything that is wrong.
//
// NOTHING HERE HAS A SILENT DEFAULT THAT MATTERS. A port may default, because
// the platform supplies one and a wrong guess fails loudly at bind. A database
// address may not, because a default would be somebody's laptop.
package config

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

// Environment is which of the two worlds this process is in. It is not
// decoration: production refuses things development is allowed to do.
type Environment string

const (
	Development Environment = "development"
	Production  Environment = "production"
)

type Config struct {
	// DatabaseURL is the whole connection string, secret included. It comes
	// from the secret manager in production and from the compose file locally.
	DatabaseURL string

	// Port is what the process listens on. The platform sets PORT and expects
	// the container to obey it, so this one is not prefixed like the others.
	Port string

	/* PlatformDomain is the ONE PLACE the domain appears.

	   It exists so that changing it is a variable and a DNS record rather than
	   a search through the code. The name is not settled — every document
	   writes addresses as example.tld for that reason — and this is what keeps
	   that decision from blocking anything: a school is resolved from the Host
	   the browser used, and this value is only what the platform's own
	   addresses are built from. */
	PlatformDomain string

	/* MailKey is the provider's credential, and it is the ONE VARIABLE HERE
	   THAT IS ALLOWED TO BE EMPTY WITHOUT BEING A PROBLEM.

	   Every laptop, every test run and CI has no mail account, and refusing to
	   start without one would make "run the platform locally" mean "get a key
	   first". Empty wires `mail.Outbox`, which keeps what it would have sent
	   instead of dropping it, and `cmd/api` logs which of the two it chose —
	   so "no mail arrived" is answered by the start-up line rather than by an
	   investigation.

	   IT IS NOT FATAL IN PRODUCTION EITHER, and that is a deliberate ordering of
	   two harms. A missing key stops addresses being confirmed, which gates
	   nothing; refusing to start would take the lessons down with it. So
	   production starts, and `cmd/api` says loudly at start-up that it is
	   keeping mail rather than sending it. */
	MailKey string

	// MailFrom is the address every message leaves from, name included, as
	// `Schooling <schooling@example.tld>`. It is configuration because SPF and
	// DKIM are published for one domain and this repository holds no domain
	// names.
	MailFrom string

	// MailReplyTo is where an answer goes, and it is a different address on
	// purpose: the sending domain has no MX, so a reply to the From bounces.
	// Empty sends no Reply-To at all, which is at least true.
	MailReplyTo string

	Environment Environment
}

// Load reads the environment. The error, when there is one, names every
// problem rather than the first.
func Load() (Config, error) {
	var problems []error

	cfg := Config{
		DatabaseURL:    os.Getenv("SCHOOLING_DATABASE_URL"),
		Port:           os.Getenv("PORT"),
		PlatformDomain: strings.ToLower(strings.TrimSpace(os.Getenv("SCHOOLING_PLATFORM_DOMAIN"))),
		MailKey:        strings.TrimSpace(os.Getenv("SCHOOLING_MAIL_API_KEY")),
		MailFrom:       strings.TrimSpace(os.Getenv("SCHOOLING_MAIL_FROM")),
		MailReplyTo:    strings.TrimSpace(os.Getenv("SCHOOLING_MAIL_REPLY_TO")),
		Environment:    Environment(os.Getenv("SCHOOLING_ENV")),
	}

	if cfg.DatabaseURL == "" {
		problems = append(problems, errors.New("SCHOOLING_DATABASE_URL is empty — there is no sensible default for a database address"))
	}

	if cfg.Port == "" {
		cfg.Port = "8080"
	}

	if cfg.PlatformDomain == "" {
		problems = append(problems, errors.New("SCHOOLING_PLATFORM_DOMAIN is empty — the platform's own addresses are built from it"))
	} else if strings.Contains(cfg.PlatformDomain, "/") || strings.Contains(cfg.PlatformDomain, ":") {
		problems = append(problems, fmt.Errorf("SCHOOLING_PLATFORM_DOMAIN is %q — it is a host, not a URL and not a host:port", cfg.PlatformDomain))
	}

	/* A KEY WITHOUT AN ADDRESS TO SEND FROM IS THE ONE COMBINATION THAT FAILS
	   AT THE PROVIDER RATHER THAN HERE, hours later, on somebody's sign-up. The
	   two travel together: either this deployment sends mail or it keeps it. */
	if cfg.MailKey != "" && cfg.MailFrom == "" {
		problems = append(problems, errors.New(
			"SCHOOLING_MAIL_API_KEY is set and SCHOOLING_MAIL_FROM is empty — a provider "+
				"refuses a message with no sender, and it refuses it at the first sign-up "+
				"rather than at start-up"))
	}
	if cfg.MailFrom != "" && !strings.Contains(cfg.MailFrom, "@") {
		problems = append(problems, fmt.Errorf(
			"SCHOOLING_MAIL_FROM is %q — it has to carry an address, as `Name <box@domain>` "+
				"or as the address alone", cfg.MailFrom))
	}
	if cfg.MailReplyTo != "" && !strings.Contains(cfg.MailReplyTo, "@") {
		problems = append(problems, fmt.Errorf(
			"SCHOOLING_MAIL_REPLY_TO is %q — it has to carry an address", cfg.MailReplyTo))
	}

	switch cfg.Environment {
	case Development, Production:
	case "":
		problems = append(problems, fmt.Errorf("SCHOOLING_ENV is empty — it has to say %q or %q, because production refuses things development allows", Development, Production))
	default:
		problems = append(problems, fmt.Errorf("SCHOOLING_ENV is %q — it has to say %q or %q", cfg.Environment, Development, Production))
	}

	if len(problems) > 0 {
		return Config{}, errors.Join(problems...)
	}
	return cfg, nil
}
