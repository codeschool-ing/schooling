// Command load writes the catalogue mirror from `content/`, and prunes what
// the files no longer carry.
//
// IT VALIDATES FIRST AND WRITES NOTHING IF ANYTHING IS WRONG. That is the whole
// design: the checker that stands in for the reviewer runs in CI, and this runs
// it again — because the gap between "CI was green on that commit" and "this is
// what is being loaded now" is exactly where a half-written catalogue reaches
// students. Refusing costs a deploy; loading a broken one costs a lesson that
// opens to nothing.
//
// ONE TRANSACTION FOR EVERYTHING, INCLUDING THE PRUNE. A load that failed
// halfway would leave a catalogue that is neither the old one nor the new one,
// with no way to say which courses a student can see. Rolled back, the previous
// catalogue keeps serving and nobody studying notices.
//
// PRUNING IS DELETION AND IT IS SAFE, because nothing a student did points at
// these rows: `practice_review.exercise_id` is text and deliberately unkeyed,
// so a question that leaves the catalogue leaves the history intact and
// orphaned — the same decision, for the same reason, as erasure.
//
//	load [directory]     (default: content/)
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"maps"
	"os"
	"path/filepath"
	"slices"
	"strconv"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/logs"
)

// A list of lines as the mirror wants it: never nil.
//
// A nil slice in Go marshals to SQL NULL, and both columns are NOT NULL — a
// course.json that simply omits `topics` would fail the insert rather than
// store nothing. Absent and empty are the same fact about a course, so they
// become the same row here rather than one being an error.
func lines(v []string) []string {
	if v == nil {
		return []string{}
	}
	return v
}

// A map's keys in an order, because Go's is deliberately not one. Two loads of
// the same file should write the same rows in the same order, so that a diff of
// the mirror is a diff of the catalogue and not of a hash seed.
func sorted[V any](m map[string]V) []string {
	return slices.Sorted(maps.Keys(m))
}

func main() {
	log := logs.New(os.Stdout)

	root := "content"
	if len(os.Args) > 1 {
		root = os.Args[1]
	}

	if err := run(context.Background(), log, root); err != nil {
		log.Error("the catalogue was not loaded", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, log *slog.Logger, root string) error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	info := build.Current()
	log.Info("loading", "version", info.Version, "commit", info.Commit, "from", root)

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	entries, err := os.ReadDir(root)
	if os.IsNotExist(err) {
		log.Info("nothing to load", "directory", root)
		return nil
	}
	if err != nil {
		return fmt.Errorf("reading %s: %w", root, err)
	}

	loaded := 0
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		if err := loadSchool(ctx, log, pool, filepath.Join(root, entry.Name())); err != nil {
			return err
		}
		loaded++
	}

	log.Info("the catalogue is loaded", "schools", loaded)
	return nil
}

func loadSchool(ctx context.Context, log *slog.Logger, pool *pgxpool.Pool, dir string) error {
	school, problems := catalog.Load(os.DirFS(dir))
	if school != nil {
		problems = append(problems, catalog.Validate(school)...)
	}
	if len(problems) > 0 {
		for _, p := range problems {
			log.Error("the catalogue is not coherent", "directory", dir, "problem", p.Error())
		}
		return fmt.Errorf("%s: %d problem(s), and nothing was written — a half-written "+
			"catalogue reaching a student costs more than a refused deploy", dir, len(problems))
	}

	tenantID, err := tenantOf(ctx, pool, school.ID)
	if err != nil {
		return err
	}

	err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		return write(ctx, tx, tenantID, school)
	})
	if err != nil {
		return fmt.Errorf("%s: %w", dir, err)
	}

	log.Info("loaded",
		"school", school.ID,
		"tracks", len(school.Tracks),
		"courses", len(school.Courses),
	)
	return nil
}

