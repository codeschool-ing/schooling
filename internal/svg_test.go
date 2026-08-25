package internal_test

import (
	"bytes"
	"encoding/xml"
	"errors"
	"io"
	"testing"
)

/*
EVERY SVG IN THE REPOSITORY IS WELL-FORMED XML.

	A browser is lenient and will draw a file no strict parser accepts, so an
	invalid one renders perfectly everywhere anybody looks at it and is refused
	everywhere they do not.

	That is not hypothetical. `ui/assets/favicon.svg` shipped with a CSS custom
	property named in its comment, and A PAIR OF HYPHENS IS FORBIDDEN INSIDE AN
	XML COMMENT. Firefox drew it. So did the offline render these icons were
	compared in. GitHub, which parses strictly, answered "invalid image source" —
	and that is how it was found, by somebody clicking on the file.

	The readers that would refuse it are the ones that matter later: a strict
	renderer, a converter turning one into the PNG that older browsers still
	want, and anything that ever has to READ these rather than display them.

	IT WALKS THE WHOLE TREE and not one package's embed, because the icons live
	in two: the schools' are in `ui/assets` and the console's is in its own, and
	a check that knew about one would have missed the other.
*/
func TestEverySvgIsWellFormedXML(t *testing.T) {
	eachFile(t, ".svg", nil, func(rel, _ string, source []byte) {
		// The whole document, not the first element: a comment before the root
		// is exactly where the defect this catches lives.
		decoder := xml.NewDecoder(bytes.NewReader(source))
		for {
			_, err := decoder.Token()
			if errors.Is(err, io.EOF) {
				return
			}
			if err != nil {
				t.Errorf("%s is not well-formed XML: %v.\n\nA browser will draw it and a "+
					"strict parser will not, so it looks right everywhere it is looked at. "+
					"A pair of hyphens inside a comment is the usual cause", rel, err)
				return
			}
		}
	})
}
