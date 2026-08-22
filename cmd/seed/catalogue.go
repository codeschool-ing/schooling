package main

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* What the school actually contains, which is what the invented past has to be
   about.

   A SEEDED HISTORY POINTS AT REAL THINGS OR IT POINTS AT NOTHING. A funnel whose
   `track.opened` names a track that does not exist draws the same boxes and
   answers no question; an `exam.item.answered` for an exercise nobody wrote
   produces statistics about a question that cannot be looked at, let alone
   fixed. So the shape is read out of the catalogue mirror rather than invented
   beside it.

   IT READS AND NEVER WRITES. The catalogue has one writer — `cmd/load`, from
   the files — and a test scans the source to keep it that way. */

type shape struct {
	id   uuid.UUID
	slug string

	track  string
	course string

	// A lesson and the sections under it, which are what a student opens and
	// completes. Empty is survivable: those steps are simply not seeded, and the
	// funnel shows the drop where the content is missing, which is true.
	lesson   string
	sections []string

	questions []question

	// broken is the exercise this run plants an inverted key on. Empty when the
	// course has no exam.
	broken string
}

// question is one exam question, with how easy this seeder will make it.
type question struct {
	id      string
	version int
	kind    string

	// ease shifts the chance of a right answer, and it is DERIVED FROM THE ID
	// rather than drawn: every run of this seeder gives the same question the
	// same difficulty, so two runs can be compared. A random one would make
	// "this question got harder" a fact about the seeder.
	ease float64
}

func shapeOf(ctx context.Context, pool *pgxpool.Pool, slug string) (shape, error) {
	var s shape
	s.slug = slug

	if err := pool.QueryRow(ctx,
		`SELECT id FROM tenants WHERE slug = $1`, slug).Scan(&s.id); err != nil {
		return s, fmt.Errorf("there is no school called %q: %w", slug, err)
	}

	/* THE FIRST TRACK AND ITS FIRST COURSE, by the order the catalogue declares
	   rather than by name. The free tier is the first course of every track
	   (computed from the order, not flagged), so this is also the course a
	   population would actually meet. */
	err := pool.QueryRow(ctx, `
		SELECT t.id, c.course_id
		FROM catalog_tracks t
		JOIN catalog_track_courses c ON c.tenant_id = t.tenant_id AND c.track_id = t.id
		WHERE t.tenant_id = $1
		ORDER BY t.position, c.position
		LIMIT 1
	`, s.id).Scan(&s.track, &s.course)
	if err != nil {
		return s, fmt.Errorf("%s has no track with a course in it, so there is nothing "+
			"for a seeded student to do: %w", slug, err)
	}

	// A lesson and its sections. Absent is not an error: see the struct.
	_ = pool.QueryRow(ctx, `
		SELECT id FROM catalog_lessons
		WHERE tenant_id = $1 AND course_id = $2
		ORDER BY position LIMIT 1
	`, s.id, s.course).Scan(&s.lesson)

	if s.lesson != "" {
		rows, err := pool.Query(ctx, `
			SELECT id FROM catalog_sections
			WHERE tenant_id = $1 AND course_id = $2 AND lesson_id = $3 AND countable
			ORDER BY position
		`, s.id, s.course, s.lesson)
		if err != nil {
			return s, fmt.Errorf("reading the sections of %s: %w", s.lesson, err)
		}
		defer rows.Close()
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				return s, fmt.Errorf("reading the sections of %s: %w", s.lesson, err)
			}
			s.sections = append(s.sections, id)
		}
		if err := rows.Err(); err != nil {
			return s, fmt.Errorf("reading the sections of %s: %w", s.lesson, err)
		}
	}

	questions, err := pool.Query(ctx, `
		SELECT id, version, type FROM catalog_exercises
		WHERE tenant_id = $1 AND course_id = $2 AND exam
		ORDER BY id
	`, s.id, s.course)
	if err != nil {
		return s, fmt.Errorf("reading the exam of %s: %w", s.course, err)
	}
	defer questions.Close()
	for questions.Next() {
		var q question
		if err := questions.Scan(&q.id, &q.version, &q.kind); err != nil {
			return s, fmt.Errorf("reading the exam of %s: %w", s.course, err)
		}
		q.ease = easeOf(q.id)
		s.questions = append(s.questions, q)
	}
	if err := questions.Err(); err != nil {
		return s, fmt.Errorf("reading the exam of %s: %w", s.course, err)
	}

	/* THE BROKEN ONE IS THE FIRST BY ID, which is a choice with no meaning and
	   that is the point: it has to be nameable — printed at the end, checked by
	   a test — and it must not be the question that happens to be hardest, or
	   "the analysis found it" would be a fact about the difficulty rather than
	   about the key. */
	if len(s.questions) > 0 {
		s.broken = s.questions[0].id
	}
	if len(s.questions) < 2 {
		// Not fatal, and worth being loud about: with one question there is no
		// paper score to divide students by, so the discrimination index has
		// nothing to discriminate with.
		if len(s.questions) == 1 {
			return s, errors.New("this course has one exam question, and a discrimination " +
				"index is a comparison between how the strong and the weak did on the whole " +
				"paper — with one question the paper IS the question")
		}
	}
	return s, nil
}

// easeOf turns an exercise id into a number between −0.2 and +0.2.
//
// Hashed rather than drawn: the same question is the same difficulty in every
// run, so a change in what the analysis says is a change in the analysis.
func easeOf(id string) float64 {
	sum := sha256.Sum256([]byte(id))
	n := binary.BigEndian.Uint32(sum[:4])
	return float64(n%401)/1000 - 0.2
}
