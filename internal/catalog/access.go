package catalog

// Whether a student may open a course, and it is computed rather than stored.
//
// # FAIL-CLOSED, EVERYWHERE
//
// Access is an active subscription, a published course and the same school
// (K-15). Every one of those is a fact this code can establish; none of them is
// a row somebody can flip. The day correctness depends on a mutable setting
// instead of code with a test, it stops being possible to assert that the
// paywall works at all.
//
// So the answers here are deliberately asymmetric. Something recognised opens a
// course; ANYTHING ELSE closes it — an unknown plan, an empty plan, a plan
// somebody misspelled in a future migration. A paywall that opens on an
// unrecognised input is not a paywall; it is a paywall with a list of ways
// around it that nobody has finished writing.
//
// THE PAYWALL IS NOT CONFIGURABLE. Granting one named student access is a
// legitimate audited action; a global switch is not, and there is no code here
// that could implement one.

// Plan is what a student is paying for, as far as the catalogue needs to know.
// Billing owns the real thing; this is the part that decides a door.
type Plan string

const (
	// PlanNone is a visitor, or an account with no subscription. It is also
	// what an unrecognised plan becomes.
	PlanNone Plan = "none"

	// PlanFull covers every school (N-02). There is one paid plan today, and
	// the scope is modelled in billing rather than here.
	PlanFull Plan = "full"
)

// recognised is the whole list. A plan that is not in it is a guest — see the
// package comment for why that direction and not the other.
var recognised = map[Plan]bool{PlanNone: true, PlanFull: true}

// Access is the decision, with the reason it was reached.
//
// THE REASON IS NOT DECORATION. It is what a screen says to somebody who cannot
// open a lesson, and it is what an event carries so the funnel can tell "did
// not subscribe" from "subscribed and never came back".
type Access struct {
	Allowed bool
	Reason  string
}

// The reasons. They are a closed set for the same reason plans are.
const (
	ReasonFreeTier     = "free-tier"    // the first course of a track, open to everybody
	ReasonSubscription = "subscription" // an active subscription covers it
	ReasonNoPlan       = "no-plan"      // no subscription, and not in the free tier
	ReasonDraft        = "draft"        // being written; nobody sees it, including subscribers
	ReasonUnknownPlan  = "unknown-plan" // something this code does not recognise
)

// MayOpen answers whether this plan opens this course.
//
// `free` is whether the course is the first of some track — the shop window,
// and it must be open at every door (N-04). It is passed in rather than
// computed here because it is a property of the catalogue's shape, which the
// store knows and this function should not have to query for.
func MayOpen(plan Plan, course *Course, free bool) Access {
	// A draft is not a product. It is invisible to everybody, including
	// somebody who has paid — publishing is the decision that makes it real,
	// and a subscriber seeing half a course first is worse than not seeing it.
	if course.Draft {
		return Access{Allowed: false, Reason: ReasonDraft}
	}

	if !recognised[plan] {
		return Access{Allowed: false, Reason: ReasonUnknownPlan}
	}

	if free {
		return Access{Allowed: true, Reason: ReasonFreeTier}
	}

	if plan == PlanFull {
		return Access{Allowed: true, Reason: ReasonSubscription}
	}

	return Access{Allowed: false, Reason: ReasonNoPlan}
}
