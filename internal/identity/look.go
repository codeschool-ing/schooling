package identity

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

/* Looking for somebody whose address you cannot reproduce exactly.

   # THIS IS WHAT K-22 REFUSED UNTIL IT WAS AMENDED

   `ByEmail` answers "this person who wrote to me, are they here?" and answers
   nothing else — that was the whole console for as long as K-22 stood as
   written. The case it never handled is the ordinary one: somebody writes in
   from an address that is not the one they signed up with, or signs their
   e-mail with a surname and nothing else, and the operator is left guessing
   spellings at a form that only answers yes or no.

   The amendment is in `docs/PLAN.md` and the argument is in
   `internal/console/people.go`. What this file owes it is the query, and the
   query has two properties the decision rests on:

     IT IS BOUNDED. A page, and a page is a number this file sets rather than a
     number a request asks for. There is no "give me everybody" here, because a
     listing whose size the caller chooses is an export with no audit entry.

     IT IS THE MINIMUM THAT IDENTIFIES. A name, an address, when they arrived,
     and whether they are seeded. Not their country, not their locale, not what
     they have studied — that is the record, one person at a time, and the
     export is what hands over the rest with an entry against it (K-20).
*/

// Sought is one person as a listing shows them.
//
// IT IS THE SAME FOUR FIELDS `console.Person` CARRIES, and that is not a
// coincidence to be tidied away: what a screen may show about somebody it has
// not been asked about is exactly what it may show about somebody it has. A
// listing that revealed one field more than a lookup would be the place where
// the difference between the two stopped being about HOW MANY people and
// started being about how much.
type Sought struct {
	ID        uuid.UUID
	Name      string
	Email     string
	CreatedAt time.Time
	Synthetic bool
}

// Look is a page of people.
type Look struct {
	// Words is matched as a substring against the address and the name, case
	// insensitively. Empty is everybody, newest first.
	Words string

	// Where the previous page ended. Both, or neither: `created_at` is not
	// unique, and paging on it alone puts two accounts made in the same
	// millisecond on both pages or on neither.
	Before   time.Time
	BeforeID uuid.UUID
}

// Page is how many come back at once.
//
// IT IS A CONSTANT AND NOT A PARAMETER. A caller who chooses the page size
// chooses it once, at ten thousand, and the listing becomes the export that
// nothing recorded — while the screen's own audit entry says one read happened.
// Fifty is a screen's worth: enough that scrolling answers "is the person I
// want here", short enough that reaching everybody is a deliberate number of
// deliberate acts, each of them counted.
const Page = 50

/*
Look answers one page of people, newest first.

	KEYSET AND NOT OFFSET. People sign up while somebody is reading, and an
	OFFSET page moves under them — the row that was 50th is 51st a moment later,
	so paging with offsets shows one person twice and skips another. The pair
	(created_at, id) is the whole order, and the next page asks for what sorts
	strictly after the last row of this one.

	AN EMPTY `Words` IS EVERYBODY and is not a mistake to refuse. "Who has signed
	up this week" is a legitimate question with no search term in it, and forcing
	one would mean typing a letter and calling the result a search.
*/
func (s *Store) Look(ctx context.Context, in Look) ([]Sought, error) {
	words := strings.TrimSpace(in.Words)

	/* THE PATTERN IS BUILT HERE AND THE WILDCARDS ARE OURS. `%` and `_` in what
	   somebody typed are escaped, so an address containing a per cent sign is
	   searchable and a stray one is not silently a wildcard — which would make
	   `%` on its own the "give me everybody" this page size exists to prevent
	   from being one keystroke. */
	pattern := "%" + like(strings.ToLower(words)) + "%"

	// The first page has no cursor, and a zero time with a nil id says so —
	// which is a state rather than a value, so the SQL asks for it as one.
	first := in.Before.IsZero()

	rows, err := s.pool.Query(ctx, `
		SELECT id, name, email, created_at, synthetic
		FROM accounts
		WHERE ($1 = '' OR lower(email) LIKE $2 ESCAPE '\' OR lower(name) LIKE $2 ESCAPE '\')
		  AND ($3::boolean OR (created_at, id) < ($4::timestamptz, $5::uuid))
		ORDER BY created_at DESC, id DESC
		LIMIT $6
	`, words, pattern, first, in.Before, in.BeforeID, Page)
	if err != nil {
		return nil, fmt.Errorf("identity: looking for people: %w", err)
	}
	defer rows.Close()

	out := make([]Sought, 0, Page)
	for rows.Next() {
		var one Sought
		if err := rows.Scan(&one.ID, &one.Name, &one.Email,
			&one.CreatedAt, &one.Synthetic); err != nil {

			return nil, fmt.Errorf("identity: reading a person: %w", err)
		}
		out = append(out, one)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("identity: looking for people: %w", err)
	}
	return out, nil
}

// like escapes what LIKE would otherwise read as a wildcard, so a search is a
// search for the characters somebody typed.
func like(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, "%", `\%`)
	return strings.ReplaceAll(s, "_", `\_`)
}
