package identity

import (
	"context"
	"fmt"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
	"github.com/google/uuid"
)

/* Who is here right now.

   # THE ONLY NUMBER IN THE CONSOLE THAT IS NOT FROM THE EVENT STREAM

   K-03 says statistics come from `events` and never from current state, because
   current state has been overwritten. This is the one question where being
   overwritten is the point. Nobody asks who was online last March — and the
   stream could not answer it if they did, because answering would need an event
   for LEAVING and no browser reliably sends one. A tab closed by a flat battery
   emits nothing, so "still here" is inferred from an absence either way; doing
   it from a column is the same arithmetic two tables closer to the fact.

   # IT COUNTS PEOPLE AND NOT SESSIONS

   Same rule as the funnel's, for the same reason: somebody with a laptop and a
   phone is one person, and counting sessions would make the number go up when
   the population did not. So the count is DISTINCT over accounts, per school,
   and the platform-wide figure is distinct again across schools rather than the
   sum of them — a person studying in two schools is in both numbers and once in
   the total.

   # AND IT DOES NOT SAY WHO THEY ARE

   K-22 no longer says people are never listed — it was amended, and a listing
   is allowed where it is bounded, minimal, counted and named. This would be
   none of those, and the last two are what settle it: a list of who is online
   is refreshed on a timer, so there is no moment at which somebody asked for it
   and nothing to record against a purpose. That is a browse of the population
   with the one thing the amendment rests on missing.

   So this answers a count and has no shape in which to return a name. The
   operator who needs one has it already, because somebody wrote in — and the
   operator who does not have it has `Look`, which records that they asked.
*/

/*
PresenceWindow is how recently somebody has to have been seen to be here.

	IT WAS A CONSTANT, AND THE ARGUMENT FOR THAT WAS RIGHT ABOUT ONE END ONLY.
	It read: the answer follows from the heartbeat, because `Verify` writes at
	most once a minute, so a window narrower than that reports people as gone
	between their own requests — and a window much wider stops being "now".

	The first half is a fact and the second half is a preference wearing its
	clothes. Nothing measures where "now" ends. Three minutes and ten minutes
	are both defensible readings of the same screen, and which one an operator
	wants depends on what they are watching for: a deploy going wrong wants the
	short end, an evening's traffic wants the long one.

	SO THE FACT BECAME THE FENCE AND THE PREFERENCE BECAME THE KNOB. `Least` is
	twice the cadence, which is the constraint the old comment actually
	established — `TestTheWindowCannotBeSetInsideTheHeartbeat` holds the two
	together, because the day somebody changes the cadence is the day this
	bound stops being derived from anything.

	`Most` is half an hour, where a count of "who is here" has plainly become a
	count of who was here.

	IT STILL TRAVELS TO THE SCREEN BESIDE THE NUMBER IT PRODUCED (K-16) rather
	than being written down again there — and it matters more now, not less: a
	screen with the window hard-coded would label today's count with yesterday's
	span the moment somebody moved it.
*/
var PresenceWindow = setting.Declared{
	Name:     "identity.presencewindow",
	Unit:     setting.Minutes,
	Least:    2,
	Most:     30,
	Fallback: 5,
	Why: "how recently somebody has to have been seen to count as here. Nothing measures " +
		"where \"now\" ends — a deploy going wrong is watched at the short end and an " +
		"evening's traffic at the long one — so this is what the platform means by now. " +
		"It cannot go below twice the heartbeat, because a window narrower than the " +
		"writing cadence reports people as gone between their own requests.",
}

// Window is the declaration's answer as a duration, which is what everything
// that reads it actually wants. The registry counts in whole minutes because a
// screen and an audit entry both do; this is the one place that conversion
// lives, so it cannot be written down two ways.
func Window(minutes int) time.Duration {
	return time.Duration(minutes) * time.Minute
}

// PresenceCadence is what the heartbeat costs, sent alongside the window
// because it is the other half of what the number means: a count of people seen
// in the last five minutes, refreshed no oftener than once a minute per person,
// is accurate to a minute and no better. Saying so is cheaper than somebody
// discovering it from a graph that moves in steps.
const PresenceCadence = time.Minute

// Present is one school and how many people are in it.
type Present struct {
	School uuid.UUID
	People int
}

// Presence answers who is here, per school and in total.
//
// The two numbers do not add up on purpose — see the file header — so they come
// back from one query over one set of rows rather than from two reads that
// could disagree about the second somebody arrived.
func (s *Store) Presence(ctx context.Context, window time.Duration) ([]Present, int, error) {
	rows, err := s.pool.Query(ctx, `
		WITH here AS (
			SELECT DISTINCT s.last_seen_tenant AS school, s.account_id
			FROM sessions s
			JOIN accounts a ON a.id = s.account_id
			WHERE s.revoked_at IS NULL
			  AND s.expires_at > now()
			  AND s.last_seen_tenant IS NOT NULL
			  AND s.last_seen_at > now() - make_interval(secs => $1::double precision)

			  -- AN OPERATOR LOOKING AT A STUDENT'S SCREENS IS NOT THE STUDENT
			  -- BEING HERE. A viewing is a session on the school's host and
			  -- would otherwise count as one more person present — which is a
			  -- number that goes up when support gets busy and says nothing
			  -- about anybody studying.
			  AND s.viewed_by IS NULL

			  -- Seeded students hold no sessions at all: the seeder writes a
			  -- past into the event stream and never signs anybody in. So this
			  -- exclusion removes nothing today and is here because K-11 is
			  -- about what every aggregate does rather than about what happens
			  -- to be reachable — and it gets no switch beside it, because a
			  -- control whose two settings draw the same picture is a control
			  -- that teaches people not to trust the others.
			  AND NOT a.synthetic
		), per_school AS (
			SELECT school, count(*) AS people FROM here GROUP BY school
		)
		SELECT school, people, (SELECT count(DISTINCT account_id) FROM here)
		FROM per_school
		ORDER BY people DESC, school
	`, window.Seconds())
	if err != nil {
		return nil, 0, fmt.Errorf("identity: reading who is here: %w", err)
	}
	defer rows.Close()

	var out []Present
	var everywhere int
	for rows.Next() {
		var one Present
		if err := rows.Scan(&one.School, &one.People, &everywhere); err != nil {
			return nil, 0, fmt.Errorf("identity: reading who is here: %w", err)
		}
		out = append(out, one)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("identity: reading who is here: %w", err)
	}
	// No rows means nobody is anywhere, and `everywhere` was never scanned —
	// which is the zero it should be.
	return out, everywhere, nil
}
