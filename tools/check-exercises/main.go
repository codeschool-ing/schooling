// Command check-exercises reads a question the way a student who did not study
// reads it.
//
// IT MEASURES TELLS, NOT KNOWLEDGE. `validate-content` already asks whether a
// question is well formed and whether its key grades — this asks the different
// question of whether the key can be found WITHOUT the material. The two are
// unrelated failures: a perfectly formed question whose correct option is
// always the longest is a question that measures reading habits.
//
// WHY IT IS A SEPARATE TOOL. `validate-content` refuses a catalogue that is
// broken. This one refuses a catalogue that is sound and too easy, which is a
// judgement with thresholds in it — and thresholds belong somewhere a person
// can find and argue with rather than buried in the loader.
//
// The tells it can see are in `docs/EXERCISES.md`, in a table that says which
// are checkable. Furniture and convergence are not among them: no machine can
// tell an option nobody believes from an option somebody does, and that is why
// the document is longer than this program.
//
//	check-exercises [directory]     (default: content/)
//
// An absent directory is not a failure, for the same reason it is not one in
// `validate-content`: the system is finished before the content is written.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// The words that make an option look wrong to somebody who has learned how
// questions are written. An absolute in a distractor is the oldest tell there
// is, and the mirror — hedges concentrated in the correct option — is the same
// leak from the other side.
//
// A tell is a property of the words a student reads, so the words this tool
// knows have to be the words in front of them.
//
// THE LISTS WERE ENGLISH AND THE CATALOGUE IS NOT. `docs/EXERCISES.md` said so
// in as many words — "the day a question is authored in Portuguese, three of
// the checkable rows score zero and the run still says no tell above its
// threshold, which is worse than not running, because it answers with
// confidence". That was written as a known limit and it was already true: every
// lesson here ships a `exercises.pt.json`, and it is the file most of these
// students actually read.
//
// EACH LIST IS THE OTHER ONE TRANSLATED, NOT A SECOND JUDGEMENT. Word for word:
// never → nunca, only → somente/apenas/só, all → todo/todos, none → nenhum,
// cannot → não pode, no one → ninguém. Writing a longer Portuguese list because
// Portuguese has more ways to overclaim would make the two languages measure
// different things, and a lesson would then pass or fail on which half of the
// file somebody edited.
//
// A LOCALE WITH NO LIST IS REFUSED RATHER THAN MEASURED HALFWAY. Three of the
// checkable rows would score zero and the run would still print a number, which
// is the exact failure the paragraph above describes. So `unknownLocale` is a
// problem with the words to write in it, raised on the day somebody adds the
// third language — which is the day somebody is already thinking about it.
type language struct {
	absolutes *regexp.Regexp
	hedges    *regexp.Regexp
	aboveAll  *regexp.Regexp

	// Forms where an absolute CONTAINS a hedge, blanked before the hedge is
	// looked for. English splits them into two words — `can` and `cannot` — and
	// Portuguese does not: `não pode` carries `pode` inside it, and without this
	// every refusal in the catalogue would be reported as a hedge. A check that
	// fires on the commonest phrase in the language is one nobody reads twice.
	negations *regexp.Regexp
}

var languages = map[string]*language{
	"en": {
		absolutes: anyOf("never", "always", "only", "all", "must", "none", "every", "cannot", "nothing", "no one"),
		hedges: anyOf("usually", "often", "frequently", "can", "may", "tends to", "tend to",
			"generally", "sometimes", "typically"),
		aboveAll: anyOf("all of the above", "none of the above"),
	},
	"pt": {
		absolutes: anyOf("nunca", "jamais", "sempre", "somente", "apenas", "só", "todo", "toda", "todos", "todas",
			"nenhum", "nenhuma", "nada", "ninguém", "deve", "devem", "não pode", "não podem", "impossível"),
		hedges: anyOf("geralmente", "normalmente", "em geral", "frequentemente", "muitas vezes", "pode", "podem",
			"tende a", "tendem a", "costuma", "costumam", "às vezes", "tipicamente"),
		aboveAll: anyOf("todas as anteriores", "nenhuma das anteriores", "todas as acima", "nenhuma das acima",
			"todas as alternativas acima", "nenhuma das alternativas acima"),
		negations: anyOf("não pode", "não podem", "não é possível"),
	},
}

