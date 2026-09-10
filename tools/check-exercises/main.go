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
	"math/rand"
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

// LongestShareCeiling is how often the correct option may be the longest one
// before the length itself is the answer.
//
// IT IS A SHARE ACROSS A LESSON AND NOT A RULE PER QUESTION. One question whose
// correct option happens to be longest is nothing; a lesson where it is true of
// half of them is a lesson that can be passed with a ruler. The ceiling is set
// a little above what chance produces for four options — 0.25 — so that
// ordinary variation is not a failure and a habit is.
const LongestShareCeiling = 0.40

// GuessCeiling is how well the strategy below may score before the questions
// are measuring the wrong thing. A student who has not read anything should do
// no better than chance, and chance for these questions is about a third.
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
		body, err := os.ReadFile(f)
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
	longest, single := 0, 0
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

		// 1 · length
		if len(correct) == 1 && isLongest(e.Choices, correct[0]) {
			longest++
			single++
		} else if len(correct) == 1 {
			single++
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

	if single >= 6 && float64(longest)/float64(single) > LongestShareCeiling {
		problems = append(problems, fmt.Sprintf(
			"%s: the correct option is the longest in %d of %d single-answer questions (%.0f%%) — "+
				"over the %.0f%% ceiling, and a student can pass with a ruler",
			at, longest, single, float64(longest)/float64(single)*100, LongestShareCeiling*100))
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

	// And the whole point, measured end to end: what does the strategy score?
	if hit, total := guess(picked); total >= 8 {
		share := float64(hit) / float64(total)
		report = fmt.Sprintf("%s: reading nothing scores %d of %d (%.0f%%); chance is %.0f%%; "+
			"the correct option is longest in %d of %d (%.0f%%)",
			at, hit, total, share*100, chance(picked)*100,
			longest, single, float64(longest)/float64(single)*100)
		if share > GuessCeiling {
			problems = append(problems, fmt.Sprintf(
				"%s: a student who read nothing and picks the longest option without an absolute "+
					"scores %d of %d (%.0f%%), over the %.0f%% ceiling",
				at, hit, total, share*100, GuessCeiling*100))
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

func isLongest(cs []choice, i int) bool {
	for j, c := range cs {
		if j != i && len([]rune(c.Text)) >= len([]rune(cs[i].Text)) {
			return false
		}
	}
	return true
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

// guess scores the strategy the whole document is written against: pick the
// longest option that contains no absolute. It is only run over single-answer
// questions, because a strategy for choosing a SET is a different thing and
// this one would flatter itself.
func guess(exs []exercise) (hit, total int) {
	r := rand.New(rand.NewSource(1))
	for _, e := range exs {
		if e.Type != "quiz" || len(e.Choices) < 2 {
			continue
		}
		total++
		var candidates []int
		for i, c := range e.Choices {
			if !absolutes.MatchString(c.Text) {
				candidates = append(candidates, i)
			}
		}
		if len(candidates) == 0 {
			candidates = []int{r.Intn(len(e.Choices))}
		}
		best := candidates[0]
		for _, i := range candidates {
			if len([]rune(e.Choices[i].Text)) > len([]rune(e.Choices[best].Text)) {
				best = i
			}
		}
		if e.Choices[best].Correct {
			hit++
		}
	}
	return
}
