package console

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

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

   # AND NOW A JOB CAN BE STARTED FROM HERE

   That was the roadmap's open half and the reason it stayed open was real:
   starting a job means this console holding the right to run one, which is an
   identity and a network path it did not have. It has one now — `run.invoker`
   on ONE job rather than on the project, and the call goes out with a token
   the instance mints for itself (`platform/cloudrun`).

   WHAT MAY BE STARTED IS A CLOSED LIST AND NOT A NAME FROM THE REQUEST. The
   handler is given the names it may pass on and refuses everything else before
   Google is asked anything. Without that this route is a general-purpose Cloud
   Run trigger wearing a console's clothes: `schooling-migrate` and
   `schooling-load` are in the same project, and a migration started by
   somebody browsing is not a thing that should be one path parameter away.

   IT REFUSES TO START ONE THAT IS ALREADY RUNNING. Two analyses at once are
   two sweeps, and a sweep WITHDRAWS a question — so the second one writes a
   second audit entry for one withdrawal. The guard is best effort and says so:
   it cannot stop the scheduler firing at 03:10 into a run somebody started at
   03:09. What it stops is the failure that actually happens, which is somebody
   pressing a button twice because nothing appeared to change.

   A run started by hand is NOT distinguishable in `job_runs`, and that is not
   an oversight: the scheduler and this console make the same call, and the job
   has no way to know who asked. Who started one lives in the audit, which is
   the only place it can.
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

	/* Start asks for one more execution of a job.

	   IT IS NIL WHERE NOTHING CAN START A JOB — a laptop, a CI runner, the
	   local stack — and that is a state to REPORT rather than a dependency to
	   fake. A handler wired with a stub that always succeeds would put a button
	   on a screen that does nothing, which is the failure this whole screen
	   exists to make visible one layer down. */
	Start func(ctx context.Context, name string) error

	/* Startable is the closed list, and it is the whole of the safety here.

	   The name in the path is checked against it before anything is asked of
	   Google. Passed through, this route would start `schooling-migrate` as
	   readily as the analysis — same project, same permission, one path
	   parameter apart. A list also lets the screen draw a button only where
	   there is one to press, rather than offering every job and failing on
	   most of them. */
	Startable []string
}

// JobsHandler answers what ran, and starts the one kind of job that may be
// started by hand.
type JobsHandler struct {
	jobs   Jobs
	record Record
	label  Label
	who    func(ctx context.Context) (uuid.UUID, bool)

	// mayStart is the second rank, as the schools and the erase paths have
	// one. Reading what ran last night is what a read-only role is for;
	// spending money and withdrawing questions is not.
	mayStart func(ctx context.Context) bool
}

func NewJobsHandler(jobs Jobs, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	mayStart func(ctx context.Context) bool,
) *JobsHandler {
	return &JobsHandler{jobs: jobs, record: record, label: label, who: who, mayStart: mayStart}
}

func (h *JobsHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/jobs", h.list)
	mux.HandleFunc("POST /console/api/v1/jobs/{job}/run", h.start)
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

		/* WHICH JOBS MAY BE STARTED, SENT RATHER THAN KNOWN. The same rule the
		   verdicts and the reasons follow: a screen holding its own copy keeps
		   offering yesterday's list, and the name it then sends is refused.

		   It is empty where nothing can start a job at all, and the screen
		   draws no button — which is the honest state on a laptop and in CI. */
		"startable": h.startable(),

		// AND WHAT A BUTTON IS AND IS NOT FOR, where somebody looking at one
		// will find it. Alerts still do not live here (K-08): they have to
		// reach a phone when the console is down, which is when they matter.
		"about_starting": "Starting one asks for a run now instead of waiting for the next " +
			"night. It is recorded with your name — the run's own row cannot say who asked, " +
			"because the scheduler makes the same call. This is not an alarm: an alert has to " +
			"reach a phone when this console is down, which is exactly when it is needed.",

		/* AND WHY THERE IS NONE, WHERE THERE IS NONE. This screen carried that
		   sentence for as long as no job could be started at all, and it still
		   needs one: a deployment that is not on Cloud Run has nothing to ask,
		   and somebody looking for the button should find the reason rather
		   than conclude it was forgotten. Which of the two sentences applies is
		   the same field the buttons are drawn from. */
		"nothing_to_press": "Nothing here can start a job. This deployment is not running on " +
			"Cloud Run, so there is nothing to ask — which is the ordinary state of a laptop, " +
			"of the local stack and of the test suite. A failed night still runs again on the " +
			"next one.",
	})
}