// anyOf builds the pattern that matches any of them as a whole word.
//
// IT IS NOT `\b`, AND THAT IS NOT A STYLE CHOICE. Go's `\b` is ASCII, so `\bsó\b`
// never matches: `ó` is not a word character to it, and the boundary it wants
// after the word is therefore already there before it. The tool would have
// reported a clean lesson for every Portuguese absolute carrying an accent — one
// of the four ways this could have been half-built and looked finished.
func anyOf(list ...string) *regexp.Regexp {
	const edge = `[^\p{L}\p{N}_]`
	quoted := make([]string, len(list))
	for i, w := range list {
		quoted[i] = regexp.QuoteMeta(w)
	}
	return regexp.MustCompile(`(?i)(?:^|` + edge + `)(?:` + strings.Join(quoted, "|") + `)(?:$|` + edge + `)`)
}

// hedged answers whether the text hedges, having first removed the absolutes
// that contain a hedge word — see `language.negations`.
func (l *language) hedged(s string) bool {
	if l.negations != nil {
		s = l.negations.ReplaceAllString(s, " ")
	}
	return l.hedges.MatchString(s)
}

// rareWord counts a long word, which is the proxy `docs/EXERCISES.md` row 6
// admits to. It is `\p{L}` rather than `[a-z]` so that `instalação` is one word
// and not `instala` — the ASCII class cut every accented word short and made the
// echo check measure a different thing in each language.
var rareWord = regexp.MustCompile(`\p{L}{6,}`)

type choice struct {
	Text    string `json:"text"`
	Correct bool   `json:"correct"`
}

type exercise struct {
	ID         string   `json:"id"`
	Section    string   `json:"section"`
	Type       string   `json:"type"`
	Difficulty string   `json:"difficulty"`
	Prompt     string   `json:"prompt"`
	Choices    []choice `json:"choices"`
}

// RankShareCeiling is how often the correct option may sit at any ONE rank by
// length — longest, second, third, shortest — before the ruler is the answer.
//
// IT IS A SHARE ACROSS A LESSON AND NOT A RULE PER QUESTION. One question whose
// correct option happens to be longest is nothing; a lesson where it is true of
// half of them is a lesson that can be passed with a ruler. The ceiling is set
// a little above what chance produces for four options — 0.25 — so that
// ordinary variation is not a failure and a habit is.
//
// IT REPLACED A ONE-DIRECTIONAL CHECK, and that is the whole point of it.
// `docs/EXERCISES.md` row 1 has always named the tell as LENGTH; the constant
// here asked only whether the correct option was the LONGEST, and the code
// narrowed what the document said. A lesson whose correct option is reliably
// the SHORTEST is passed with the same ruler held the other way up, and three
// lessons of this catalogue shipped at 97%, 100% and 100% shortest with this
// tool calling them clean.
//
// The narrowing is worse than a blind spot, because it steers the repair.
// Trimming the correct option until it stops being longest does not remove the
// habit, it moves it: one such rewrite took a lesson from 39% longest to 0%,
// and to 90% SECOND-longest in the same pass. A number that only falls when
// the tell moves somewhere unmeasured is a number that rewards moving it.
//
// So the question this asks is not which end. It is whether length says
// anything at all.
//
// THE NUMBER IS 0.45 BECAUSE THE PEAK OF FOUR IS NOT THE MEAN OF ONE. Taking
// the largest of four shares inflates it even when nothing is wrong: simulating
// a lesson whose correct option lands at a uniformly random rank puts the
// median peak at 31–35% and the 95th percentile at 40–46%, depending on how
// many questions the lesson has. A ceiling of 0.40 would therefore fail about
// one clean lesson in twelve, and one short one in six — and a check that
// cries wolf teaches whoever reads it to skip the output that would one day
// name a real one. At 0.45 that falls to roughly one in fifty, and the
// catalogue this was written against separates cleanly: every lesson with a
// real habit sits at 48% or above, and the ones between 37% and 42% are noise.
//
// It is the same number as GuessCeiling, and for the same reason rather than by
// coincidence — picking the option at rank k scores exactly the share at rank
// k, so the two constants are one measurement seen from two directions.
const RankShareCeiling = 0.45

