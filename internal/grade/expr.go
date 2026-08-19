package grade

import (
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"unicode"
)

// A small expression language, and an evaluator for it.
//
// # WHY THIS EXISTS AT ALL
//
// `expression-answer` asks whether two expressions are the same thing. `2x+1`
// and `1+2x` are; `x^2` and `2x` are not, even though they agree at 0 and at 2.
// Deciding that by rearranging symbols is a computer algebra system, and a
// real one is a large dependency in the path that marks a student's exam.
//
// It is not needed. Two expressions over the reals are equal if they agree
// everywhere, and "everywhere" can be sampled: evaluate both at a spread of
// points and compare. Two different polynomials of degree n agree at most at n
// points, so a couple of dozen well-chosen ones settle it — and the failure
// direction is safe, because a student's WRONG answer would have to agree with
// the right one at every sample to be accepted.
//
// What it cannot do is simplify, factor or solve. It does not need to: the
// question is "are these equal", never "what is this".
//
// # WHAT IT ACCEPTS
//
// The arithmetic a school algebra question is written in: the four operations,
// powers, parentheses, unary minus, named functions, `pi` and `e`. And IMPLICIT
// MULTIPLICATION — `2x`, `3(x+1)`, `2 sin(x)` — because that is how a person
// writes algebra, and a grader that refused it would be marking notation.
//
// # WHAT IT REFUSES, AND WHY THAT IS THE IMPORTANT HALF
//
// Anything it does not understand is an error, never a guess. A parser that
// skipped a character it did not recognise would silently mark `x + y` and
// `x @ y` the same, and the student would be told they were right for a reason
// nobody could reconstruct.

// ErrBadExpression is something that is not an expression this understands.
var ErrBadExpression = errors.New("grade: that is not an expression")

/* ---------- the tree ---------- */

type node interface {
	// eval answers the value at one assignment of the variables, or an error
	// for a point where the expression has no value — a division by zero, the
	// square root of a negative. Those are POINTS TO SKIP rather than failures:
	// `1/x` is a perfectly good expression that is undefined at one place.
	eval(at map[string]float64) (float64, error)
}

// errUndefined is "no value here", which the sampler treats as a point to skip
// rather than as a broken expression.
var errUndefined = errors.New("grade: the expression has no value at that point")

type numberNode float64

func (n numberNode) eval(map[string]float64) (float64, error) { return float64(n), nil }

type varNode string

func (v varNode) eval(at map[string]float64) (float64, error) {
	x, ok := at[string(v)]
	if !ok {
		// A letter the question did not declare. It is refused rather than
		// treated as zero: an answer of `y` to a question about `x` is not an
		// answer that happens to be wrong, it is an answer about something else.
		return 0, fmt.Errorf("%w: %q is not one of this question's variables", ErrBadExpression, string(v))
	}
	return x, nil
}

type binaryNode struct {
	op          byte
	left, right node
}

func (b binaryNode) eval(at map[string]float64) (float64, error) {
	l, err := b.left.eval(at)
	if err != nil {
		return 0, err
	}
	r, err := b.right.eval(at)
	if err != nil {
		return 0, err
	}

	switch b.op {
	case '+':
		return l + r, nil
	case '-':
		return l - r, nil
	case '*':
		return l * r, nil
	case '/':
		if r == 0 {
			return 0, errUndefined
		}
		return l / r, nil
	case '^':
		// A negative base with a fractional exponent is not a real number, and
		// math.Pow answers NaN rather than saying so.
		if l < 0 && r != math.Trunc(r) {
			return 0, errUndefined
		}
		if l == 0 && r < 0 {
			return 0, errUndefined
		}
		return math.Pow(l, r), nil
	default:
		return 0, fmt.Errorf("%w: the operator %q", ErrBadExpression, string(b.op))
	}
}

type callNode struct {
	name string
	arg  node
}