// tenantOf finds the school this catalogue belongs to.
//
// IT DOES NOT CREATE ONE. A school is an address, a domain mapping and a
// decision; a directory appearing in `content/` is none of those. Creating it
// here would mean a typo in a directory name silently becoming a school that
// answers at no address and shows up in every count.
func tenantOf(ctx context.Context, pool *pgxpool.Pool, slug string) (uuid.UUID, error) {
	var id uuid.UUID
	err := pool.QueryRow(ctx, `SELECT id FROM tenants WHERE slug = $1`, slug).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, fmt.Errorf(
			"there is no school called %q — a directory in content/ does not create one, "+
				"because a school is also an address and a domain mapping", slug)
	}
	if err != nil {
		return uuid.Nil, fmt.Errorf("looking for the school %q: %w", slug, err)
	}
	return id, nil
}

// write replaces one school's catalogue.
//
// DELETE THEN INSERT, inside the caller's transaction. An upsert plus a
// separate prune is two passes that can disagree about what "no longer there"
// means; deleting the school's rows and writing them again cannot. The
// catalogue is small — a few thousand rows — and this runs at deploy time, so
// the simplest thing that is obviously right wins.
//
// AND THE LIST IS ASSERTED AGAINST THE SCHEMA, because a catalogue table nobody
// adds here is not caught by reading this function. `catalog_videos` was added
// to the schema and not to this list, and what failed was a SECOND load
// colliding on a primary key — loud only because that table happens to have
// one. A table without a colliding key would simply have grown, one deploy at a
// time, with every row a copy of a row the files still carry.
var catalogueTables = []string{
	"catalog_exercise_text", "catalog_exercises",
	"catalog_images", "catalog_prose", "catalog_videos", "catalog_sections",
	"catalog_lessons",
	"catalog_course_topics", "catalog_course_requires", "catalog_courses",
	"catalog_course_topic_text", "catalog_course_text",
	"catalog_track_fork_text", "catalog_track_text",
	"catalog_track_links", "catalog_track_courses", "catalog_track_forks", "catalog_tracks",
}

