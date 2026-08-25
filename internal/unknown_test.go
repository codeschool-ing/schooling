package internal_test

import (
	"testing"

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/platform/geo"
)

/*
FOUR PACKAGES SPELL "NOBODY KNOWS WHERE" AND THEY HAVE TO AGREE.

	`platform/geo` writes the word onto the request. `event` puts it in the
	column. `analysis` groups by it and treats it as a country of its own.
	`console` sends it to the screen so the map can draw that row differently,
	because it is not a place.

	NONE OF THEM MAY IMPORT ANOTHER. `geo` is in platform and may reach nowhere;
	the other three are modules and modules do not import modules (X-02). So the
	word is written four times, and the only thing that can hold them together
	is a test outside all four — this file, for the same reason the privacy
	policy's table check lives out here.

	WHAT BREAKS IF THEY DRIFT IS SILENT. A `geo` that started writing `none`
	would produce a country called `none` in every report, sitting beside a
	country called `unknown` full of older events, both drawn as places, with
	nothing failing anywhere. The screen would keep working. It would just be
	answering a question nobody asked.
*/
func TestEverybodySpellsNobodyKnowsTheSameWay(t *testing.T) {
	const word = "unknown"

	for where, spelling := range map[string]string{
		"platform/geo": geo.Unknown,
		"event":        event.Unknown,
		"analysis":     analysis.Unknown,
		"console":      console.Unknown,
	} {
		if spelling != word {
			t.Errorf("%s calls it %q and everybody else calls it %q — a report would then "+
				"carry two countries for the one thing, both drawn as places, with nothing "+
				"failing", where, spelling, word)
		}
	}
}