// GuessCeiling is how well the BEST of the strategies below may score before
// the questions are measuring the wrong thing. A student who has not read
// anything should do no better than chance, and chance for these questions is
// about a third.
//
// THE BEST OF THEM, RATHER THAN ONE OF THEM. A student does not use the rule
// this tool happens to imagine; they use whichever rule works on the paper in
// front of them, and they find it by trying. Scoring one strategy measures our
// imagination. Scoring the family and reporting its maximum measures the paper.
const GuessCeiling = 0.45

// MinimumChoices is the floor under a question's option count. Two options is a
// coin flip, which puts a score of 50% under a student who knows nothing — see
// `docs/EXERCISES.md`.
const MinimumChoices = 3

func main() {
	dir := "content"
	if len(os.Args) > 1 {
		dir = os.Args[1]
	}
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		fmt.Printf("no %s yet, nothing to check\n", dir)
		return
	}

	files, err := filepath.Glob(filepath.Join(dir, "*", "courses", "*", "lessons", "*", "exercises.json"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	sort.Strings(files)

	var problems []string
	var report []string
	lessons, locales := 0, map[string]bool{}
	for _, f := range files {
		body, err := os.ReadFile(f) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			problems = append(problems, fmt.Sprintf("%s: %v", f, err))
			continue
		}
		var exs []exercise
		if err := json.Unmarshal(body, &exs); err != nil {
			problems = append(problems, fmt.Sprintf("%s: %v", f, err))
			continue
		}
		lessons++

		versions, err := everyLanguage(f, body, exs)
		if err != nil {
			problems = append(problems, fmt.Sprintf("%s: %v", f, err))
			continue
		}
		for _, v := range versions {
			locales[v.locale] = true
			at := fmt.Sprintf("%s [%s]", where(f), v.locale)
			if v.lang == nil {
				problems = append(problems, fmt.Sprintf(
					"%s: no word list for %q, so the absolutes, the hedges and \"all of the "+
						"above\" would score zero and the run would still print a number — add "+
						"%q to `languages` in this tool with the English list translated",
					at, v.locale, v.locale))
				continue
			}
			found, line := checkLesson(at, v.lang, v.exercises)
			problems = append(problems, found...)
			if line != "" {
				report = append(report, line)
			}
		}
	}
	sort.Strings(report)

	// The score is printed whether or not it is over the ceiling, because the
	// number is the evidence and "nothing to report" is only an assertion. A
	// lesson that moves from 48% to 30% is visible here and nowhere else.
	for _, r := range report {
		fmt.Println(r)
	}
	if len(report) > 0 && len(problems) > 0 {
		fmt.Println()
	}

	if len(problems) > 0 {
		fmt.Println("questions that can be answered without the material:")
		for _, p := range problems {
			fmt.Println(" - " + p)
		}
		fmt.Printf("\n%d problem(s) across %d lesson(s) in %d language(s). A tell is not a "+
			"style note: it is a student passing without reading.\n",
			len(problems), lessons, len(locales))
		os.Exit(1)
	}
	fmt.Printf("%d lesson(s) in %d language(s), no tell above its threshold\n", lessons, len(locales))
}

// version is one lesson's questions as one language's students read them.
type version struct {
	locale    string
	lang      *language
	exercises []exercise
}

