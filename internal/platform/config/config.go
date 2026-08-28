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

	/* MailHookUser and MailHookPassword are the HTTP Basic credential the
	   provider presents when it posts a delivery event.

	   A DELIVERY EVENT IS NOT SELF-AUTHENTICATING: nothing signs the body, so a
	   shared secret is all there is. An endpoint that marks addresses as refused
	   and is open to the world is a way to stop this platform writing to
	   anybody — post somebody's address and they never get their link.

	   IT USED TO TRAVEL IN THE PATH, on the belief that the provider offered
	   nothing better. It offers Basic. A header is in no request log, no address
	   bar and no screenshot, which is three places the path version was.

	   ONE OF THEM IS A SECRET AND THE OTHER IS NOT, and they are separate for
	   that reason: the user is a name, and lives in `terraform.tfvars` beside
	   the sending addresses. The password comes out of the secret manager.

	   EMPTY MOUNTS NO ENDPOINT AT ALL, which is why neither is fatal: a laptop
	   and CI have no provider to hear from, and the failure of getting this
	   wrong has to be "there is nothing there" rather than "there is something
	   there that anybody may post to". */
	MailHookUser     string
	MailHookPassword string

	/* AsaasKey is what the payment gateway is talked to with.

	   EMPTY MOUNTS NO CHECKOUT AT ALL, which is the same arrangement the mail
	   hook above has and the right failure for the same reason: a deployment
	   with no key must offer nobody a way to pay rather than a button that
	   fails after they have decided to.

	   WHICH HOST IT REACHES IS NOT A SETTING AND IS NOT THIS ONE EITHER. It is
	   read off the key itself — `asaas.HostFor` — because the key is the thing
	   that actually determines the answer: a sandbox key is refused by the live
	   host and the other way round. Following `Environment` was the first
	   version, and its cost was that a production deployment could never reach
	   the sandbox, which would make the first end-to-end run of a payment
	   integration one with real money in it. */
	AsaasKey string

	/* AsaasHookToken is what the gateway presents when it posts an event.

	   A PAYMENT EVENT IS NOT SELF-AUTHENTICATING: nothing signs the body, so
	   this shared token is the whole of what stands between the endpoint and
	   anybody who finds it — and what an open one would buy is worse than the
	   mail hook's, because an event that says a charge was paid opens a
	   subscription nobody paid for.

	   IT IS SEPARATE FROM THE KEY ABOVE and rotates for its own reasons. A
	   deployment may have the key and not this: that is a checkout that takes
	   money and hears nothing back, which is a state worth being able to see. */
	AsaasHookToken string

	/* SupportEmail is where a person writes when only a person will do.

	   IT EXISTS BECAUSE THE TERMS OF USE PROMISE SOMETHING. They give seven
	   days to withdraw from a purchase, unconditionally, for the full amount —
	   which is art. 49 of the Código de Defesa do Consumidor and is not ours to
	   narrow. A promise with nowhere to send it is worse than no promise: the
	   document is evidence, and the person holding the right cannot use it.

	   IT IS CONFIGURED AND NOT A CONSTANT because it is a deployment's fact.
	   `contact@codeschool.ing` belongs to one platform; a lab, a fork and
	   anybody else running this are not it, and an address baked into the code
	   is an address that is wrong everywhere except one place.

	   EMPTY IS ALLOWED AND COSTS SOMETHING. The screen still tells somebody the
	   deadline they are inside — that is worth knowing on its own — and simply
	   has no address to offer them. A deployment whose terms promise the seven
	   days should set this. */
	SupportEmail string

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
		SupportEmail:   strings.ToLower(strings.TrimSpace(os.Getenv("SCHOOLING_SUPPORT_EMAIL"))),
		Environment:    Environment(os.Getenv("SCHOOLING_ENV")),

		MailHookUser:     strings.TrimSpace(os.Getenv("SCHOOLING_MAIL_HOOK_USER")),
		MailHookPassword: strings.TrimSpace(os.Getenv("SCHOOLING_MAIL_HOOK_PASSWORD")),

		AsaasKey:       strings.TrimSpace(os.Getenv("SCHOOLING_ASAAS_KEY")),
		AsaasHookToken: strings.TrimSpace(os.Getenv("SCHOOLING_ASAAS_HOOK_TOKEN")),
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

	/* HALF A CREDENTIAL IS THE ONE STATE THAT CANNOT BE MEANT. Both empty is a
	   deployment with no provider to hear from, which is every laptop and CI.
	   Both set is a deployment that listens. One of each is somebody halfway
	   through configuring it, and mounting nothing while the provider posts —
	   or mounting something with an empty password — are both worse than
	   saying so at start-up. */
	if (cfg.MailHookUser == "") != (cfg.MailHookPassword == "") {
		problems = append(problems, errors.New(
			"SCHOOLING_MAIL_HOOK_USER and SCHOOLING_MAIL_HOOK_PASSWORD travel together — "+
				"one without the other is half a credential, and the delivery hook is "+
				"either listening or it is not"))
	}

	/* A SHORT PASSWORD IS WORSE THAN NONE, because none mounts nothing and a
	   short one mounts an endpoint while looking protected. It is not typed by
	   anybody — it comes out of `openssl rand` — and the floor is here to catch
	   a placeholder somebody meant to replace.

	   The message does NOT quote the value back, for the reason it is a secret. */
	if n := len(cfg.MailHookPassword); n > 0 && n < 32 {
		problems = append(problems, fmt.Errorf(
			"SCHOOLING_MAIL_HOOK_PASSWORD is %d characters — it is the only thing "+
				"standing between the delivery hook and anybody who finds it, so it wants "+
				"at least 32. Generate one rather than choosing one", n))
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
