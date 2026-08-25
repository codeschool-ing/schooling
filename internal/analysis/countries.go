package analysis

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
)

/* Where the people are.

   # IT COUNTS PEOPLE THE WAY THE FUNNEL COUNTS THEM, AND THAT IS THE POINT

   Both go through `personOf` and the same visitor-to-account links. A map that
   counted identities while the funnel counted people would put two different
   totals on two screens of the same console, both correct by their own
   definition and neither reconcilable — which is worse than one of them being
   wrong, because there is nothing to fix.

   # A PERSON IN TWO COUNTRIES IS IN BOTH, AND THE ANSWER SAYS SO

   Somebody who studies at home and again on a trip appears in two countries,
   which is the honest answer to "where do people study from" and makes the
   countries add up to MORE than the number of people. That is not a rounding
   error to hide: it is what the number means, and a screen that showed only the
   bars would let somebody add them up and conclude there are more students than
   there are.

   So `People` comes back beside them — every person counted once, however many
   countries they were seen in — and the screen has both halves. It is the same
   rule as a threshold travelling with the number it produced (K-16).

   # AND `unknown` IS A COUNTRY ON THE LIST

   It is where every event before the database existed came from, and where
   everything a VPN touches will keep coming from. Dropping it would make the
   map look complete and make the percentages lies. It is the honest majority
   today and it is drawn like any other row, named for what it is. */

// Origins is the stream's reader, defined here and satisfied by the module that
// owns the rows.
type Origins func(ctx context.Context, tenantID uuid.UUID, since time.Time,
	who Counting) ([]Origin, error)

// Origin is one identity seen from one country.
type Origin struct {
	Country   string
	VisitorID *uuid.UUID
	AccountID *uuid.UUID
}

// Country is one row of the map.
type Country struct {
	// Code is ISO 3166-1 alpha-2, lower case — or `unknown`.
	Code string

	// People is how many distinct people were seen from it.
	People int
}

// Where is the whole answer.
type Where struct {
	Countries []Country

	// People is every person counted ONCE, whatever they were seen from. The
	// countries sum to at least this and usually to more.
	People int
}

// Countries answers where the people of one school were, over the population
// `who` names.
func (s *Store) Countries(ctx context.Context, tenantID uuid.UUID, since time.Time,
	who Counting) (Where, error) {

	if s.origins == nil || s.links == nil {
		return Where{}, fmt.Errorf("analysis: this store was built without the stream to read")
	}

	origins, err := s.origins(ctx, tenantID, since, who)
	if err != nil {
		return Where{}, fmt.Errorf("analysis: reading where people were: %w", err)
	}

	links, err := s.links(ctx)
	if err != nil {
		return Where{}, fmt.Errorf("analysis: reading which visitors belong to an account: %w", err)
	}

	// One set of people per country, and one set of all of them. The second is
	// not the sum of the first, and that is the whole reason it is kept.
	byCountry := map[string]map[string]bool{}
	everybody := map[string]bool{}

	for _, o := range origins {
		person := personOf(Reach{VisitorID: o.VisitorID, AccountID: o.AccountID}, links)
		if person == "" {
			// An event with neither identity on it. It happened, and there is
			// nobody to count it for — counting it as an anonymous person would
			// inflate whichever country it came from.
			continue
		}
		/* FOLDED TO LOWER CASE, BECAUSE THE COLUMN HAS MORE THAN ONE WRITER.
		   `platform/geo` lowercases; the seeder wrote `BR` for its first three
		   weeks. Grouping on the raw string made those two countries — one
		   drawn on the map with a flag and a name, one a bare code beside it —
		   and nothing failed anywhere. Rows written before the seeder was
		   fixed are still in the stream and always will be, so this is where it
		   is settled rather than in a migration nobody would run again. */
		country := strings.ToLower(strings.TrimSpace(o.Country))
		if country == "" {
			// The column refuses an empty string, so this cannot come from the
			// database; it can come from a hand-built row in a test. Either way
			// it is the same thing `unknown` means.
			country = Unknown
		}
		if byCountry[country] == nil {
			byCountry[country] = map[string]bool{}
		}
		byCountry[country][person] = true
		everybody[person] = true
	}

	out := Where{People: len(everybody), Countries: make([]Country, 0, len(byCountry))}
	for code, people := range byCountry {
		out.Countries = append(out.Countries, Country{Code: code, People: len(people)})
	}

	/* BIGGEST FIRST, AND THE NAME BREAKS THE TIE. Alphabetical would bury the
	   answer somewhere in the middle of the list; the tiebreaker exists because
	   ranging over a map is deliberately unordered in Go, and a screen whose
	   rows swap places between two identical requests looks broken in a way
	   nobody can reproduce. */
	sort.Slice(out.Countries, func(i, j int) bool {
		if out.Countries[i].People != out.Countries[j].People {
			return out.Countries[i].People > out.Countries[j].People
		}
		return out.Countries[i].Code < out.Countries[j].Code
	})
	return out, nil
}

// Unknown is the country of an event nobody could place. It is the same word
// `platform/geo` writes, spelled here because this package may not import it —
// and it is a country on the report rather than a row to drop.
const Unknown = "unknown"
