package analysis

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
)

/* What the people are holding.

   # IT IS `countries.go` WITH ONE COLUMN CHANGED, AND THAT IS THE POINT

   The two questions have the same shape all the way down: an identity seen on
   a thing, folded into a person the way the funnel folds them, counted once per
   thing and once overall. Written differently they would be two reports of one
   stream disagreeing about how many people there are — both right by their own
   definition, neither reconcilable, which is worse than one of them being wrong
   because there is nothing to fix.

   So this is the same file with `Country` replaced by `Device`, deliberately,
   down to the sentence about somebody appearing twice.

   # A PERSON ON TWO THINGS IS ON BOTH

   Somebody who reads on a phone in a queue and drills on a laptop in the
   evening is two rows, which is the honest answer to "what do people study on"
   and makes the devices add up to MORE than the number of people. `People`
   comes back beside them for that reason — every person counted once, however
   many things they were seen on — so a screen can show both halves and nobody
   adds the bars up into a headcount.

   # AND `unknown` IS A DEVICE ON THE LIST

   It is every browser that sends no client hint and no header of ours, which
   today is most of what is not Chromium. Dropping it, or folding it into the
   largest bucket, would make the percentages lies in the direction that flatters
   whichever browser we happen to be able to read.

   # WHAT THIS IS FOR

   Not "what percentage are on a phone", which is trivia. It is for the
   comparison: a share of the arrivals on a phone that is far from the share of
   the people who finish is a defect with an address, and it is invisible in
   every other number on this platform. */

// Holdings is the stream's reader, defined here and satisfied by the module
// that owns the rows.
type Holdings func(ctx context.Context, tenantID uuid.UUID, since time.Time,
	who Counting) ([]Holding, error)

// Holding is one identity seen on one kind of device.
type Holding struct {
	Device    string
	VisitorID *uuid.UUID
	AccountID *uuid.UUID
}

// Device is one row of the breakdown.
type Device struct {
	// Kind is one of the four words `platform/device` declares.
	Kind string

	// People is how many distinct people were seen on it.
	People int

	/* Students is how many of those People have an account.

	   THIS IS THE CROSS, AND IT IS WHY THE BREAKDOWN IS WORTH HAVING. "Seventy
	   per cent are on phones" is trivia; "seventy per cent are on phones and a
	   tenth of them ever signed up, against half of the people on a keyboard"
	   is a defect with an address, and it is invisible in every other number on
	   this platform.

	   IT IS THE SAME DEFINITION OF A PERSON the funnel uses, computed by the
	   same function one line down: an identity that `links` resolves to an
	   account is a student, and a bare visitor is not. Anything else would be a
	   second conversion rate on a second screen, disagreeing with the first. */
	Students int
}

// Held is the whole answer.
type Held struct {
	Devices []Device

	// People is every person counted ONCE, whatever they were seen on. The
	// devices sum to at least this and usually to more.
	People int
}

// Devices answers what the people of one school were on, over the population
// `who` names.
func (s *Store) Devices(ctx context.Context, tenantID uuid.UUID, since time.Time,
	who Counting) (Held, error) {

	if s.holdings == nil || s.links == nil {
		return Held{}, fmt.Errorf("analysis: this store was built without the stream to read")
	}

	holdings, err := s.holdings(ctx, tenantID, since, who)
	if err != nil {
		return Held{}, fmt.Errorf("analysis: reading what people were on: %w", err)
	}

	links, err := s.links(ctx)
	if err != nil {
		return Held{}, fmt.Errorf("analysis: reading which visitors belong to an account: %w", err)
	}

	// One set of people per device, and one set of all of them. The second is
	// not the sum of the first, and that is the whole reason it is kept.
	byDevice := map[string]map[string]bool{}
	everybody := map[string]bool{}

	for _, h := range holdings {
		person := personOf(Reach{VisitorID: h.VisitorID, AccountID: h.AccountID}, links)
		if person == "" {
			// An event with neither identity on it. It happened, and there is
			// nobody to count it for — counting it as an anonymous person would
			// inflate whichever device it came from.
			continue
		}
		/* FOLDED TO LOWER CASE FOR `countries.go`'s REASON, before this column
		   has a second writer rather than after. That one was grouped on the
		   raw string until the seeder's `BR` and the resolver's `br` had been
		   two countries on one map for three weeks, with nothing failing
		   anywhere. The lesson is cheap to apply in advance. */
		kind := strings.ToLower(strings.TrimSpace(h.Device))
		if kind == "" {
			// The column refuses an empty string, so this cannot come from the
			// database; it can come from a hand-built row in a test. Either way
			// it is the same thing `unknown` means.
			kind = Unknown
		}
		if byDevice[kind] == nil {
			byDevice[kind] = map[string]bool{}
		}
		byDevice[kind][person] = true
		everybody[person] = true
	}

	out := Held{People: len(everybody), Devices: make([]Device, 0, len(byDevice))}
	for kind, people := range byDevice {
		/* A PERSON IS A STUDENT WHEN `personOf` RESOLVED THEM TO AN ACCOUNT,
		   which that function writes into the key it returns. Reading the
		   prefix is reading its answer rather than deciding again — a second
		   test for "is this an account" is a second definition, and this file
		   would then be a conversion rate that disagrees with the funnel's. */
		students := 0
		for person := range people {
			if strings.HasPrefix(person, "account:") {
				students++
			}
		}
		out.Devices = append(out.Devices, Device{
			Kind: kind, People: len(people), Students: students,
		})
	}

	/* BIGGEST FIRST, AND THE NAME BREAKS THE TIE — the same ordering and the
	   same reason as the map: ranging over a Go map is deliberately unordered,
	   and a screen whose rows swap places between two identical requests looks
	   broken in a way nobody can reproduce. */
	sort.Slice(out.Devices, func(i, j int) bool {
		if out.Devices[i].People != out.Devices[j].People {
			return out.Devices[i].People > out.Devices[j].People
		}
		return out.Devices[i].Kind < out.Devices[j].Kind
	})
	return out, nil
}