// everyLanguage answers the lesson in English and in each `exercises.<locale>.json`
// beside it.
//
// THE MERGE IS `catalog.Translated` AND NOT A SECOND ONE WRITTEN HERE. The
// mirror holds a complete payload per locale because merging in every reader is
// how a screen ends up half translated; a checker with its own merge is a reader
// that would have drifted the same way, and it would drift towards passing —
// a field this tool forgot to take from the translation is a field it measures
// in English while the student reads Portuguese.
//
// A LESSON WITH NO TRANSLATION IS ONE VERSION, NOT A FAILURE. Whether every
// question is translated is `validate-content`'s question and it asks it
// already; this tool has nothing to say about a file that is not there.
func everyLanguage(f string, body []byte, exs []exercise) ([]version, error) {
	out := []version{{locale: "en", lang: languages["en"], exercises: exs}}

	var raws []json.RawMessage
	if err := json.Unmarshal(body, &raws); err != nil {
		return nil, err
	}

	dir := filepath.Dir(f)
	others, err := filepath.Glob(filepath.Join(dir, "exercises.*.json"))
	if err != nil {
		return nil, err
	}
	sort.Strings(others)

	for _, o := range others {
		locale := strings.TrimSuffix(strings.TrimPrefix(filepath.Base(o), "exercises."), ".json")
		lang, known := languages[locale]
		if !known {
			out = append(out, version{locale: locale})
			continue
		}
		translated, err := os.ReadFile(o) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			return nil, err
		}
		var text map[string]catalog.ExerciseText
		if err := json.Unmarshal(translated, &text); err != nil {
			return nil, fmt.Errorf("%s: %w", filepath.Base(o), err)
		}
		read := make([]exercise, 0, len(raws))
		for i, raw := range raws {
			t, ok := text[exs[i].ID]
			if !ok {
				read = append(read, exs[i])
				continue
			}
			merged, err := catalog.Translated(raw, t)
			if err != nil {
				return nil, fmt.Errorf("%s/%s: %w", filepath.Base(o), exs[i].ID, err)
			}
			var e exercise
			if err := json.Unmarshal(merged, &e); err != nil {
				return nil, fmt.Errorf("%s/%s: %w", filepath.Base(o), exs[i].ID, err)
			}
			read = append(read, e)
		}
		out = append(out, version{locale: locale, lang: lang, exercises: read})
	}
	return out, nil
}

func where(f string) string {
	parts := strings.Split(filepath.ToSlash(f), "/")
	if len(parts) >= 3 {
		return strings.Join(parts[len(parts)-4:len(parts)-1], "/")
	}
	return f
}

