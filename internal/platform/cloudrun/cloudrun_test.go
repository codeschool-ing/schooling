package cloudrun

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

/* Starting a job, against a metadata server and an API that are both pretend.

   WHAT THESE TESTS CAN AND CANNOT SEE. They cannot prove Google accepts the
   call — only a deploy does that, and `infra/scheduler.tf` proves the same URL
   shape works because the scheduler has been starting this job with it. What
   they CAN hold is everything between: that the header Google requires is
   sent, that the region is unqualified before it reaches a hostname, that a
   token is asked for per call rather than remembered, and that the two
   failures a caller must tell apart stay apart. */

// A metadata server that answers the three reads, and counts them.
type fakeMetadata struct {
	project string
	region  string
	token   string

	tokens   int
	flavour  bool
	unmarked int
}

func (f *fakeMetadata) handler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The header Google requires. A request without it gets a 403 there,
		// so it gets one here — a test that answered anyway would pass for a
		// client that would fail in production.
		if r.Header.Get("Metadata-Flavor") != "Google" {
			f.unmarked++
			w.WriteHeader(http.StatusForbidden)
			return
		}
		f.flavour = true

		switch r.URL.Path {
		case "/computeMetadata/v1/project/project-id":
			_, _ = w.Write([]byte(f.project))
		case "/computeMetadata/v1/instance/region":
			_, _ = w.Write([]byte(f.region))
		case "/computeMetadata/v1/instance/service-accounts/default/token":
			f.tokens++
			_, _ = w.Write([]byte(`{"access_token":"` + f.token + `","expires_in":3599}`))
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	})
}

func onCloudRun(t *testing.T) (*Runner, *fakeMetadata) {
	t.Helper()

	fake := &fakeMetadata{
		project: "schooling-prod",
		region:  "projects/123456789/regions/southamerica-east1",
		token:   "a-token-for-this-instance",
	}
	server := httptest.NewServer(fake.handler())
	t.Cleanup(server.Close)

	runner, err := here(context.Background(), server.URL)
	if err != nil {
		t.Fatalf("working out where this is running: %v", err)
	}
	return runner, fake
}

// A MACHINE THAT IS NOT CLOUD RUN IS THE ORDINARY CASE, not a failure to
// report. Every developer machine, every CI runner and the local stack are in
// this state, and the caller's job is to say the capability is absent.
func TestOffCloudRunItSaysSoRatherThanFailing(t *testing.T) {
	// A server that is closed: the connection is refused at once, which is what
	// an unresolvable metadata host amounts to.
	server := httptest.NewServer(http.NotFoundHandler())
	closed := server.URL
	server.Close()

	if _, err := here(context.Background(), closed); !errors.Is(err, ErrNotOnCloudRun) {
		t.Errorf("a machine with no metadata server answered %v, and the caller cannot tell "+
			"that from an outage", err)
	}
}

// THE REGION ARRIVES QUALIFIED AND A HOSTNAME CANNOT USE IT THAT WAY. This is
// the one piece of parsing in the package, and getting it wrong produces a DNS
// failure with nothing in it to explain itself.
func TestTheRegionIsUnqualifiedBeforeItReachesAHostname(t *testing.T) {
	runner, _ := onCloudRun(t)

	project, region := runner.Where()
	if project != "schooling-prod" {
		t.Errorf("the project is %q", project)
	}
	if region != "southamerica-east1" {
		t.Errorf("the region is %q — `projects/…/regions/…` in a hostname is a DNS failure "+
			"that names none of its causes", region)
	}
	if want := "https://southamerica-east1-run.googleapis.com"; runner.admin != want {
		t.Errorf("the admin host is %q, want %q", runner.admin, want)
	}
}

