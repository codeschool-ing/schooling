package console

import (
	"context"
	"net/http"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* What ran on a schedule, and how it went.

   # THE SCREEN THAT SAYS "IT DID NOT RUN"

   Every other read in this console reports on students. This one reports on
   US — on whether the machinery that produces one of the other screens did its
   work last night.

   It exists because the console already had a signal and it was the wrong one.
   The item analysis shows when its rollup was last WRITTEN, which is a good
   number and answers a different question: a job that failed at 03:10, a job
   nobody scheduled and a job that ran perfectly and found nothing to change all
   look identical through it. That last case is the one that makes `computed_at`
   unusable as an alarm — a healthy night can leave it untouched.

   # AND IT IS NOT AN ALERT (K-08)

   Operational alerts do not live here. They have to reach a phone WHEN THE
   CONSOLE IS DOWN, which is exactly when they are needed, and that machinery is
   in `infra/monitoring.tf`. This is the other half: somebody who is already
   looking at a number wants to know whether to trust it. A screen answers that
   and a pager cannot.

   # THERE IS NO RETRY BUTTON, YET

   The roadmap asks for one and it is not here. Starting a job from the console
   means the console holding `run.invoker` and calling Google's API, which is an
   identity and a network path this package has never had — and the value of it
   is smaller than it looks while the answer to a failed night is "it runs again
   in twenty-four hours". What this screen buys is knowing that it failed, which
   nothing did before.
*/

// Run is one attempt as the console shows it.
type Run struct {
	Job     string
	Version string

	StartedAt  time.Time
	FinishedAt *time.Time

	// One of `running`, `ok`, `failed` — the store's own words, passed through
	// rather than translated, so a fourth would appear on the screen as itself
	// instead of being silently folded into one of the three.
	Outcome string
	Detail  string

	// Adrift is a run still saying `running` long after anything could still be
	// running. The store decides it, not the screen: it is a judgement against
	// a threshold, and a threshold belongs beside the number it produced (K-16)
	// rather than copied into an interface.
	Adrift bool
}

// Jobs is what this package may not import: `job` owns the table.
type Jobs struct {
	// Names is every job that has ever recorded a run — read rather than
	// declared, so a job nobody remembered to list still appears.
	Names func(ctx context.Context) ([]string, error)

	// Latest is the most recent runs of one job, newest first.
	Latest func(ctx context.Context, name string, limit int) ([]Run, error)

	// AdriftAfter is how long a run may say `running` before it is believed
	// dead, sent to the screen with the runs so the sentence beside a row and
	// the rule that produced it cannot drift apart.
	AdriftAfter time.Duration
}

// JobsHandler answers what ran. It reads and never writes — there is no retry
// here, so it carries no audit seam and no second rank.
type JobsHandler struct {
	jobs Jobs
}

func NewJobsHandler(jobs Jobs) *JobsHandler { return &JobsHandler{jobs: jobs} }

func (h *JobsHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/jobs", h.list)
}

// howMany runs of each job come back. Enough that a failure and the successes
// around it are on the screen together — "it failed once on Tuesday" and "it
// has failed every night since Tuesday" are different situations and the second
// is the one worth waking up for.
const howMany = 14

func (h *JobsHandler) list(w http.ResponseWriter, r *http.Request) {
	names, err := h.jobs.Names(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading which jobs have run", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(names))
	for _, name := range names {
		runs, err := h.jobs.Latest(r.Context(), name, howMany)
		if err != nil {
			web.LoggerFrom(r.Context()).Error("reading the runs of a job",
				"error", err, "job", name)
			web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
			return
		}

		rows := make([]map[string]any, 0, len(runs))
		for _, one := range runs {
			rows = append(rows, map[string]any{
				"version":     one.Version,
				"started_at":  one.StartedAt,
				"finished_at": one.FinishedAt,
				"outcome":     one.Outcome,
				"detail":      one.Detail,
				"adrift":      one.Adrift,
			})
		}
		out = append(out, map[string]any{"name": name, "runs": rows})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"jobs": out,

		// THE THRESHOLD BESIDE THE NUMBER IT PRODUCED (K-16). `adrift` is a
		// judgement, and a screen showing one without the span it was judged
		// against is a screen that keeps saying the old span after it moves.
		"adrift_after_seconds": int(h.jobs.AdriftAfter / time.Second),

		// WHAT A JOB THAT HAS NEVER RUN LOOKS LIKE, said by the thing that
		// knows. An empty list here is not an error and not an empty database:
		// it is the state a platform is in before its first night, and it was
		// the state this one was in for as long as nothing scheduled anything.
		"nothing_yet": "No job has recorded a run. Before the first night that is what this " +
			"screen says — and it is also what it says if nothing is scheduled at all.",

		// AND WHY THERE IS NO BUTTON, where somebody looking for one will find
		// the reason rather than conclude it was forgotten.
		"no_retry": "There is nothing to press. A failed night runs again on the next one, and " +
			"starting a job from here would mean this console holding the right to run one. " +
			"Alerts do not live here either: they have to reach a phone when the console is " +
			"down, which is when they are needed.",
	})
}
