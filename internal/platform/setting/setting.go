/*
Package setting is every knob this platform has, declared where it is read.

# WHAT IT IS FOR, AND WHAT IT IS NOT

K-13 said only something without a right answer becomes a parameter, and
`console/writes.go` enforced it by making the mechanism expensive: a table and a
migration per knob. That works at three and fails at fifteen — the cost of a
migration is paid by whoever is tired enough to stop writing the sentence, and
the sentence was the point.

So the cost moves. `0046` gives every parameter one table, and this package
holds the fence that table used to be: the CLOSED SET OF NAMES, each with the
unit it counts in, the bounds it sits inside, the value it falls back to, and
the sentence saying what it decides. A name absent from the set is refused on
the way in and ignored on the way out.

Adding a knob still costs a declaration and an argument. It no longer costs a
table, and that is the only thing about K-13 that changed.

# WHERE A DECLARATION LIVES

Beside the code that reads it, in the module that owns the decision — not in a
list here. `exam` knows why a pass mark is 70; this package does not, and a
registry that carried every module's reasons would be the one file nobody keeps
true. `cmd` gathers them, which is where this repository assembles everything
else that crosses a module boundary.

That also means the closed set is closed by the COMPILER: a name that is not a
declared var in some module is not in the registry, and `Registry` refuses two
declarations of one name rather than letting the later win.

# READING IS FROM A SNAPSHOT, AND IT IS EVENTUALLY CONSISTENT

A parameter is read on paths that run per request — the presence window on every
heartbeat, the pass mark on every graded paper — and a query each time would put
this table in front of things that have nothing to do with it.

So the store keeps a snapshot and refreshes it when it is older than `stale`.
The consequence is honest and worth stating: after a write, another instance of
this server can go on answering the old value for up to that long. For a pass
mark or a presence window that is a non-event. It would not be acceptable for
anything about ACCESS, which is why nothing about access is here — K-15 keeps
the paywall out of every parameter surface, and this package is one.

# WHAT MAY NOT BE DECLARED HERE

Anything whose wrong value is a weakening rather than a preference: the minimum
length of a password, how many recovery codes are issued, the cost parameters of
the hash, the size of a token. Those have right answers — the highest the
platform can afford — and a settable minimum is a weakening with an interface on
it. `Declared` cannot enforce that; the sentence a declaration carries is where
somebody has to say it out loud, and a review is what reads it.
*/
package setting

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Unit is what a parameter counts in. It decides how a value is parsed, how it
// is drawn, and what the bounds mean — one field rather than three that can
// disagree.
type Unit string

const (
	// Count is a whole number of things: questions on a paper, instalments.
	Count Unit = "count"

	// Percent is hundredths of a whole, as a whole number: a pass mark of 70.
	Percent Unit = "percent"

	// Days is a whole number of days.
	Days Unit = "days"

	// Minutes is a whole number of minutes.
	Minutes Unit = "minutes"

	// Seconds is a whole number of seconds.
	Seconds Unit = "seconds"

	// Bytes is a whole number of bytes.
	Bytes Unit = "bytes"
)

// ErrUnknown is a name nothing declared. It is returned rather than ignored on
// a write, because a caller asking for a name that does not exist is a caller
// with a stale idea of what this platform has.
var ErrUnknown = errors.New("setting: nothing declares that parameter")

// ErrOutOfBounds is a value outside what its declaration allows.
var ErrOutOfBounds = errors.New("setting: that is outside what this parameter allows")

// ErrNotANumber is a value that is not one.
var ErrNotANumber = errors.New("setting: that is not a number")

/*
Declared is one parameter, and it is the whole of what makes a knob legitimate.

	EVERY FIELD IS LOAD-BEARING. `Least` and `Most` are the fence — the mistake
	nearly every one of these guards is a digit too many, and a fence a screen
	can move is a fence in the way. `Fallback` is what the platform behaves like
	before anybody sets one and if the row is ever unreadable, so it is the value
	the code shipped with rather than a placeholder. `Why` is the argument: an
	entry whose reason reads "so it can be configured" is an entry that should
	not exist, and that is the sentence a review is looking for.
*/
type Declared struct {
	// Name is `module.thing`, lowercase, dotted. It is the primary key of the
	// table and it is what an audit entry names, so it is read by somebody who
	// has neither this file nor the console in front of them.
	Name string

	Unit Unit

	// Least and Most bound what may be written. Both inclusive.
	Least, Most int

	// Fallback is the value in force until somebody sets one — the number the
	// code carried before it became a parameter.
	Fallback int

	// Why says what this decides and why it has no right answer. It is the
	// cost of adding a knob, and it is shown on the screen that sets it: an
	// operator changing a number should be reading the argument for it.
	Why string
}

