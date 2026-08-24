/*
Package cloudrun starts a Cloud Run job from inside a Cloud Run service.

# IT IS MECHANISM AND HOLDS NO OPINION ABOUT WHICH JOB

That is why it is in `platform`. This package knows how to ask Google to run a
job by name; WHICH names may be asked for is a product decision and lives where
the product is wired. A package that carried the list would be a package that
has to be edited to add a job, which is the shape of a dependency pointing the
wrong way.

# NOTHING IS CONFIGURED, AND THAT IS THE POINT

A process on Cloud Run already knows its project and its region: the metadata
server answers both, and it answers for the instance actually running rather
than for whatever a deploy wrote into an environment variable last. Two of the
three things this needs would otherwise be a second copy of a fact — and the
copy is what goes stale when a service is moved to another region and the
variable is not.

The third is the token, and it cannot be configured at all: it is minted for
this instance's own service account, expires in an hour, and never leaves the
machine.

# IT FETCHES A TOKEN PER CALL

A cache with an expiry is the obvious optimisation and the wrong trade here.
This is pressed by a person looking at a screen, a handful of times a day at
most; the alternative buys nothing measurable and adds the one bug class that
is invisible until the hour it matters — a token believed fresh, a call refused
at three in the morning, and nothing on the screen that says why.

# NOT BEING ON CLOUD RUN IS AN ANSWER AND NOT A FAILURE

Every developer machine and every CI runner is in that state, and so is the
local stack. `Here` says so with `ErrNotOnCloudRun`, and what the caller must
do with it is report the capability as ABSENT rather than offer it and fail:
a button that cannot work is worse than no button, which is the argument the
console's jobs screen has been making since before there was a button to argue
about.

# WHY THE URL LOOKS LEGACY

Cloud Scheduler starts a job by calling `apis/run.googleapis.com/v1/namespaces/
<project>/jobs/<name>:run` on the regional host, and so does this — the same
path `infra/scheduler.tf` assembles, for the same reason it gives: the v2
surface exists and the v1 namespaces form is the one this integration is tested
against. Two ways to start one job would be two ways to be wrong about one of
them.
*/
package cloudrun

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// ErrNotOnCloudRun is a process with no metadata server: a laptop, a CI runner,
// the local stack. It is a state to report, not an error to log.
var ErrNotOnCloudRun = errors.New("cloudrun: no metadata server — this is not running on Cloud Run")

// ErrNoSuchJob is a name Google does not have a job for. It is separate from a
// call that failed, because the two are different mistakes: one is a typo in a
// list somebody wrote and the other is an outage.
var ErrNoSuchJob = errors.New("cloudrun: there is no job with that name in this project")

// The metadata server, which is a fixed address on every Google compute
// surface. It is a constant rather than a setting for the reason the whole
// package exists: a configurable address for "where am I" is a way to be told
// the wrong answer.
const metadataBase = "http://metadata.google.internal"

/*
HOW LONG TO WAIT BEFORE DECIDING THIS IS NOT CLOUD RUN.

	Off Google the name usually does not resolve and the answer is immediate. In
	a network that black-holes it instead, an unbounded probe would hang the
	thing that called it — and this is called while a server is starting up, so
	it would hang the deploy rather than a request. Two seconds is long past
	generous for a link-local answer.
*/
const probeTimeout = 2 * time.Second

// Runner is one process's own place: which project and region it is in, and a
// client that can ask Google to start something there.
type Runner struct {
	project string
	region  string

	client   *http.Client
	metadata string
	admin    string
}

// Here answers where this process is running, or ErrNotOnCloudRun.
//
// IT IS CALLED ONCE, AT START-UP, and the answer is wired into whatever needs
// it. Asking per request would put a link-local round trip in front of a
// person pressing a button, to re-learn a fact that cannot change while a
// process is alive.
func Here(ctx context.Context) (*Runner, error) { return here(ctx, metadataBase) }

func here(ctx context.Context, base string) (*Runner, error) {
	r := &Runner{
		client:   &http.Client{Timeout: 10 * time.Second},
		metadata: base,
	}

	ctx, cancel := context.WithTimeout(ctx, probeTimeout)
	defer cancel()

	project, err := r.metadataValue(ctx, "/computeMetadata/v1/project/project-id")
	if err != nil {
		return nil, err
	}

	/* THE REGION COMES BACK QUALIFIED — `projects/123456789/regions/sa-east-1`
	   — and the last segment is the part every URL wants. Splitting rather than
	   asking for a shorter field: there is no shorter field, and a caller that
	   pasted the whole string into a hostname would get a DNS failure with
	   nothing in it to explain itself. */
	region, err := r.metadataValue(ctx, "/computeMetadata/v1/instance/region")
	if err != nil {
		return nil, err
	}
	if i := strings.LastIndex(region, "/"); i >= 0 {
		region = region[i+1:]
	}
	if project == "" || region == "" {
		return nil, fmt.Errorf("%w: the metadata server answered with an empty project or region",
			ErrNotOnCloudRun)
	}

	r.project, r.region = project, region
	r.admin = "https://" + region + "-run.googleapis.com"
	return r, nil
}