// startable is the list as the screen may use it: empty rather than nil where
// nothing can be started, so a client cannot tell a deployment with no runner
// from a field that failed to arrive.
func (h *JobsHandler) startable() []string {
	if h.jobs.Start == nil {
		return []string{}
	}
	out := make([]string, 0, len(h.jobs.Startable))
	out = append(out, h.jobs.Startable...)
	return out
}

func (h *JobsHandler) mayBeStarted(name string) bool {
	for _, one := range h.jobs.Startable {
		if one == name {
			return true
		}
	}
	return false
}

/*
start asks for one more run of a job.

	THE ORDER OF THE REFUSALS IS THE DESIGN. Rank, then the closed list, then
	whether anything can start a job at all, then whether one is already going —
	and only then is anything recorded. Every one of those answers is cheap and
	none of them writes, so a request that was never going to work leaves no
	entry claiming somebody did something.
*/
func (h *JobsHandler) start(w http.ResponseWriter, r *http.Request) {
	if !h.mayStart(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"starting a job asks for an operator")
		return
	}

	name := r.PathValue("job")
	if !h.mayBeStarted(name) {
		/* NOT A 404 ABOUT A JOB, a sentence about this list. The job may well
		   exist — `schooling-migrate` does — and answering "no such job" would
		   be false in the one case worth being careful about. */
		web.Fail(w, http.StatusNotFound, web.CodeNotFound,
			"that is not a job this console may start. What may be started is a short list, "+
				"and it is short on purpose: a migration and a catalogue load run in the same "+
				"project, and neither is a thing to begin by browsing")
		return
	}
	if h.jobs.Start == nil {
		web.Fail(w, http.StatusNotImplemented, "no_runner",
			"this deployment cannot start jobs. It is not running on Cloud Run, so there is "+
				"nothing to ask — which is the ordinary state of a laptop and of the test suite")
		return
	}

	/* ALREADY RUNNING IS A REFUSAL AND NOT A SECOND START. Two analyses at once
	   are two sweeps, and a sweep withdraws questions — the second one writes a
	   second audit entry for one withdrawal. An ADRIFT run is not a reason to
	   refuse: it is the state of a run that was killed, and refusing on it would
	   make a job unstartable until somebody edited the database. */
	recent, err := h.jobs.Latest(r.Context(), name, 1)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the runs of a job", "error", err, "job", name)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	if len(recent) == 1 && recent[0].Outcome == "running" && !recent[0].Adrift {
		web.Fail(w, http.StatusConflict, "already_running",
			"that job is running now. Starting a second one would be two sweeps over the same "+
				"night, which is two decisions about one question")
		return
	}

	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}
	label, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return
	}

	/* RECORDED BEFORE IT IS ASKED FOR, which is this console's rule everywhere.
	   Here the usual cost of it — an entry for something that then failed — is
	   smaller than usual and checkable: the run writes its own row when the
	   container comes up, so an entry with no run beside it is visible as
	   exactly that rather than having to be believed. */
	if err := h.record(r.Context(), actor, strings.TrimSpace(label+" <"+email+">"),
		"job.started",
		Subject{Kind: "job", ID: name},
		Changed{Before: was(recent), After: "asked to run now"},
		// Nobody is asked why they started a job, and nobody should be: the
		// schedule is unchanged and the run happens tonight anyway.
		"",
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a job start", "error", err, "job", name)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	if err := h.jobs.Start(r.Context(), name); err != nil {
		web.LoggerFrom(r.Context()).Error("starting a job", "error", err, "job", name)
		web.Fail(w, http.StatusBadGateway, web.CodeInternal,
			"the start was recorded and then refused, which is a defect — the history now "+
				"says a run was asked for and none was")
		return
	}

	web.JSON(w, http.StatusAccepted, map[string]any{
		"job": name,

		/* ACCEPTED AND NOT DONE, and the sentence says which. The call creates
		   an execution and returns; the container then takes as long as it
		   takes, and its row appears when it starts rather than now. A screen
		   told "started" would redraw, find no new run, and look broken. */
		"started": "Asked for. The run appears on this screen when the container comes up, " +
			"which is usually within a minute — nothing here waits for it, because the answer " +
			"to how it went is the row it writes on the way out.",
	})
}

// was is what the audit entry says the job was doing before somebody asked for
// another run. A job with no history says so in words rather than with an empty
// string, which reads as a missing field.
func was(recent []Run) string {
	if len(recent) == 0 {
		return "no run on record"
	}
	if recent[0].Adrift {
		return "adrift — started and never finished"
	}
	return recent[0].Outcome
}
