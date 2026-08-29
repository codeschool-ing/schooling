package console

/* Everything this console can change, declared.

   # K-13 ASKED FOR A CLOSED LIST AND THE OBVIOUS BUILD IS THE WRONG ONE

   The shape that suggests itself is a `system_parameters` table — a name, a
   value, a screen that edits any row of it. That is precisely what K-13 exists
   to refuse: a configuration surface grows to fill the space it is given, and
   every knob multiplies the state two people have to test. Build the registry
   and the next value somebody wants to make settable costs one INSERT and no
   argument.

   So the list is here, in Go, beside a test that holds it. What it closes is not
   the set of values a table may contain; it is the set of things this console
   can do at all.

   # AND THAT PARAGRAPH WAS RIGHT ABOUT THE DANGER AND WRONG ABOUT THE FENCE

   The registry it turns down was built, in `0046` and `internal/platform/setting`
   — read those two before this reads as a reversal, because the amendment is
   narrower than it looks.

   What K-13 protects is that a knob costs an ARGUMENT. A table and a migration
   per parameter delivered that by making the MECHANISM expensive, which worked
   while there were three and stops working the moment the platform wants
   fifteen: the cost of a migration is paid by whoever is tired enough to stop
   writing the sentence, and the sentence was the point.

   So the cost moved onto the declaration and stayed the same size. A parameter
   is a `setting.Declared` in the module that owns the decision, carrying its
   unit, the bounds it may move inside, the value the code shipped with, and the
   sentence saying what it decides — and `cmd` is where they become a set, so a
   name declared twice panics at start-up rather than letting one of them
   silently decide nothing. A name absent from that set is refused on the way in
   and ignored on the way out.

   The sentence "the next value somebody wants to make settable costs one INSERT
   and no argument" is the failure this arrangement is measured against, and
   `cmd/api`'s `TestEveryParameterCarriesItsArgument` is what holds it: no INSERT
   makes a parameter, and no declaration passes without the argument.

   # THE COST OF ADDING ONE IS THE POINT

   A new write in this package fails `TestEveryConsoleWriteIsDeclared` until it
   appears below with a sentence. Writing that sentence for a PARAMETER means
   arguing that the value has no right answer — because if it has one it belongs
   in code, where a test holds it, and this list is where somebody has to say so
   out loud rather than reach for a settings row.

   # TWO KINDS, AND THEY ARE NOT THE SAME QUESTION

   A PARAMETER persists: set it and the platform behaves differently until
   somebody sets it back. An ACTION happens once and leaves no setting behind —
   it changes the world and the world remembers, but there is no dial left at a
   new position. K-13 is about the first. The second is here because a list of
   what a console can change that omitted the erasures and the viewings would be
   a list that answers "what can this console do" wrongly, and that is the
   question a person actually asks of it.

   # WHAT IS NOT A FIELD HERE

   THE ROLE EACH ONE ASKS FOR. Every write below is refused below operator, and
   that is enforced by a closure `cmd/api` passes in and by a test per handler
   — this package cannot see the wiring, so a `Rank` column here would be a
   second answer that can disagree with the first. What this list is for is
   WHICH writes exist, not what guards them.

   # AND WHAT IS DELIBERATELY OUTSIDE IT

   `cmd/staff` grants a role, audited, from a terminal. It is a change to the
   system and it is not on this list, because this list is what the CONSOLE can
   change — and a role is granted by a command precisely because the first one
   could not be granted through a console that needs a role to open.

   THE CONSOLE CAN NOW SEE THAT LIST WITHOUT BEING ABLE TO CHANGE IT, which is
   `staff.go` and is correctly absent from here. A roster is a read; what makes
   it worth having is exactly that the write stays where it is. Two doors onto
   `staff` would be two paths to keep audited and in agreement, bought for the
   convenience of not opening a terminal on the rarest write this platform has.
*/

// Kind is what a write leaves behind.
type Kind string

