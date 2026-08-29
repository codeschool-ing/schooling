package analysis

import "context"

/*
Enough is `enough`, exposed while the tests are compiled.

	WHY IT IS NOT SIMPLY EXPORTED. What it answers is an internal decision — how
	many answers this store wants before it will say anything — and nothing
	outside this package has any business asking. Exporting it for a test would
	widen the surface permanently to check one guard.

	AND WHY IT IS WORTH REACHING FOR AT ALL. The guard's failure is the quiet
	kind: a wiring that answers two makes this platform quarantine questions on
	the evidence of two people, and every screen looks exactly as it does today
	— the verdict arrives with "minimum sample: 2" printed beside it, which is a
	label nobody reads as a warning. Proving it through `Run` would need a
	school, a stream and a transaction to check one comparison.

	This is `identity.CodeFor`'s arrangement, for the same reason it exists
	there: a test that cannot see the thing it is about is a test about
	something else.
*/
func (s *Store) Enough(ctx context.Context) int { return s.enough(ctx) }
