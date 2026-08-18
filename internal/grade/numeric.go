package grade

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
)

/* ---------- numeric ---------- */

// numeric grades a number with a unit and a tolerance.
//
// PHYSICS AND CHEMISTRY DO NOT EXIST WITHOUT IT, and neither does an honest
// mathematics answer: 9.81 and 9.8100000001 are the same measurement, and a
// grader that compared them exactly would fail a student for having a different
// calculator.
//
// THE UNIT IS COMPARED AND NOT CONVERTED. `1000 m` and `1 km` are the same
// quantity and this marks the second wrong, deliberately: converting means a
// table of units, a table of prefixes, and a question about `km` that quietly
// accepts `m` — which is exactly the mistake a physics question is usually
// asking about. A question that will take either says so with `accept_units`.
type numeric struct{}

type numericPayload struct {
	common

	Value float64 `json:"value"`

	// The unit the answer must be in. Empty means the quantity has none —
	// a count, a ratio — and an answer carrying one is then wrong.
	Unit string `json:"unit"`

	// Other spellings of the same unit, for when `m/s^2` and `m/s²` are both
	// what somebody would type. NOT other units.
	AcceptUnits []string `json:"accept_units"`

	// How far off is still right. Absolute by default, because that is what a
	// question about a measurement means; relative when the magnitude varies.
	Tolerance float64 `json:"tolerance"`
	Relative  bool    `json:"relative"`
}

type numericAnswer struct {
	Value float64 `json:"value"`
	Unit  string  `json:"unit"`
}

func (numeric) grade(payload, answer json.RawMessage) (Result, error) {
	var p numericPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a numericAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	if math.IsNaN(a.Value) || math.IsInf(a.Value, 0) {
		return Result{}, fmt.Errorf("%w: %v is not a number anybody measured", ErrBadAnswer, a.Value)
	}

	if !unitMatches(p, a.Unit) {
		return Result{Correct: false}, nil
	}

	allowed := p.Tolerance
	if p.Relative {
		allowed = math.Abs(p.Value) * p.Tolerance
	}
	return Result{Correct: math.Abs(a.Value-p.Value) <= allowed}, nil
}

func unitMatches(p numericPayload, given string) bool {
	given = strings.TrimSpace(given)
	if given == strings.TrimSpace(p.Unit) {
		return true
	}
	for _, one := range p.AcceptUnits {
		if given == strings.TrimSpace(one) {
			return true
		}
	}
	return false
}

func (numeric) key(payload json.RawMessage) (json.RawMessage, error) {
	var p numericPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}

	switch {
	case math.IsNaN(p.Value) || math.IsInf(p.Value, 0):
		return nil, errors.New("the expected value is not a number")
	case p.Tolerance < 0:
		return nil, errors.New("a negative tolerance accepts nothing at all")
	case p.Relative && p.Value == 0:
		return nil, errors.New("a relative tolerance around zero accepts only zero, which makes " +
			"the tolerance a decoration")
	}

	return json.Marshal(numericAnswer{Value: p.Value, Unit: p.Unit})
}

/* ---------- labelling ---------- */

// labelling grades a label dropped on a point of an image.
//
// COORDINATES ARE FRACTIONS OF THE IMAGE, never pixels. The same question is
// answered on a phone and on a monitor, and a pixel is a different distance on
// each — so a question authored against one screen would be ungradable on the
// other, and nobody would find out until a student on a small screen could not
// pass it.
type labelling struct{}

type labellingPayload struct {
	common

	Image  string           `json:"image"`
	Labels []labellingLabel `json:"labels"`
}

type labellingLabel struct {
	Text string `json:"text"`

	// The centre of the region that counts, and how far from it still does.
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	Radius float64 `json:"radius"`
}

type labellingAnswer struct {
	// Placed[i] is where the student dropped label i.
	Placed []struct {
		X float64 `json:"x"`
		Y float64 `json:"y"`
	} `json:"placed"`
}

func (labelling) grade(payload, answer json.RawMessage) (Result, error) {
	var p labellingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a labellingAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	if len(a.Placed) != len(p.Labels) {
		return Result{}, fmt.Errorf("%w: it places %d labels and the question has %d",
			ErrBadAnswer, len(a.Placed), len(p.Labels))
	}

	for i, label := range p.Labels {
		dx := a.Placed[i].X - label.X
		dy := a.Placed[i].Y - label.Y
		if math.Sqrt(dx*dx+dy*dy) > label.Radius {
			return Result{Correct: false}, nil
		}
	}
	return Result{Correct: true}, nil
}

func (labelling) key(payload json.RawMessage) (json.RawMessage, error) {
	var p labellingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}

	if p.Image == "" {
		return nil, errors.New("a labelling question with no image labels nothing")
	}
	if len(p.Labels) == 0 {
		return nil, errors.New("no labels to place")
	}

	for i, label := range p.Labels {
		switch {
		case label.Text == "":
			return nil, fmt.Errorf("label %d has no text", i+1)
		case label.X < 0 || label.X > 1 || label.Y < 0 || label.Y > 1:
			return nil, fmt.Errorf("label %q sits at (%v, %v), which is outside the image — "+
				"coordinates are fractions of it, so that they mean the same on every screen",
				label.Text, label.X, label.Y)
		case label.Radius <= 0:
			return nil, fmt.Errorf("label %q has no radius, so only an exact hit counts and "+
				"nobody can produce one with a finger", label.Text)
		}

		// Two regions that overlap make a drop ambiguous: the student is right
		// and wrong at once, and which they get depends on the order the labels
		// happen to be in.
		for j := i + 1; j < len(p.Labels); j++ {
			other := p.Labels[j]
			dx, dy := label.X-other.X, label.Y-other.Y
			if math.Sqrt(dx*dx+dy*dy) < label.Radius+other.Radius {
				return nil, fmt.Errorf("the regions for %q and %q overlap — a drop inside both "+
					"is right and wrong at the same time", label.Text, other.Text)
			}
		}
	}

	answer := labellingAnswer{}
	for _, label := range p.Labels {
		answer.Placed = append(answer.Placed, struct {
			X float64 `json:"x"`
			Y float64 `json:"y"`
		}{X: label.X, Y: label.Y})
	}
	return json.Marshal(answer)
}