func checkLesson(at string, lang *language, exs []exercise) (problems []string, report string) {
	var picked []exercise
	single, ranked := 0, 0
	byRank := map[int]int{}
	position := map[int]int{}
	var absent skew

	for _, e := range exs {
		if e.Type != "quiz" && e.Type != "multiple-choice" {
			continue
		}
		picked = append(picked, e)

		if len(e.Choices) < MinimumChoices {
			problems = append(problems, fmt.Sprintf(
				"%s/%s has %d options — two is a coin flip, and a student who knows nothing "+
					"scores 50%%", at, e.ID, len(e.Choices)))
		}

		correct, wrong := split(e.Choices)

		// 1 · length, at either end and in the middle
		if len(correct) == 1 {
			single++
			if rank, unique := lengthRank(e.Choices, correct[0]); unique {
				ranked++
				byRank[rank]++
			}
		}

		// 2 · absolutes in the wrong options, counted across the lesson rather
		//     than refused per question — see `skew`
		for _, i := range wrong {
			absent.wrong++
			if lang.absolutes.MatchString(e.Choices[i].Text) {
				absent.inWrong++
			}
		}
		for _, i := range correct {
			absent.right++
			if lang.absolutes.MatchString(e.Choices[i].Text) {
				absent.inRight++
			}
		}
		if len(correct) == 1 && lang.hedged(e.Choices[correct[0]].Text) {
			hedged := 0
			for _, i := range wrong {
				if lang.hedged(e.Choices[i].Text) {
					hedged++
				}
			}
			if hedged == 0 {
				problems = append(problems, fmt.Sprintf(
					"%s/%s hedges (usually/often/can/…) only in the correct option — the mirror "+
						"of the absolutes tell", at, e.ID))
			}
		}

		// 6 · echo of the prompt's rare words
		if len(correct) == 1 && echoes(e.Prompt, e.Choices, correct[0]) {
			problems = append(problems, fmt.Sprintf(
				"%s/%s: the correct option repeats more of the prompt's uncommon words than any "+
					"other — the answer can be matched rather than known", at, e.ID))
		}

		// 8 · all/none of the above
		for _, c := range e.Choices {
			if lang.aboveAll.MatchString(c.Text) {
				problems = append(problems, fmt.Sprintf(
					"%s/%s uses \"all/none of the above\", which is answerable from one option "+
						"a student is sure about", at, e.ID))
				break
			}
		}

		// 9 · position
		if len(correct) == 1 {
			position[correct[0]]++
		}
	}

	if ranked >= 6 {
		ranks := make([]int, 0, len(byRank))
		for r := range byRank {
			ranks = append(ranks, r)
		}
		sort.Ints(ranks)
		for _, r := range ranks {
			if share := float64(byRank[r]) / float64(ranked); share > RankShareCeiling {
				problems = append(problems, fmt.Sprintf(
					"%s: the correct option is %s in %d of %d questions where the options differ "+
						"in length (%.0f%%) — over the %.0f%% ceiling, and a student can pass "+
						"with a ruler",
					at, nameRank(r), byRank[r], ranked, share*100, RankShareCeiling*100))
			}
		}
	}

	if n := len(picked); n >= 6 {
		for at2, count := range position {
			if float64(count)/float64(n) > 0.6 {
				problems = append(problems, fmt.Sprintf(
					"%s: the correct option sits at position %d in %d of %d questions — the "+
						"place is the answer", at, at2+1, count, n))
			}
		}
	}

	// And the whole point, measured end to end: what does the best of them score?
	if name, hit, total := guess(lang, picked); total >= 8 {
		share := float64(hit) / float64(total)
		worst, worstShare := bestRank(byRank, ranked)
		report = fmt.Sprintf("%s: reading nothing scores %d of %d (%.0f%%) by picking %s; "+
			"chance is %.0f%%; the correct option is %s in %.0f%% of the %d questions whose "+
			"options differ in length%s",
			at, hit, total, share*100, name, chance(picked)*100,
			nameRank(worst), worstShare*100, ranked, absent.String())
		if share > GuessCeiling {
			problems = append(problems, fmt.Sprintf(
				"%s: a student who read nothing and picks %s scores %d of %d (%.0f%%), over the "+
					"%.0f%% ceiling", at, name, hit, total, share*100, GuessCeiling*100))
		}
	}

	return problems, report
}

/*
skew is how much more often an absolute sits in a wrong option than in a right
one, across a whole lesson.

IT REPLACED A REFUSAL PER QUESTION, and the measurement is why. The rule used to
fail any question with an absolute among its distractors and none in its key,
which reads as the row-2 tell and is not it: the words are also the ordinary
vocabulary of a short factual answer. Run over this catalogue's Portuguese for
the first time it raised 156 of them, and they were `Nada, sem saber do disco`,
`Nenhum — a versão é antiga demais para ter suporte`, `Nunca, porque os dois
campos de dia se contradizem`. Correct answers, all three, and each one the whole
answer.

THE TELL IS A HABIT AND A HABIT IS A RATE. If absolutes are written without
regard to which option is correct, the rate in the wrong options and the rate in
the right ones are the same number; the tell is the gap between them. Over the
57 lesson-languages here with enough absolutes to measure at all, the largest gap
is five points and most are NEGATIVE — the keys carry them slightly more often.
There was no habit to find, in either language, and 156 sentences were being
asked to change to hide a word.

It is the same amendment `RankShareCeiling` already carries, for the same reason
and stated in `docs/EXERCISES.md` row 1: one question whose correct option
happens to be longest is nothing, and one distractor saying `never` is nothing.

WHICH LEAVES THE REFUSAL SOMEWHERE BETTER. Eliminating the absolutes is a
STRATEGY, and a strategy is scored end to end against `GuessCeiling` rather than
guessed at per question — `pickLongestClean` has always been in the family and
`pickShortestClean` is its mirror, added here so that elimination is measured at
both ends of the ruler rather than only the end the tool imagined. A lesson whose
distractors all overclaim is a lesson where those two score near 100%, which
fails, and says so with a number.

So this prints and does not refuse. The number is the evidence; the verdict is
the score above it.
*/
type skew struct {
	wrong, inWrong int
	right, inRight int
}