// THE WHOLE CALL, READ OFF THE WIRE. The path is the one `infra/scheduler.tf`
// assembles, because two ways to start one job would be two ways to be wrong
// about one of them.
func TestStartingAJobAsksForTheRunTheSchedulerAsksFor(t *testing.T) {
	runner, fake := onCloudRun(t)

	var got *http.Request
	admin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got = r
		_, _ = w.Write([]byte(`{"metadata":{"name":"schooling-analyse-abcde"}}`))
	}))
	defer admin.Close()
	runner.admin = admin.URL

	if err := runner.Start(context.Background(), "schooling-analyse"); err != nil {
		t.Fatalf("starting a job: %v", err)
	}

	if got == nil {
		t.Fatal("nothing was asked of the API")
	}
	if got.Method != http.MethodPost {
		t.Errorf("the run was asked for with %s", got.Method)
	}
	want := "/apis/run.googleapis.com/v1/namespaces/schooling-prod/jobs/schooling-analyse:run"
	if got.URL.Path != want {
		t.Errorf("it asked for %q, want %q", got.URL.Path, want)
	}
	if auth := got.Header.Get("Authorization"); auth != "Bearer a-token-for-this-instance" {
		t.Errorf("the call carried %q — an unauthenticated start is a 401 nobody can act on", auth)
	}

	if !fake.flavour {
		t.Error("the metadata reads went out without `Metadata-Flavor: Google`")
	}
	if fake.unmarked > 0 {
		t.Errorf("%d metadata request(s) omitted the header Google requires", fake.unmarked)
	}
	if fake.tokens != 1 {
		t.Errorf("%d token(s) were fetched for one call", fake.tokens)
	}
}

// A TOKEN PER CALL, DELIBERATELY. The cache is the obvious optimisation and it
// buys nothing here — this is pressed by a person a few times a day — while
// adding the one bug that is invisible until the hour it matters.
func TestATokenIsFetchedForEveryCallRatherThanRemembered(t *testing.T) {
	runner, fake := onCloudRun(t)

	admin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{}`))
	}))
	defer admin.Close()
	runner.admin = admin.URL

	for i := 0; i < 3; i++ {
		if err := runner.Start(context.Background(), "schooling-analyse"); err != nil {
			t.Fatalf("starting a job: %v", err)
		}
	}
	if fake.tokens != 3 {
		t.Errorf("three calls fetched %d token(s) — a cached one is a call refused at three "+
			"in the morning with nothing on the screen to say why", fake.tokens)
	}
}

// A NAME NOBODY HAS A JOB FOR IS A DIFFERENT MISTAKE FROM AN OUTAGE. One is a
// typo in a list somebody wrote and the other is Google being unwell, and a
// caller that could not tell them apart would report both the same way.
func TestAJobThatDoesNotExistIsNotAnOutage(t *testing.T) {
	runner, _ := onCloudRun(t)

	admin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		_, _ = w.Write([]byte(`{"error":{"message":"job not found"}}`))
	}))
	defer admin.Close()
	runner.admin = admin.URL

	err := runner.Start(context.Background(), "schooling-analyse")
	if !errors.Is(err, ErrNoSuchJob) {
		t.Errorf("a job Google does not have answered %v", err)
	}
}

// WHAT GOOGLE SAID IS IN THE ERROR. A missing permission, an API that is not
// enabled and a job with no image all arrive as one status code, and a bare
// code turns every one of them into the same half-hour.
func TestARefusalCarriesWhatGoogleSaidAboutIt(t *testing.T) {
	runner, _ := onCloudRun(t)

	admin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte(`{"error":{"message":"run.jobs.run denied on schooling-analyse"}}`))
	}))
	defer admin.Close()
	runner.admin = admin.URL

	err := runner.Start(context.Background(), "schooling-analyse")
	if err == nil {
		t.Fatal("a refusal came back as a successful start")
	}
	if errors.Is(err, ErrNoSuchJob) {
		t.Error("a permission failure was reported as a missing job")
	}
	if !strings.Contains(err.Error(), "run.jobs.run denied") {
		t.Errorf("what Google said is not in the error: %v", err)
	}
}