func (c callNode) eval(at map[string]float64) (float64, error) {
	x, err := c.arg.eval(at)
	if err != nil {
		return 0, err
	}

	fn, ok := functions[c.name]
	if !ok {
		return 0, fmt.Errorf("%w: there is no function %q", ErrBadExpression, c.name)
	}
	out := fn(x)

	// A function outside its domain answers NaN or an infinity. Both are "no
	// value here" rather than a wrong answer.
	if math.IsNaN(out) || math.IsInf(out, 0) {
		return 0, errUndefined
	}
	return out, nil
}

// The functions a school algebra question is written with. A closed list: one
// that is not on it is an error, because a grader that quietly evaluated an
// unknown name to something would mark answers on a rule nobody wrote down.
var functions = map[string]func(float64) float64{
	"sqrt": math.Sqrt,
	"abs":  math.Abs,
	"exp":  math.Exp,
	"ln":   math.Log,
	"log":  math.Log10,
	"log2": math.Log2,
	"sin":  math.Sin,
	"cos":  math.Cos,
	"tan":  math.Tan,
	"asin": math.Asin,
	"acos": math.Acos,
	"atan": math.Atan,
	"sinh": math.Sinh,
	"cosh": math.Cosh,
	"tanh": math.Tanh,
}

// The constants. `e` is a constant and not a variable, which is why a question
// about a variable called `e` cannot be written — a limitation worth having,
// since an expression where `e` means two things is one nobody can read either.
var constants = map[string]float64{
	"pi": math.Pi,
	"e":  math.E,
}

/* ---------- reading one ---------- */

type parser struct {
	in  []rune
	at  int
	src string
}

// parse reads an expression, or says why it could not.
func parse(src string) (node, error) {
	p := &parser{in: []rune(src), src: src}

	p.spaces()
	if p.done() {
		return nil, fmt.Errorf("%w: it is empty", ErrBadExpression)
	}

	out, err := p.expression()
	if err != nil {
		return nil, err
	}

	p.spaces()
	if !p.done() {
		return nil, fmt.Errorf("%w: %q is left over at the end of %q",
			ErrBadExpression, string(p.in[p.at:]), src)
	}
	return out, nil
}

func (p *parser) done() bool { return p.at >= len(p.in) }

func (p *parser) spaces() {
	for !p.done() && unicode.IsSpace(p.in[p.at]) {
		p.at++
	}
}

func (p *parser) peek() rune {
	if p.done() {
		return 0
	}
	return p.in[p.at]
}

// expression := term (('+' | '-') term)*
func (p *parser) expression() (node, error) {
	left, err := p.term()
	if err != nil {
		return nil, err
	}

	for {
		p.spaces()
		op := p.peek()
		if op != '+' && op != '-' {
			return left, nil
		}
		p.at++

		right, err := p.term()
		if err != nil {
			return nil, err
		}
		left = binaryNode{op: byte(op), left: left, right: right}
	}
}

// term := power (('*' | '/' | implicit) power)*
func (p *parser) term() (node, error) {
	left, err := p.power()
	if err != nil {
		return nil, err
	}

	for {
		p.spaces()
		switch op := p.peek(); {
		case op == '*' || op == '/':
			p.at++
			right, err := p.power()
			if err != nil {
				return nil, err
			}
			left = binaryNode{op: byte(op), left: left, right: right}

		/* IMPLICIT MULTIPLICATION, which is how people write algebra. `2x`,
		   `3(x+1)`, `2 sin(x)`. Without it a grader marks notation rather than
		   mathematics — and a student who writes what their textbook writes is
		   told they are wrong.

		   It binds exactly as `*` does, which is the reading everybody expects:
		   `2x^2` is `2*(x^2)` because the power is inside `power`, and `1/2x`
		   is `(1/2)*x` because both are left-associative at this level. The
		   second is genuinely ambiguous in handwriting; this picks the reading
		   a calculator picks. */
		case startsAPower(op):
			right, err := p.power()
			if err != nil {
				return nil, err
			}
			left = binaryNode{op: '*', left: left, right: right}

		default:
			return left, nil
		}
	}
}

func startsAPower(r rune) bool {
	return unicode.IsDigit(r) || unicode.IsLetter(r) || r == '(' || r == '.'
}