func (s skew) String() string {
	if s.inWrong+s.inRight == 0 || s.wrong == 0 || s.right == 0 {
		return ""
	}
	return fmt.Sprintf("; an absolute sits in %.0f%% of the wrong options and %.0f%% of the "+
		"right ones", float64(s.inWrong)/float64(s.wrong)*100, float64(s.inRight)/float64(s.right)*100)
}

// chance is what pure guessing scores on these questions, which is the number
// the strategy has to be compared against. It is not a constant, because a
// lesson's option counts vary and so does the floor they put under a student.
func chance(exs []exercise) float64 {
	sum, n := 0.0, 0
	for _, e := range exs {
		if e.Type != "quiz" || len(e.Choices) == 0 {
			continue
		}
		sum += 1 / float64(len(e.Choices))
		n++
	}
	if n == 0 {
		return 0
	}
	return sum / float64(n)
}

func split(cs []choice) (correct, wrong []int) {
	for i, c := range cs {
		if c.Correct {
			correct = append(correct, i)
		} else {
			wrong = append(wrong, i)
		}
	}
	return
}

// lengthRank is how many options are strictly longer than the one at i, and
// whether i's length is its own among the options.
//
// A TIE IS NOT A TELL, so a question where the correct option shares its length
// with another is counted at no rank at all. A ruler cannot separate two
// options of the same length, and a question whose four options are all one
// length is the ideal rather than a failure — this catalogue has one written
// that way on purpose, and the old check counted it as a habit.
func lengthRank(cs []choice, i int) (rank int, unique bool) {
	n := len([]rune(cs[i].Text))
	unique = true
	for j, c := range cs {
		if j == i {
			continue
		}
		switch m := len([]rune(c.Text)); {
		case m > n:
			rank++
		case m == n:
			unique = false
		}
	}
	return rank, unique
}

func nameRank(r int) string {
	switch r {
	case 0:
		return "the longest"
	case 1:
		return "the second-longest"
	case 2:
		return "the third-longest"
	}
	return fmt.Sprintf("%dth by length", r+1)
}

// bestRank is the rank the correct option lands on most often, which is the one
// a reader of the report wants named.
func bestRank(byRank map[int]int, ranked int) (rank int, share float64) {
	if ranked == 0 {
		return 0, 0
	}
	ranks := make([]int, 0, len(byRank))
	for r := range byRank {
		ranks = append(ranks, r)
	}
	sort.Ints(ranks)
	for _, r := range ranks {
		if s := float64(byRank[r]) / float64(ranked); s > share {
			rank, share = r, s
		}
	}
	return rank, share
}

func echoes(prompt string, cs []choice, i int) bool {
	want := words(prompt)
	if len(want) == 0 {
		return false
	}
	best, mine := 0, overlap(want, words(cs[i].Text))
	for j, c := range cs {
		if j == i {
			continue
		}
		if n := overlap(want, words(c.Text)); n > best {
			best = n
		}
	}
	return mine > best && mine >= 2
}

func words(s string) map[string]bool {
	out := map[string]bool{}
	for _, w := range rareWord.FindAllString(s, -1) {
		out[strings.ToLower(w)] = true
	}
	return out
}