// Valid answers whether a value may be written, and says why not.
func (d Declared) Valid(value int) error {
	if value < d.Least || value > d.Most {
		return fmt.Errorf("%w: %s takes %d to %d and %d is outside that",
			ErrOutOfBounds, d.Name, d.Least, d.Most, value)
	}
	return nil
}

/*
Registry is the closed set, assembled by `cmd` from what the modules declare.

	IT REFUSES A REPEATED NAME rather than letting the later win. Two
	declarations of one name is two modules believing they own a decision, and
	the failure that follows is a value changed on a screen that moves one of
	them — which is the kind of thing found months later by somebody who does
	not believe what they are seeing.
*/
type Registry struct{ by map[string]Declared }

// NewRegistry gathers declarations and refuses a name declared twice.
func NewRegistry(all ...Declared) (*Registry, error) {
	by := make(map[string]Declared, len(all))
	for _, one := range all {
		if one.Name == "" {
			return nil, fmt.Errorf("setting: a declaration with no name (%q)", one.Why)
		}
		if _, twice := by[one.Name]; twice {
			return nil, fmt.Errorf("setting: %q is declared twice, so two places believe "+
				"they own it", one.Name)
		}
		if one.Least > one.Most {
			return nil, fmt.Errorf("setting: %q allows %d to %d, which is no value at all",
				one.Name, one.Least, one.Most)
		}
		if err := one.Valid(one.Fallback); err != nil {
			return nil, fmt.Errorf("setting: %q falls back to a value it would refuse: %w",
				one.Name, err)
		}
		by[one.Name] = one
	}
	return &Registry{by: by}, nil
}

// MustRegistry is NewRegistry for `cmd`, where a bad declaration is a
// compile-time-shaped mistake nobody can recover from at run time.
func MustRegistry(all ...Declared) *Registry {
	r, err := NewRegistry(all...)
	if err != nil {
		panic(err)
	}
	return r
}

// Declaration answers what a name declares, and whether anything does.
func (r *Registry) Declaration(name string) (Declared, bool) {
	one, ok := r.by[name]
	return one, ok
}

