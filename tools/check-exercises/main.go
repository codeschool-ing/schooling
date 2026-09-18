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
)

// The words that make an option look wrong to somebody who has learned how
// questions are written. An absolute in a distractor is the oldest tell there
// is, and the mirror — hedges concentrated in the correct option — is the same
// leak from the other side.
var (
	absolutes = regexp.MustCompile(`(?i)\b(never|always|only|all|must|none|every|cannot|nothing|no one)\b`)
	hedges    = regexp.MustCompile(`(?i)\b(usually|often|can|may|tends? to|generally|sometimes|typically)\b`)
	rareWord  = regexp.MustCompile(`(?i)[a-z]{6,}`)
	aboveAll  = regexp.MustCompile(`(?i)\b(all|none) of the above\b`)
)

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
	lessons := 0
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
		found, line := checkLesson(where(f), exs)
		problems = append(problems, found...)
		if line != "" {
			report = append(report, line)
		}
	}

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
		fmt.Printf("\n%d problem(s) across %d lesson(s). A tell is not a style note: it is a "+
			"student passing without reading.\n", len(problems), lessons)
		os.Exit(1)
	}
	fmt.Printf("%d lesson(s), no tell above its threshold\n", lessons)
}

func where(f string) string {
	parts := strings.Split(filepath.ToSlash(f), "/")
	if len(parts) >= 3 {
		return strings.Join(parts[len(parts)-4:len(parts)-1], "/")
	}
	return f
}

func checkLesson(at string, exs []exercise) (problems []string, report string) {
	var picked []exercise
	single, ranked := 0, 0
	byRank := map[int]int{}
	position := map[int]int{}

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

		// 2 · absolutes in the wrong options, hedges in the right one
		var absWrong, absRight int
		for _, i := range wrong {
			if absolutes.MatchString(e.Choices[i].Text) {
				absWrong++
			}
		}
		for _, i := range correct {
			if absolutes.MatchString(e.Choices[i].Text) {
				absRight++
			}
		}
		if absWrong > 0 && absRight == 0 && len(wrong) > 0 {
			problems = append(problems, fmt.Sprintf(
				"%s/%s puts an absolute (never/always/only/…) in %d of its %d wrong options and "+
					"none in the right one — eliminating them is a strategy that works without "+
					"the lesson", at, e.ID, absWrong, len(wrong)))
		}
		if len(correct) == 1 && hedges.MatchString(e.Choices[correct[0]].Text) {
			hedged := 0
			for _, i := range wrong {
				if hedges.MatchString(e.Choices[i].Text) {
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
			if aboveAll.MatchString(c.Text) {
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
	if name, hit, total := guess(picked); total >= 8 {
		share := float64(hit) / float64(total)
		worst, worstShare := bestRank(byRank, ranked)
		report = fmt.Sprintf("%s: reading nothing scores %d of %d (%.0f%%) by picking %s; "+
			"chance is %.0f%%; the correct option is %s in %.0f%% of the %d questions whose "+
			"options differ in length",
			at, hit, total, share*100, name, chance(picked)*100,
			nameRank(worst), worstShare*100, ranked)
		if share > GuessCeiling {
			problems = append(problems, fmt.Sprintf(
				"%s: a student who read nothing and picks %s scores %d of %d (%.0f%%), over the "+
					"%.0f%% ceiling", at, name, hit, total, share*100, GuessCeiling*100))
		}
	}

	return problems, report
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
	pick func(cs []choice) int
}{
	{"the longest option without an absolute", pickLongestClean},
	{"the longest option", func(cs []choice) int { return byLength(cs, 0) }},
	{"the shortest option", func(cs []choice) int { return byLength(cs, len(cs)-1) }},
	{"the second-longest option", func(cs []choice) int { return byLength(cs, 1) }},
}

func guess(exs []exercise) (name string, hit, total int) {
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
			if e.Choices[s.pick(e.Choices)].Correct {
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
func pickLongestClean(cs []choice) int {
	var candidates []int
	for i, c := range cs {
		if !absolutes.MatchString(c.Text) {
			candidates = append(candidates, i)
		}
	}
	if len(candidates) == 0 {
		return byLength(cs, 0)
	}
	best := candidates[0]
	for _, i := range candidates {
		if len([]rune(cs[i].Text)) > len([]rune(cs[best].Text)) {
			best = i
		}
	}
	return best
}