func overlap(a, b map[string]bool) int {
	n := 0
	for w := range b {
		if a[w] {
			n++
		}
	}
	return n
}

// guess scores the family of strategies a student who did not study can reach
// for, and returns the best of them by name.
//
// IT IS ONLY RUN OVER SINGLE-ANSWER QUESTIONS, because a strategy for choosing
// a SET is a different thing and this one would flatter itself.
//
// EACH IS DETERMINISTIC, and that is the point rather than a shortcut. A student
// reading tells is not rolling dice — they apply the rule and get one answer —
// so the score has to be reproducible or a lesson would pass on one run and
// fail on the next.
//
// THE FAMILY IS SMALL ON PURPOSE. Every strategy here is one a person could
// arrive at by sitting two papers and noticing something: the long answer, the
// short answer, the long answer that does not overclaim, the one just under the
// longest. Adding strategies until something scores would turn this into a
// search for an accusation, and the number it reported would only ever rise.
var strategies = []struct {
	name string
	pick func(lang *language, cs []choice) int
}{
	{"the longest option without an absolute", pickLongestClean},
	{"the shortest option without an absolute", pickShortestClean},
	{"the longest option", func(_ *language, cs []choice) int { return byLength(cs, 0) }},
	{"the shortest option", func(_ *language, cs []choice) int { return byLength(cs, len(cs)-1) }},
	{"the second-longest option", func(_ *language, cs []choice) int { return byLength(cs, 1) }},
}

func guess(lang *language, exs []exercise) (name string, hit, total int) {
	var single []exercise
	for _, e := range exs {
		if e.Type == "quiz" && len(e.Choices) >= 2 {
			single = append(single, e)
		}
	}
	total = len(single)
	if total == 0 {
		return "", 0, 0
	}
	for _, s := range strategies {
		n := 0
		for _, e := range single {
			if e.Choices[s.pick(lang, e.Choices)].Correct {
				n++
			}
		}
		if n > hit || name == "" {
			name, hit = s.name, n
		}
	}
	return name, hit, total
}

// byLength picks the option at position k of the options sorted longest first.
// Ties are broken by the order they were written in, so the answer does not
// move when two options happen to match.
func byLength(cs []choice, k int) int {
	order := make([]int, len(cs))
	for i := range cs {
		order[i] = i
	}
	sort.SliceStable(order, func(a, b int) bool {
		return len([]rune(cs[order[a]].Text)) > len([]rune(cs[order[b]].Text))
	})
	if k < 0 {
		k = 0
	}
	if k >= len(order) {
		k = len(order) - 1
	}
	return order[k]
}

// pickLongestClean is the rule `docs/EXERCISES.md` opens with: the longest
// option that does not say "never" or "always". Where every option carries an
// absolute the rule has nothing to eliminate, and it falls back to the half of
// it that still applies.
func pickLongestClean(lang *language, cs []choice) int {
	return pickClean(lang, cs, true)
}

// pickShortestClean is the same elimination with the ruler held the other way
// up, and it is here because the length checks learned this lesson first: a rule
// that only watches one end does not remove a habit, it moves it. Eliminating
// the absolutes and then taking the SHORTEST of what is left is the same student
// on a paper whose keys are bare — which is most of this catalogue, where the
// answer is a command or a name.
func pickShortestClean(lang *language, cs []choice) int {
	return pickClean(lang, cs, false)
}

func pickClean(lang *language, cs []choice, longest bool) int {
	var candidates []int
	for i, c := range cs {
		if !lang.absolutes.MatchString(c.Text) {
			candidates = append(candidates, i)
		}
	}
	if len(candidates) == 0 {
		if longest {
			return byLength(cs, 0)
		}
		return byLength(cs, len(cs)-1)
	}
	best := candidates[0]
	for _, i := range candidates {
		n, m := len([]rune(cs[i].Text)), len([]rune(cs[best].Text))
		if (longest && n > m) || (!longest && n < m) {
			best = i
		}
	}
	return best
}