func write(ctx context.Context, tx pgx.Tx, tenantID uuid.UUID, school *catalog.School) error {
	for _, table := range catalogueTables {
		// The table names come from this list and from nowhere else, so there
		// is no interpolation of anything a file could influence.
		if _, err := tx.Exec(ctx, "DELETE FROM "+table+" WHERE tenant_id = $1", tenantID); err != nil {
			return fmt.Errorf("clearing %s: %w", table, err)
		}
	}

	/* THIS JOB IS THE ONE PLACE THAT TRANSLATES A NAME INTO AN IDENTITY.

	   Inside `content/` everything refers to everything else by SLUG — a
	   course's `requires`, a track's `courses`, its `links`, its `continues`,
	   the school's order. That is what keeps a pull request readable: a
	   reviewer can see that `"requires": ["python"]` is right, and could not
	   see it of `["co-8k2p91xz"]`.

	   Past this function nothing speaks slugs. The mirror, the API and every
	   record of what a student did carry ids, so a slug is free to be rewritten
	   without moving anybody's work. It is a compiler's arrangement: names go
	   in, symbols come out.

	   A slug that resolves to nothing cannot reach here — `Validate` refuses a
	   reference to a course or track that is not there, and a catalogue that
	   does not pass is never written. */
	courseID := map[string]string{}
	for _, c := range school.Courses {
		courseID[c.Slug] = c.ID
	}
	trackID := map[string]string{}
	for _, t := range school.Tracks {
		trackID[t.Slug] = t.ID
	}

	for i, track := range school.Tracks {
		if _, err := tx.Exec(ctx, `
			INSERT INTO catalog_tracks
				(tenant_id, id, slug, name, goal, outcome, continues, position)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		`, tenantID, track.ID, track.Slug, track.Name, track.Goal, track.Outcome,
			trackID[track.Continues], i); err != nil {
			return fmt.Errorf("writing the track %s: %w", track.ID, err)
		}

		// The track in its other languages. Every field is a pointer and goes
		// in as it came: NULL where nobody translated it, which is what lets
		// the read fall back field by field (C-11) instead of losing a goal to
		// an empty string.
		for _, locale := range sorted(track.Text) {
			text := track.Text[locale]
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_track_text (tenant_id, track_id, locale, name, goal, outcome)
				VALUES ($1, $2, $3, $4, $5, $6)
			`, tenantID, track.ID, locale, text.Name, text.Goal, text.Outcome); err != nil {
				return fmt.Errorf("writing the %s of the track %s: %w", locale, track.ID, err)
			}

			for _, at := range sorted(text.Steps) {
				position, err := strconv.Atoi(at)
				if err != nil {
					// Refused by the validator; here it would be a silent skip.
					return fmt.Errorf("the %s of the track %s translates a step called %q",
						locale, track.ID, at)
				}
				fork := text.Steps[at]
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_track_fork_text
						(tenant_id, track_id, position, locale, choice, note, options)
					VALUES ($1, $2, $3, $4, $5, $6, $7)
				`, tenantID, track.ID, position, locale,
					fork.Choice, fork.Note, fork.Options); err != nil {
					return fmt.Errorf("writing the %s of a choice in %s: %w", locale, track.ID, err)
				}
			}
		}

		// The track's own sequence. Written in the order the file lists them,
		// because the position is the primary key's tie-breaker and reading
		// them back in a different order would draw the same edges in a
		// different order — which the graph does not care about and a diff of
		// two loads does.
		for _, course := range sorted(track.Links) {
			for position, target := range track.Links[course] {
				var step *int
				if target.Step != nil {
					step = target.Step
				}
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_track_links
						(tenant_id, track_id, course_id, position, target_course, target_step)
					VALUES ($1, $2, $3, $4, $5, $6)
				`, tenantID, track.ID, courseID[course], position,
					courseID[target.Course], step); err != nil {
					return fmt.Errorf("writing a link of %s in %s: %w", course, track.ID, err)
				}
			}
		}

		for position, step := range track.Courses {
			if step.Fork == nil {
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_track_courses
						(tenant_id, track_id, position, course_id)
					VALUES ($1, $2, $3, $4)
				`, tenantID, track.ID, position, courseID[step.Course]); err != nil {
					return fmt.Errorf("writing %s/%s: %w", track.ID, step.Course, err)
				}
				continue
			}

			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_track_forks (tenant_id, track_id, position, choice, note)
				VALUES ($1, $2, $3, $4, $5)
			`, tenantID, track.ID, position, step.Fork.Choice, step.Fork.Note); err != nil {
				return fmt.Errorf("writing a fork in %s: %w", track.ID, err)
			}

			for option, branch := range step.Fork.Options {
				for course, id := range branch.Courses {
					if _, err := tx.Exec(ctx, `
						INSERT INTO catalog_track_courses
							(tenant_id, track_id, position, option_name, option_position,
							 course_position, course_id)
						VALUES ($1, $2, $3, $4, $5, $6, $7)
					`, tenantID, track.ID, position, branch.Name, option, course,
						courseID[id]); err != nil {
						return fmt.Errorf("writing %s/%s: %w", track.ID, id, err)
					}
				}
			}
		}
	}

	for _, course := range school.Courses {
		if _, err := tx.Exec(ctx, `
			INSERT INTO catalog_courses
				(tenant_id, id, slug, name, category, level, hours, summary, prerequisites,
				 syllabus, draft)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		`, tenantID, course.ID, course.Slug, course.Name, course.Category, course.Level, course.Hours,
			course.Summary, course.Prerequisites, lines(course.Syllabus),
			course.Draft); err != nil {
			return fmt.Errorf("writing the course %s: %w", course.ID, err)
		}

		/* THE TOPICS, EACH WITH THE ID IT DECLARED — and declared is the only way
		   an id gets here. Nothing in this job works one out from a title,
		   because nothing anywhere does any more: a catalogue that reached this
		   line passed `Validate`, which refuses a topic with no id, and a
		   catalogue that does not pass is never written. */
		for at, topic := range course.Topics {
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_course_topics
					(tenant_id, course_id, position, topic_id, title)
				VALUES ($1, $2, $3, $4, $5)
			`, tenantID, course.ID, at, topic.ID, topic.Title); err != nil {
				return fmt.Errorf("writing topic %d of the course %s: %w", at, course.ID, err)
			}
		}

		for _, locale := range sorted(course.Text) {
			text := course.Text[locale]
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_course_text
					(tenant_id, course_id, locale, name, summary, prerequisites, syllabus)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
			`, tenantID, course.ID, locale, text.Name, text.Summary, text.Prerequisites,
				text.Syllabus); err != nil {
				return fmt.Errorf("writing the %s of the course %s: %w", locale, course.ID, err)
			}

			// BY THE TOPIC'S ID. It was an array beside the syllabus, matched to
			// the English topics by position — see `CourseText.Topics`.
			for _, id := range sorted(text.Topics) {
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_course_topic_text
						(tenant_id, course_id, topic_id, locale, title)
					VALUES ($1, $2, $3, $4, $5)
				`, tenantID, course.ID, id, locale, text.Topics[id]); err != nil {
					return fmt.Errorf("writing the %s title of %s/%s: %w", locale, course.ID, id, err)
				}
			}
		}

		for _, needed := range course.Requires {
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_course_requires (tenant_id, course_id, requires_id)
				VALUES ($1, $2, $3)
			`, tenantID, course.ID, courseID[needed]); err != nil {
				return fmt.Errorf("writing what %s requires: %w", course.ID, err)
			}
		}

		for i, lesson := range course.Loaded {
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_lessons (tenant_id, course_id, id, title, position)
				VALUES ($1, $2, $3, $4, $5)
			`, tenantID, course.ID, lesson.ID, lesson.Title, i); err != nil {
				return fmt.Errorf("writing the lesson %s: %w", lesson.ID, err)
			}

			for j, section := range lesson.Sections {
				countable := section.Kind != catalog.KindVideo
				if section.Countable != nil {
					countable = *section.Countable
				}
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_sections
						(tenant_id, course_id, lesson_id, id, slug, kind, video, duration,
						 countable, position)
					VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
				`, tenantID, course.ID, lesson.ID, section.ID, section.Slug, section.Kind,
					len(section.Videos) > 0, summarise(section.Videos), countable, j); err != nil {
					return fmt.Errorf("writing the section %s: %w", section.ID, err)
				}

				for k, v := range section.Videos {
					if _, err := tx.Exec(ctx, `
						INSERT INTO catalog_videos
							(tenant_id, course_id, lesson_id, section_id, id, version,
							 script, seconds, locales, position)
						VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
					`, tenantID, course.ID, lesson.ID, section.ID, v.ID, v.Version,
						v.Script, v.Seconds, v.Locales, k); err != nil {
						return fmt.Errorf("writing the video %s: %w", v.ID, err)
					}
				}
			}

			for _, prose := range lesson.Text {
				if _, err := tx.Exec(ctx, `
					INSERT INTO catalog_prose
						(tenant_id, course_id, lesson_id, section_id, locale, title, body, version)
					VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
				`, tenantID, course.ID, lesson.ID, prose.SectionID, prose.Locale,
					prose.Title, prose.Body, prose.Version); err != nil {
					return fmt.Errorf("writing the prose of %s: %w", prose.SectionID, err)
				}
			}

			if err := writeExercises(ctx, tx, tenantID,
				owner{courseID: course.ID, lessonID: lesson.ID}, lesson.Exercises,
				lesson.ExerciseText); err != nil {
				return err
			}
		}

		for _, image := range course.Images {
			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_images (tenant_id, course_id, name, media_type, bytes)
				VALUES ($1, $2, $3, $4, $5)
			`, tenantID, course.ID, image.Name, image.MediaType, image.Bytes); err != nil {
				return fmt.Errorf("writing the picture %s: %w", image.Name, err)
			}
		}

		if err := writeExercises(ctx, tx, tenantID,
			owner{courseID: course.ID, exam: true}, course.Exam, course.ExamText); err != nil {
			return err
		}
	}

	// The finals. They are written after the courses rather than beside their
	// track for no reason other than that the tracks were already walked; the
	// order of inserts is not a constraint, because `continues` and the rest are
	// checked before anything is written.
	for _, track := range school.Tracks {
		if err := writeExercises(ctx, tx, tenantID,
			owner{trackID: track.ID, exam: true}, track.Exam, track.ExamText); err != nil {
			return err
		}
	}

	return nil
}

