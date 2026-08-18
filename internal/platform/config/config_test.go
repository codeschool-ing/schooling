package config_test

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/config"
)

// A good environment loads, and the port defaults because the platform sets it.
func TestAWholeEnvironmentLoads(t *testing.T) {
	t.Setenv("SCHOOLING_DATABASE_URL", "postgres://user:pass@localhost:5432/schooling")
	t.Setenv("SCHOOLING_PLATFORM_DOMAIN", "Example.TLD")
	t.Setenv("SCHOOLING_ENV", "development")
	t.Setenv("PORT", "")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("a complete environment did not load: %v", err)
	}
	if cfg.Port != "8080" {
		t.Errorf("Port = %q, want the default 8080", cfg.Port)
	}
	// The domain is folded, because a host name is case-insensitive and it is
	// compared against what a browser sent.
	if cfg.PlatformDomain != "example.tld" {
		t.Errorf("PlatformDomain = %q, want it lowercased", cfg.PlatformDomain)
	}
}

// THE ONE THIS PACKAGE EXISTS FOR.
//
// A misconfigured deploy must teach everything that is wrong in one look.
// Failing on the first missing variable turns it into a sequence of restarts,
// each costing a build and a rollout to learn a single fact — and each one
// looking, from outside, exactly like the last.
func TestEveryProblemIsReportedTogether(t *testing.T) {
	t.Setenv("SCHOOLING_DATABASE_URL", "")
	t.Setenv("SCHOOLING_PLATFORM_DOMAIN", "https://example.tld/")
	t.Setenv("SCHOOLING_ENV", "staging")

	_, err := config.Load()
	if err == nil {
		t.Fatal("an environment with three problems in it loaded")
	}

	report := err.Error()
	for _, want := range []string{
		"SCHOOLING_DATABASE_URL",
		"SCHOOLING_PLATFORM_DOMAIN",
		"SCHOOLING_ENV",
	} {
		if !strings.Contains(report, want) {
			t.Errorf("the report does not mention %s — it says only:\n%s", want, report)
		}
	}
}

func TestTheDomainIsAHostAndNotAURL(t *testing.T) {
	for _, bad := range []string{"https://example.tld", "example.tld/", "example.tld:8080"} {
		t.Setenv("SCHOOLING_DATABASE_URL", "postgres://localhost/x")
		t.Setenv("SCHOOLING_ENV", "development")
		t.Setenv("SCHOOLING_PLATFORM_DOMAIN", bad)

		if _, err := config.Load(); err == nil {
			t.Errorf("SCHOOLING_PLATFORM_DOMAIN=%q was accepted — it is a host, not a URL", bad)
		}
	}
}