const (
	// Parameter is a value that persists. K-13's subject: it exists only
	// because there is no right answer to write in code.
	Parameter Kind = "parameter"

	// Action happens once and leaves no setting at a new position.
	Action Kind = "action"
)

// Write is one thing this console can do.
type Write struct {
	// Route exactly as it is registered, so the test can compare strings
	// rather than parse them.
	Route string

	Kind Kind

	// Why is not decoration, and for a parameter it is the argument that the
	// value has no right answer. An entry whose reason would read "so it can be
	// configured" is an entry that should not exist.
	Why string
}

// Writes is every write route in this package. A test holds it to that, in both
// directions: an undeclared route fails, and so does an entry for a route that
// is no longer there — a stale exception is worse than a missing one, because
// it reads as current.
var Writes = []Write{
	{
		Route: "PUT /console/api/v1/schools/{id}/accent",
		Kind:  Parameter,
		Why: "a school's colour. There is no right answer — it is the one thing that differs " +
			"between schools so that a student knows which one they are in, and no test can " +
			"say that green is correct for a school teaching mathematics. It is REPLACED " +
			"rather than appended: there is one accent, and nothing has to be explained " +
			"about last month's",
	},
	{
		Route: "PUT /console/api/v1/plan/price",
		Kind:  Parameter,
		Why: "what a subscription costs, for one term. No right answer for the same reason and " +
			"a different shape: money is APPENDED, never overwritten (K-14), because a March " +
			"invoice has to stay explicable in November. Setting one writes a row dated from " +
			"today and the old row stays. It is the PLATFORM's and not a school's, because " +
			"one subscription opens every school (N-02) — two prices for the same thing is " +
			"an arbitrage rather than a choice",
	},
	{
		Route: "PUT /console/api/v1/plan/discount",
		Kind:  Parameter,
		Why: "what comes off for paying a way that costs us less to receive — five per cent " +
			"for a Pix. No right answer: it is the share of a cheaper settlement this " +
			"platform hands back, which is a commercial choice and not a fact anybody can " +
			"check. APPENDED like the price and for a reason of its own: a past sale is " +
			"already explicable without a series, because the checkout records what was " +
			"charged beside the price row it was sold under — what a series adds is the " +
			"fortnight that sold NOTHING, which leaves no trace in any sale and is exactly " +
			"the fortnight somebody asks about. The CEILING stays in code (0045, " +
			"MostBasisPoints): it guards 5000 typed where 500 was meant, and a fence " +
			"somebody can move from a screen is a fence in the way rather than a fence",
	},
	{
		Route: "PUT /console/api/v1/support/contact",
		Kind:  Parameter,
		Why: "where a student writes to use the seven days the terms promise. No right answer, " +
			"and for a reason neither of the two above gives: it is a fact about WHO IS " +
			"ANSWERING rather than about the platform, so the correct address changes when " +
			"the person does and no code changes with it. REPLACED like the accent — a " +
			"price is a series because a March invoice has to stay explicable in November, " +
			"and an address owes nothing like that, because what was published in March is " +
			"what the audit entry says. It lived in the infrastructure until 0044, which " +
			"meant an apply and a new revision from the one machine holding a gitignored " +
			"file — and an apply from anywhere else planned it back to empty and took the " +
			"address off the screen with nothing failing, which is a right losing the way " +
			"to use it in silence",
	},
	{
		Route: "PUT /console/api/v1/settings/{name}",
		Kind:  Parameter,
		Why: "every OTHER knob this platform has, through one route. It looks like the " +
			"`system_parameters` table this file opens by refusing and it is not, because the " +
			"refusal was about where the cost sits rather than about the shape: the set of " +
			"names is closed in Go, each one declared beside the code that reads it with its " +
			"unit, its bounds, the value the code shipped with and the argument for it " +
			"existing. The path parameter is checked against that set and nothing else — a " +
			"name nobody declared is a 404 here and decides nothing anywhere. What this " +
			"entry buys is that the eleven numbers a deployment used to be needed to move " +
			"can move on a Tuesday afternoon; what it does not buy is a twelfth without a " +
			"declaration, which is the whole of K-13 and is unchanged. REPLACED and not " +
			"appended: none of these is money, the values that needed dating (a price, a " +
			"discount, the mark a paper was judged by) have their own tables, and the audit " +
			"entry is the history of the rest",
	},
	{
		Route: "POST /console/api/v1/people/{id}/erase",
		Kind:  Action,
		Why: "the phase-0 obligation. It happens once, to one person who asked, and what it " +
			"leaves behind is an audit entry rather than a setting",
	},
	{
		Route: "POST /console/api/v1/students/{id}/view/{school}",
		Kind:  Action,
		Why: "starting a viewing (K-02). It mints a session that expires by itself, so there " +
			"is nothing left at a new position half an hour later — which is the difference " +
			"between this and a switch that turns support access on",
	},
	{
		Route: "POST /console/api/v1/reports/{report}/settle",
		Kind:  Action,
		Why: "answering a student who said the material is wrong. One report, one decision, " +
			"and the row it closes is the student's rather than the platform's",
	},
	{
		Route: "POST /console/api/v1/people/{id}/subscription/extend",
		Kind:  Action,
		Why: "giving somebody time nobody paid for — an outage, a fortnight lost to support. " +
			"It happens once and leaves no dial at a new position: their term is longer and " +
			"nothing about the platform behaves differently afterwards. The CEILING on it " +
			"is in code rather than settable, because the mistake it guards against is a " +
			"typed zero and there is no right answer to make configurable",
	},
	{
		Route: "POST /console/api/v1/people/{id}/subscription/cancel",
		Kind:  Action,
		Why: "stopping the renewal notices. It does NOT take access away — every purchase " +
			"here is a term bought outright and the paid period is honoured — so what it " +
			"changes today is that nobody writes to somebody about renewing a thing they " +
			"have already said they are leaving",
	},
	{
		Route: "POST /console/api/v1/people/{id}/ledger/adjustment",
		Kind:  Action,
		Why: "one line in the ledger for money that moved outside the gateway: a bank " +
			"transfer, a write-off, a goodwill credit, an amount keyed wrongly once. It is " +
			"the escape hatch and is supposed to look like one — everything else this " +
			"console does is a shape the system understands, and this is the one that says " +
			"something happened that none of them describe. It tells the gateway nothing: " +
			"no money moves because of this row, it records that money moved elsewhere",
	},
	{
		Route: "POST /console/api/v1/purchases/{id}/refund",
		Kind:  Action,
		Why: "sending money back. It is the only write in this console that changes something " +
			"OUTSIDE it — everything else moves rows this platform owns, and this asks the " +
			"gateway and then stops. What it leaves behind here is an audit entry saying " +
			"somebody asked; the ledger row and the closed subscription arrive with the " +
			"webhook that refund causes, which is the same path a refund made from the " +
			"gateway's own dashboard takes. One writer for money, and it is the one that " +
			"hears from the gateway",
	},
	{
		Route: "POST /console/api/v1/jobs/{job}/run",
		Kind:  Action,
		Why: "asking for a run of a scheduled job now rather than waiting for tonight. It " +
			"leaves no dial at a new position — the schedule is unchanged and the next run " +
			"happens anyway — and WHICH jobs it may ask for is a closed list of its own, " +
			"because a migration and a catalogue load are in the same project one path " +
			"parameter away",
	},
}

// Parameters is the closed list K-13 asks for, which is this one narrowed to
// the kind that persists. It is a function rather than a second slice, so there
// is no way for the two to disagree about what a parameter is.
func Parameters() []Write {
	var out []Write
	for _, w := range Writes {
		if w.Kind == Parameter {
			out = append(out, w)
		}
	}
	return out
}