// owner is where a question hangs: in a lesson, in a course's exam, or in a
// track's final. EXACTLY ONE OF courseID AND trackID IS SET, which the schema
// also states as a check — a struct rather than five positional arguments,
// because the two that mattered were adjacent strings.
type owner struct {
	courseID string
	lessonID string
	trackID  string
	exam     bool
}

func writeExercises(ctx context.Context, tx pgx.Tx, tenantID uuid.UUID,
	at owner, exercises []catalog.Exercise,
	text map[string]map[string]catalog.ExerciseText) error {

	for _, e := range exercises {
		payload := e.Raw
		if len(payload) == 0 {
			payload = json.RawMessage("{}")
		}

		if _, err := tx.Exec(ctx, `
			INSERT INTO catalog_exercises
				(tenant_id, id, course_id, track_id, lesson_id, section_id, exam,
				 version, type, difficulty, drillable, prompt, hint, payload)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		`, tenantID, e.ID, at.courseID, at.trackID, at.lessonID, e.Section, at.exam,
			e.Version, e.Type, e.Difficulty, e.Drillable, e.Prompt, e.Hint, payload); err != nil {
			return fmt.Errorf("writing the exercise %s: %w", e.ID, err)
		}

		/* AND THE SAME QUESTION IN EVERY LANGUAGE SOMEBODY WROTE IT IN.

		   A COMPLETE PAYLOAD PER LOCALE, merged here and once: what nobody
		   translated stays English, so a reader takes one payload and never has
		   to ask which half of it came from where. `catalog.Translated` is the
		   only thing that writes one, and it can only write the fields
		   `ExerciseText` declares — none of which grading reads. */
		for locale, questions := range text {
			one, found := questions[e.ID]
			if !found {
				continue
			}
			translated, err := catalog.Translated(payload, one)
			if err != nil {
				return fmt.Errorf("translating the exercise %s into %s: %w", e.ID, locale, err)
			}

			prompt, hint := e.Prompt, e.Hint
			if one.Prompt != nil {
				prompt = *one.Prompt
			}
			if one.Hint != nil {
				hint = *one.Hint
			}

			if _, err := tx.Exec(ctx, `
				INSERT INTO catalog_exercise_text
					(tenant_id, exercise_id, locale, prompt, hint, payload)
				VALUES ($1, $2, $3, $4, $5, $6)
			`, tenantID, e.ID, locale, prompt, hint, translated); err != nil {
				return fmt.Errorf("writing the %s of the exercise %s: %w", locale, e.ID, err)
			}
		}
	}
	return nil
}

/*
summarise is what the rail prints beside a section, and it is a SUMMARY rather
than a second source: it is computed by the only writer, from the rows written
beside it, in the same transaction.

THE FORMAT DOES NOT BELONG HERE and it is not moving in this change. A column
holding "12 min" is presentation in data — a screen in another language prints
an English word — and the right home is the interface, with the player that
will read `catalog_videos.seconds` directly. That is phase 6's; until then this
keeps what the rail already draws from going blank.
*/
func summarise(videos []catalog.Video) string {
	total := 0
	for _, v := range videos {
		total += v.Seconds
	}
	if total == 0 {
		return ""
	}
	if minutes := (total + 59) / 60; minutes < 60 {
		return fmt.Sprintf("%02d min", minutes)
	}
	return fmt.Sprintf("%d h %02d min", total/3600, (total%3600+59)/60)
}