// power := unary ('^' power)?   — right-associative, so `2^3^2` is `2^(3^2)`.
func (p *parser) power() (node, error) {
	left, err := p.unary()
	if err != nil {
		return nil, err
	}

	p.spaces()
	if p.peek() != '^' {
		return left, nil
	}
	p.at++

	right, err := p.power()
	if err != nil {
		return nil, err
	}
	return binaryNode{op: '^', left: left, right: right}, nil
}

// unary := ('-' | '+') unary | primary
func (p *parser) unary() (node, error) {
	p.spaces()

	switch p.peek() {
	case '-':
		p.at++
		inner, err := p.unary()
		if err != nil {
			return nil, err
		}
		return binaryNode{op: '-', left: numberNode(0), right: inner}, nil
	case '+':
		p.at++
		return p.unary()
	}
	return p.primary()
}

// primary := number | name ('(' expression ')')? | '(' expression ')'
func (p *parser) primary() (node, error) {
	p.spaces()
	if p.done() {
		return nil, fmt.Errorf("%w: it ends where a number or a name should be: %q",
			ErrBadExpression, p.src)
	}

	switch r := p.peek(); {
	case r == '(':
		p.at++
		inner, err := p.expression()
		if err != nil {
			return nil, err
		}
		p.spaces()
		if p.peek() != ')' {
			return nil, fmt.Errorf("%w: a bracket is not closed in %q", ErrBadExpression, p.src)
		}
		p.at++
		return inner, nil

	case unicode.IsDigit(r) || r == '.':
		return p.number()

	case unicode.IsLetter(r):
		return p.name()

	default:
		return nil, fmt.Errorf("%w: %q is not something this understands, in %q",
			ErrBadExpression, string(r), p.src)
	}
}

func (p *parser) number() (node, error) {
	start := p.at
	for !p.done() && (unicode.IsDigit(p.in[p.at]) || p.in[p.at] == '.') {
		p.at++
	}

	// An exponent, so `1e-9` reads as a number rather than as `1 * e - 9`.
	// It is only an exponent when a digit or a sign and a digit follow, which
	// is what keeps `2e` meaning two times Euler's number.
	if !p.done() && (p.in[p.at] == 'e' || p.in[p.at] == 'E') {
		if next := p.at + 1; next < len(p.in) {
			after := next
			if p.in[after] == '+' || p.in[after] == '-' {
				after++
			}
			if after < len(p.in) && unicode.IsDigit(p.in[after]) {
				p.at = after
				for !p.done() && unicode.IsDigit(p.in[p.at]) {
					p.at++
				}
			}
		}
	}

	text := string(p.in[start:p.at])
	value, err := strconv.ParseFloat(text, 64)
	if err != nil {
		return nil, fmt.Errorf("%w: %q is not a number", ErrBadExpression, text)
	}
	return numberNode(value), nil
}

func (p *parser) name() (node, error) {
	start := p.at
	for !p.done() && (unicode.IsLetter(p.in[p.at]) || unicode.IsDigit(p.in[p.at]) || p.in[p.at] == '_') {
		p.at++
	}
	name := strings.ToLower(string(p.in[start:p.at]))

	p.spaces()
	if p.peek() == '(' {
		if _, ok := functions[name]; !ok {
			return nil, fmt.Errorf("%w: there is no function %q", ErrBadExpression, name)
		}
		p.at++
		arg, err := p.expression()
		if err != nil {
			return nil, err
		}
		p.spaces()
		if p.peek() != ')' {
			return nil, fmt.Errorf("%w: %s( is not closed in %q", ErrBadExpression, name, p.src)
		}
		p.at++
		return callNode{name: name, arg: arg}, nil
	}

	if value, ok := constants[name]; ok {
		return numberNode(value), nil
	}

	// A function used without brackets — `sin x` — is a mistake worth naming,
	// because implicit multiplication would otherwise read it as `sin * x` and
	// then fail with "sin is not a variable", which points at the wrong thing.
	if _, ok := functions[name]; ok {
		return nil, fmt.Errorf("%w: %s needs brackets round what it applies to, as %s(x)",
			ErrBadExpression, name, name)
	}
	return varNode(name), nil
}