// Where this process is, for a log line at start-up. A service that thinks it
// is in the wrong region will fail every call with a 404, and the one place
// that can say otherwise is the line it wrote when it worked out where it was.
func (r *Runner) Where() (project, region string) { return r.project, r.region }

// Start asks for one execution of a job, and returns as soon as Google has
// accepted the request.
//
// IT DOES NOT WAIT FOR THE RUN. The call creates an execution and answers; the
// work then takes as long as it takes, in a container this process has no
// handle on. A caller that wanted "did it succeed" is asking a question only
// the run's own row can answer, minutes later — which is exactly what
// `job_runs` is for, and why this returns nothing but whether the ASKING
// worked.
func (r *Runner) Start(ctx context.Context, job string) error {
	token, err := r.token(ctx)
	if err != nil {
		return err
	}

	url := r.admin + "/apis/run.googleapis.com/v1/namespaces/" + r.project +
		"/jobs/" + job + ":run"

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, nil)
	if err != nil {
		return fmt.Errorf("cloudrun: building the request to start %q: %w", job, err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	res, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("cloudrun: asking for a run of %q: %w", job, err)
	}
	defer res.Body.Close()

	if res.StatusCode == http.StatusNotFound {
		return fmt.Errorf("%w: %q", ErrNoSuchJob, job)
	}
	if res.StatusCode < 200 || res.StatusCode > 299 {
		/* THE BODY IS IN THE ERROR, TRIMMED. Google says why in it — a missing
		   permission, a job with no image, a project with the API disabled —
		   and a bare status code turns every one of those into the same
		   half-hour. It is bounded because an error is a log line and a log
		   line is not a place to put a page of JSON. */
		return fmt.Errorf("cloudrun: asking for a run of %q: %s: %s",
			job, res.Status, said(res.Body))
	}
	return nil
}

// token is this instance's own, minted by the metadata server for the service
// account the revision runs as. There is nothing to configure and nothing to
// rotate: it is issued for this call and expires without anybody's help.
func (r *Runner) token(ctx context.Context) (string, error) {
	body, err := r.metadataValue(ctx,
		"/computeMetadata/v1/instance/service-accounts/default/token")
	if err != nil {
		return "", err
	}

	var answer struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.Unmarshal([]byte(body), &answer); err != nil {
		return "", fmt.Errorf("cloudrun: reading the token from the metadata server: %w", err)
	}
	if answer.AccessToken == "" {
		return "", errors.New("cloudrun: the metadata server returned no access token")
	}
	return answer.AccessToken, nil
}

// metadataValue asks the metadata server one thing.
//
// THE HEADER IS WHAT MAKES IT A REQUEST AND NOT AN ACCIDENT. Google requires
// `Metadata-Flavor: Google` on every read precisely so that a server tricked
// into fetching a URL cannot fetch this one — a browser and a naive proxy will
// not send it. Omitting it does not fail obscurely; it fails with a 403.
func (r *Runner) metadataValue(ctx context.Context, path string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.metadata+path, nil)
	if err != nil {
		return "", fmt.Errorf("cloudrun: building a metadata request: %w", err)
	}
	req.Header.Set("Metadata-Flavor", "Google")

	res, err := r.client.Do(req)
	if err != nil {
		// Unreachable is the ordinary case off Google and is not worth a
		// distinct error type: what the caller does about it is the same.
		return "", fmt.Errorf("%w: %v", ErrNotOnCloudRun, err)
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("%w: the metadata server answered %s for %s",
			ErrNotOnCloudRun, res.Status, path)
	}

	value, err := io.ReadAll(io.LimitReader(res.Body, 8<<10))
	if err != nil {
		return "", fmt.Errorf("cloudrun: reading %s from the metadata server: %w", path, err)
	}
	return strings.TrimSpace(string(value)), nil
}

// said is as much of a failure body as belongs in an error.
func said(body io.Reader) string {
	text, err := io.ReadAll(io.LimitReader(body, 2<<10))
	if err != nil {
		return "(the body could not be read)"
	}
	return strings.TrimSpace(string(text))
}
