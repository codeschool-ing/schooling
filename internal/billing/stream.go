package billing

import (
	"context"

	"github.com/google/uuid"
)

/*
What a subscription's life looks like from the outside, for counting.

# WHY THIS EXISTS AT ALL

`subscription_events` has recorded every transition since phase 3. It is the
answer to "I was locked out on Tuesday and I had paid", and it is the wrong
thing to count from: it is a log keyed by subscription, written for a person
reading one account, and statistics in this platform come from the stream and
never from anywhere else (see `internal/event`). Nothing put a subscription
into that stream, and three things stayed open because of it — the funnel's
last step came back saying it was not measured, a cohort could not be grouped
by when somebody started paying, and the seeder could not represent a refund.
All three are the same missing row, and `docs/ROADMAP.md` says so in three
places.

# THREE NAMES AND NOT SEVEN

The state machine next door has seven events — paid, payment-failed,
retries-exhausted, cancelled, refunded, charged-back, granted — and mirroring
them here was the first thing tried. It is the wrong shape twice over.

A NAME IN THE STREAM IS FOREVER. The stream is append-only and a report reads
what was written years ago, so every name is a commitment that outlives the
code that emitted it. The seven are how billing works TODAY: `grace` and
`suspended` exist only for real recurrence, which this platform does not sell
yet (N-08), and a name emitted for a state nothing enters is a name somebody
has to keep understanding forever.

AND THEY ANSWER A DIFFERENT QUESTION. `retries-exhausted` is a fact about a
card. What a report asks is whether somebody started paying, kept paying, or
stopped — so those are the three, and WHY it stopped is the payload, where a
reason can be added without minting a name.

WHAT IS DELIBERATELY NOT HERE: grace and suspension. Nothing asks about them —
they are recoverable states on a model this platform does not sell — and an
event nobody reads is a name that can never be removed. When a screen asks,
it arrives with the screen.

# AND IT IS A CALLBACK, LIKE EVERYTHING ELSE THAT LEAVES A MODULE

X-02: modules do not import modules. `progress.Emit` and `catalog.Emit` are the
same arrangement and `cmd/api` wires all three.

IT TAKES THE ACCOUNT RATHER THAN READING ONE FROM THE CONTEXT, which is where
it differs from those two and the difference is not a preference. They are
called from a handler, where the person acting IS the person the event is
about. Half of these are not: a settlement arrives on a webhook the gateway
called, and an operator's grant is about somebody else entirely. An emitter
that read `identity.FromContext` would attribute a student's renewal to
whoever's request happened to be running — or, on the webhook, drop it.
*/
type Emit func(ctx context.Context, name string, accountID uuid.UUID, payload map[string]any)

const (
	// EventStarted is a subscription existing where there was none. Once per
	// subscription, ever — a renewal is the name below, and the two are
	// separate because "how many people started paying in March" and "how much
	// was collected in March" are different questions that a single name would
	// answer with the same number.
	EventStarted = "subscription.started"

	// EventRenewed is a payment on one that already existed. It is the same
	// row: a subscription is reused for years, which is what keeps progress and
	// history attached to one thing (see `Begin`).
	EventRenewed = "subscription.renewed"

	// EventEnded is access closing for good — cancelled, refunded, charged
	// back, or a term that simply ran out. The payload says which, under
	// `reason`, spelling it exactly as the state machine's own event does so
	// that a row in the stream and a row in `subscription_events` can be put
	// beside each other.
	EventEnded = "subscription.ended"
)

// ended says whether a transition closed access for good.
//
// IT IS COMPUTED FROM `Opens` RATHER THAN FROM A LIST OF STATES, so a state
// added later cannot be forgotten here: whatever the machine says opens
// nothing, this reports as an ending. `Opens` is already exhaustive over the
// closed list of states, and having one place that decides means there is no
// second copy to drift.
//
// SUSPENSION IS NOT AN ENDING, and this is where that shows: it closes access
// and is recoverable, so it is excluded by name. That exclusion is the only
// thing in this file that has to move when the platform sells real recurrence.
func ended(was, now Subscription) bool {
	if now.State == StateSuspended {
		return false
	}
	return Opens(was) && !Opens(now)
}