// All is every declaration, by name, so a screen draws them in one order
// however the modules happen to be assembled.
func (r *Registry) All() []Declared {
	out := make([]Declared, 0, len(r.by))
	for _, one := range r.by {
		out = append(out, one)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out
}

/*
Store reads and writes the rows, against the registry.

	THE SNAPSHOT IS THE POINT. See the package comment: these are read on paths
	that run per request, and a query each time would put this table in front of
	things that have nothing to do with it. The cost is that a write takes up to
	`stale` to reach another instance of this server, which is stated rather than
	hidden — and is why nothing about access may be declared here.
*/
type Store struct {
	pool  *pgxpool.Pool
	known *Registry

	// stale is how long a snapshot is used before it is read again.
	stale time.Duration

	mu    sync.RWMutex
	held  map[string]int
	taken time.Time
}

// NewStore is the store over a pool and a registry.
//
// Fifteen seconds is chosen against what these values are: nobody sets a pass
// mark and then checks whether it took effect within the second, and a window
// short enough to feel instant would put a query on every heartbeat to save
// somebody a wait they are not having.
func NewStore(pool *pgxpool.Pool, known *Registry) *Store {
	return &Store{pool: pool, known: known, stale: 15 * time.Second}
}

/*
Int is what a parameter is set to, or what it falls back to.

	IT NEVER FAILS, and that is deliberate rather than lax. Every caller is a
	line of ordinary behaviour — how many questions to draw, how long a viewing
	lasts — and there is no useful thing any of them could do with an error. A
	database that cannot be read costs the platform its configured values and
	not its behaviour: it falls back to what the code shipped with, which is the
	number that was there before any of this existed.

	AN UNDECLARED NAME ANSWERS ZERO, which is a programming mistake rather than
	a state: nothing should ask for a name nothing declares, and a test in `cmd`
	holds that every name a module reads is a name some module declared.
*/
func (s *Store) Int(ctx context.Context, name string) int {
	one, declared := s.known.Declaration(name)
	if !declared {
		return 0
	}

	s.mu.RLock()
	fresh := time.Since(s.taken) < s.stale && s.held != nil
	value, set := s.held[name]
	s.mu.RUnlock()

	if fresh {
		if set {
			return value
		}
		return one.Fallback
	}

	s.refresh(ctx)

	s.mu.RLock()
	defer s.mu.RUnlock()
	if value, set := s.held[name]; set {
		return value
	}
	return one.Fallback
}

/*
Reads is `Int` for one declaration, as the function type the modules take.

	IT EXISTS SO A MODULE NEVER NAMES A PARAMETER BY STRING. `cmd` wires
	`settings.Reads(billing.MostInstalments)` and the compiler carries the name,
	so a declaration that is renamed or deleted breaks the wiring instead of
	quietly answering the fallback for ever — which is the failure this whole
	arrangement is otherwise wide open to, and the one nothing would report.
*/
func (s *Store) Reads(one Declared) func(context.Context) int {
	return func(ctx context.Context) int { return s.Int(ctx, one.Name) }
}

// refresh reads the whole table, which is a handful of rows and one round trip
// however many parameters are asked for in the request that triggered it.
func (s *Store) refresh(ctx context.Context) {
	rows, err := s.pool.Query(ctx, `SELECT name, value FROM settings`)
	if err != nil {
		// The snapshot stands, however old it is. A read that failed is not
		// news about what anything is set to.
		return
	}
	defer rows.Close()

	held := map[string]int{}
	for rows.Next() {
		var name, value string
		if err := rows.Scan(&name, &value); err != nil {
			return
		}
		one, declared := s.known.Declaration(name)
		if !declared {
			// A row for a name nothing declares any more. It is left alone in
			// the table — deleting somebody's setting because a deployment
			// rolled back would be worse — and it decides nothing.
			continue
		}
		number, err := strconv.Atoi(strings.TrimSpace(value))
		if err != nil || one.Valid(number) != nil {
			// Written by hand, or declared differently since. The fallback is
			// the honest answer and it is what this leaves in place.
			continue
		}
		held[name] = number
	}
	if rows.Err() != nil {
		return
	}

	s.mu.Lock()
	s.held, s.taken = held, time.Now()
	s.mu.Unlock()
}

/*
Set writes a value and answers the one it replaces.

	`was` IS THE VALUE THAT WAS IN FORCE, which is the row when there is one and
	the fallback when there is not — because that is what the platform was
	actually doing, and an audit entry naming a blank would be naming the
	absence of a row rather than the behaviour it changed.
*/
func (s *Store) Set(ctx context.Context, name string, value int) (was int, err error) {
	one, declared := s.known.Declaration(name)
	if !declared {
		return 0, fmt.Errorf("%w: %q", ErrUnknown, name)
	}
	if err := one.Valid(value); err != nil {
		return 0, err
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return 0, fmt.Errorf("setting: writing %s: %w", name, err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	was = one.Fallback
	var stored string
	err = tx.QueryRow(ctx, `SELECT value FROM settings WHERE name = $1 FOR UPDATE`,
		name).Scan(&stored)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// Nothing set: the platform was doing what the code shipped with.
	case err != nil:
		return 0, fmt.Errorf("setting: reading %s: %w", name, err)
	default:
		if number, err := strconv.Atoi(strings.TrimSpace(stored)); err == nil {
			was = number
		}
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO settings (name, value, set_at) VALUES ($1, $2, now())
		ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value, set_at = EXCLUDED.set_at
	`, name, strconv.Itoa(value)); err != nil {
		return 0, fmt.Errorf("setting: writing %s: %w", name, err)
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, fmt.Errorf("setting: writing %s: %w", name, err)
	}

	// The snapshot is dropped rather than patched: this instance answers the
	// new value on the next read, and every other one answers it within
	// `stale`. Patching would leave this instance right and the others behind
	// by the same amount, which is the same guarantee with more code.
	s.mu.Lock()
	s.taken = time.Time{}
	s.mu.Unlock()

	return was, nil
}

// Current is every declared parameter with what it is set to and whether that
// is a row or the fallback — which is what a screen needs to say whether
// anybody has ever decided this one.
type Current struct {
	Declared
	Value int

	// Set is whether a row says so. False means the value is the fallback, and
	// the screen says which: "nobody has changed this" and "somebody set it
	// back to what it was" are different facts.
	Set bool

	// Since is when the row was written, and zero when there is none.
	Since time.Time
}

// Now is every declaration with what it is set to, in name order.
func (s *Store) Now(ctx context.Context) ([]Current, error) {
	rows, err := s.pool.Query(ctx, `SELECT name, value, set_at FROM settings`)
	if err != nil {
		return nil, fmt.Errorf("setting: reading the parameters: %w", err)
	}
	defer rows.Close()

	type row struct {
		value string
		at    time.Time
	}
	stored := map[string]row{}
	for rows.Next() {
		var name string
		var one row
		if err := rows.Scan(&name, &one.value, &one.at); err != nil {
			return nil, fmt.Errorf("setting: reading the parameters: %w", err)
		}
		stored[name] = one
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("setting: reading the parameters: %w", err)
	}

	out := make([]Current, 0, len(s.known.by))
	for _, one := range s.known.All() {
		current := Current{Declared: one, Value: one.Fallback}
		if held, there := stored[one.Name]; there {
			if number, err := strconv.Atoi(strings.TrimSpace(held.value)); err == nil &&
				one.Valid(number) == nil {

				current.Value, current.Set, current.Since = number, true, held.at
			}
		}
		out = append(out, current)
	}
	return out, nil
}
