package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Reading the mirror.
//
// EVERY QUERY LEADS WITH tenant_id, and the tenancy test holds every index to
// matching. Nothing here takes a school from anywhere but its caller, which
// takes it from the middleware, which takes it from the Host — the chain that
// makes "a school is whichever one the address names" true all the way down.
//
// NOTHING HERE WRITES. The files are the truth and these tables are derived;
// an architecture test scans the source to keep it that way.

// ErrNotFound is a course, track or lesson this school does not have. It is a
// state rather than a failure — somebody followed an old link.
var ErrNotFound = errors.New("catalog: no such thing in this school")

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

/* ---------- what a catalogue screen shows ---------- */

// Listing is one course as the catalogue lists it, with the door already
// decided.
type Listing struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
	Level    string `json:"level"`
	Hours    int    `json:"hours"`
	Summary  string `json:"summary"`

	Requires []string `json:"requires"`

	// How much there is, which is what a screen puts under a course's name and
	// what every "4 of 50" on the interface divides by.
	//
	// SECTIONS COUNTS ONLY THE COUNTABLE ONES. It is the denominator of a
	// progress bar, and a denominator that includes steps nobody can complete
	// is a bar that stops short of full for a student who finished the course.
	// `countable` is a column precisely so this is not inferred from what a
	// section happens to be (see `catalog_sections`).
	Lessons  int `json:"lessons"`
	Sections int `json:"sections"`

	// What is in the course, at two depths. On the LISTING and not only on the
	// course view, because the interface derives a course's lessons from
	// `topics` — a catalogue answered without them is a school where every
	// course has nothing in it.
	Syllabus []string `json:"syllabus,omitempty"`
	/* THE TOPICS CARRY THEIR IDS, and that is what the interface joins a lesson
	   by. It used to be a list of sentences and the client looked a lesson up by
	   its title text — see the migration that made this a table for what that
	   cost. The title is still here because it is what a person reads. */
	Topics []Topic `json:"topics,omitempty"`

	Free   bool   `json:"free"`
	Locked bool   `json:"locked"`
	Reason string `json:"reason,omitempty"`
}

// Courses lists what a student may see, with each door decided for this plan.
//
// DRAFTS NEVER APPEAR. Not locked, not greyed — absent. A course being written
// is not a product, and the difference between "not for you" and "not yet"
// belongs to the console rather than to a catalogue screen.
//
// AND IT IS ANSWERED IN A LANGUAGE. A course's name and syllabus used to be
// translated by a dictionary that shipped with the interface, keyed by
// codeschool.ing's course ids — so a second school's courses came out in the
// language they were written in whatever the student picked, and nothing looked
// broken, because a missing translation falls back to its key and the key is the
// English text.
//
// `COALESCE` is the field-by-field fallback (C-11), said once per column: a
// course translated in its name and not its syllabus keeps the English
// syllabus. `NULLIF` on the arrays because an empty array is what a row carries
// for a list nobody translated, and empty is not the same as "no syllabus".
func (s *Store) Courses(ctx context.Context, tenantID uuid.UUID,
	plan Plan, locale string) ([]Listing, error) {

	free, err := s.freeCourses(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	// THE TWO COUNTS ARE SUBQUERIES AND NOT MORE JOINS. Joined in beside
	// `catalog_course_requires` they would multiply against it — three
	// prerequisites and fifty sections is a hundred and fifty rows, and
	// `count(*)` over that answers neither question. A scalar subquery per
	// course is the shape that cannot be wrong by accident.
	rows, err := s.pool.Query(ctx, `
		SELECT c.id, coalesce(t.name, c.name), c.category, c.level, c.hours,
		       coalesce(t.summary, c.summary),
		       coalesce(array_agg(r.requires_id ORDER BY r.requires_id)
		                FILTER (WHERE r.requires_id IS NOT NULL), '{}'),
		       (SELECT count(*) FROM catalog_lessons l
		         WHERE l.tenant_id = c.tenant_id AND l.course_id = c.id),
		       (SELECT count(*) FROM catalog_sections s
		         WHERE s.tenant_id = c.tenant_id AND s.course_id = c.id AND s.countable),
		       coalesce(nullif(t.syllabus, '{}'), c.syllabus),
		       (SELECT coalesce(jsonb_agg(jsonb_build_object(
		                 'id', tp.topic_id,
		                 'title', coalesce(nullif(t.topics[tp.position + 1], ''), tp.title))
		               ORDER BY tp.position), '[]'::jsonb)
		          FROM catalog_course_topics tp
		         WHERE tp.tenant_id = c.tenant_id AND tp.course_id = c.id)
		FROM catalog_courses c
		LEFT JOIN catalog_course_requires r
		       ON r.tenant_id = c.tenant_id AND r.course_id = c.id
		LEFT JOIN catalog_course_text t
		       ON t.tenant_id = c.tenant_id AND t.course_id = c.id AND t.locale = $2
		WHERE c.tenant_id = $1 AND NOT c.draft
		GROUP BY c.id, c.tenant_id, c.name, c.category, c.level, c.hours, c.summary,
		         c.syllabus, t.name, t.summary, t.syllabus, t.topics
		ORDER BY c.id
	`, tenantID, locale)
	if err != nil {
		return nil, fmt.Errorf("catalog: listing the courses: %w", err)
	}
	defer rows.Close()

	var out []Listing
	for rows.Next() {
		var l Listing
		var topics []byte
		if err := rows.Scan(&l.ID, &l.Name, &l.Category, &l.Level, &l.Hours,
			&l.Summary, &l.Requires, &l.Lessons, &l.Sections,
			&l.Syllabus, &topics); err != nil {
			return nil, fmt.Errorf("catalog: listing the courses: %w", err)
		}
		if err := json.Unmarshal(topics, &l.Topics); err != nil {
			return nil, fmt.Errorf("catalog: the topics of %q: %w", l.ID, err)
		}

		l.Free = free[l.ID]
		access := MayOpen(plan, &Course{ID: l.ID}, l.Free)
		l.Locked = !access.Allowed
		if l.Locked {
			l.Reason = access.Reason
		}
		out = append(out, l)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("catalog: listing the courses: %w", err)
	}
	return out, nil
}

// freeCourses answers which courses are the first of some track.
//
// THE SHOP WINDOW MUST BE OPEN AT EVERY DOOR (N-04): the first course of every
// track, in every school. It is computed from the catalogue's shape rather than
// flagged on a course, because a flag is a second place to say what position 0
// already says — and the two would disagree the first time a track is
// reordered.
func (s *Store) freeCourses(ctx context.Context, tenantID uuid.UUID) (map[string]bool, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT DISTINCT tc.course_id
		FROM catalog_track_courses tc
		WHERE tc.tenant_id = $1
		  AND tc.position = (
		      SELECT min(position) FROM catalog_track_courses
		      WHERE tenant_id = tc.tenant_id AND track_id = tc.track_id
		  )
	`, tenantID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the free tier: %w", err)
	}
	defer rows.Close()

	free := map[string]bool{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("catalog: reading the free tier: %w", err)
		}
		free[id] = true
	}
	return free, rows.Err()
}

/* ---------- a course, and what is inside it ---------- */

// CourseView is one course with its lessons. A locked course still shows its
// shape — the names of its lessons and how many steps each has — because that
// is what somebody deciding whether to subscribe is looking at. What it does
// not show is a single word of the material.
type CourseView struct {
	Listing
	Prerequisites string `json:"prerequisites"`

	Lessons []LessonView `json:"lessons"`

	// The names of this course's pictures. A client builds an address from each
	// — see the picture endpoint — and it is a list rather than something to be
	// discovered because there is nobody to ask: the offline bundle fetches as a
	// stranger and never sits an exam, so without this it could not know which
	// files a question is going to want.
	Images []string `json:"images,omitempty"`

	// Exam is whether there is one to sit. See hasExam for why a screen needs
	// to be told rather than to find out by being refused.
	Exam bool `json:"exam"`
}

type LessonView struct {
	ID       string        `json:"id"`
	Title    string        `json:"title"`
	Sections []SectionView `json:"sections"`
}

type SectionView struct {
	ID        string `json:"id"`
	Kind      string `json:"kind"`
	Duration  string `json:"duration,omitempty"`
	Countable bool   `json:"countable"`

	// Empty on a locked course, and on a section whose prose is not being
	// asked for. Absent rather than blank, so a client can tell "no words yet"
	// from "not for you".
	Title string `json:"title,omitempty"`
	Body  string `json:"body,omitempty"`
}

func (s *Store) Course(ctx context.Context, tenantID uuid.UUID,
	id string, locale string, plan Plan) (*CourseView, error) {

	free, err := s.freeCourses(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	// In the language that was asked for, falling back column by column — see
	// `Courses`, which does the same for the listing.
	var course Course
	var topics []byte
	err = s.pool.QueryRow(ctx, `
		SELECT c.id, coalesce(t.name, c.name), c.category, c.level, c.hours,
		       coalesce(t.summary, c.summary),
		       coalesce(t.prerequisites, c.prerequisites),
		       coalesce(nullif(t.syllabus, '{}'), c.syllabus),
		       (SELECT coalesce(jsonb_agg(jsonb_build_object(
		                 'id', tp.topic_id,
		                 'title', coalesce(nullif(t.topics[tp.position + 1], ''), tp.title))
		               ORDER BY tp.position), '[]'::jsonb)
		          FROM catalog_course_topics tp
		         WHERE tp.tenant_id = c.tenant_id AND tp.course_id = c.id),
		       c.draft
		FROM catalog_courses c
		LEFT JOIN catalog_course_text t
		       ON t.tenant_id = c.tenant_id AND t.course_id = c.id AND t.locale = $3
		WHERE c.tenant_id = $1 AND c.id = $2
	`, tenantID, id, locale).Scan(&course.ID, &course.Name, &course.Category, &course.Level,
		&course.Hours, &course.Summary, &course.Prerequisites,
		&course.Syllabus, &topics, &course.Draft)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the course %q: %w", id, err)
	}
	if err := json.Unmarshal(topics, &course.Topics); err != nil {
		return nil, fmt.Errorf("catalog: the topics of %q: %w", id, err)
	}

	// A draft answers exactly as a course that does not exist. Anything else
	// tells a stranger what is being written.
	if course.Draft {
		return nil, ErrNotFound
	}

	access := MayOpen(plan, &course, free[course.ID])

	view := &CourseView{
		Listing: Listing{
			ID: course.ID, Name: course.Name, Category: course.Category,
			Level: course.Level, Hours: course.Hours, Summary: course.Summary,
			Free: free[course.ID], Locked: !access.Allowed,
		},
		Prerequisites: course.Prerequisites,
	}
	/* BOTH LISTS ARE SHOWN ON A LOCKED COURSE, and that is the point of them.
	   What is behind the paywall is the MATERIAL; what a course contains is the
	   shop window, and hiding it would be asking somebody to buy a title. The
	   lessons below are already handled that way — their names show and their
	   words do not. */
	view.Syllabus, view.Topics = course.Syllabus, course.Topics
	if view.Locked {
		view.Reason = access.Reason
	}

	if view.Requires, err = s.requires(ctx, tenantID, id); err != nil {
		return nil, err
	}
	if view.Lessons, err = s.lessons(ctx, tenantID, id); err != nil {
		return nil, err
	}
	if view.Exam, err = s.hasExam(ctx, tenantID, ScopeCourse, id); err != nil {
		return nil, err
	}

	// A locked course lists no pictures, for the same reason it carries no
	// prose: the shape of a course is the shop window, its material is not.
	if !view.Locked {
		if view.Images, err = s.pictures(ctx, tenantID, id); err != nil {
			return nil, err
		}
	}
	return view, nil
}

func (s *Store) pictures(ctx context.Context, tenantID uuid.UUID, courseID string) ([]string, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT name FROM catalog_images
		WHERE tenant_id = $1 AND course_id = $2
		ORDER BY name
	`, tenantID, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog: listing the pictures of %q: %w", courseID, err)
	}
	defer rows.Close()

	var names []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, fmt.Errorf("catalog: listing the pictures of %q: %w", courseID, err)
		}
		names = append(names, name)
	}
	return names, rows.Err()
}

// The two things an exam can belong to. They are named here rather than passed
// as a column name, so no caller can reach a string this file did not write.
const (
	ScopeCourse = "course"
	ScopeTrack  = "track"
)

// hasExam answers whether there is an exam to sit.
//
// IT IS ON THE VIEW BECAUSE A SCREEN HAS TO DECIDE WHETHER TO OFFER THE BUTTON.
// Starting an exam that does not exist is a 404, so an interface with no way to
// ask would either show a button that sometimes fails or hide one that should
// be there. Both are worse than a boolean.
//
// It counts questions rather than reading a flag: a course whose pool is empty
// has no exam, because there is no such thing as a paper of zero questions —
// everybody would pass it at once.
func (s *Store) hasExam(ctx context.Context, tenantID uuid.UUID, scope, id string) (bool, error) {
	// The column is chosen from a closed set two lines above, never from an
	// argument that reached here from outside this package.
	column := "course_id"
	if scope == ScopeTrack {
		column = "track_id"
	}

	var yes bool
	err := s.pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM catalog_exercises
			WHERE tenant_id = $1 AND exam AND `+column+` = $2
		)
	`, tenantID, id).Scan(&yes)
	if err != nil {
		return false, fmt.Errorf("catalog: asking whether %s %q has an exam: %w", scope, id, err)
	}
	return yes, nil
}

func (s *Store) requires(ctx context.Context, tenantID uuid.UUID, courseID string) ([]string, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT requires_id FROM catalog_course_requires
		WHERE tenant_id = $1 AND course_id = $2 ORDER BY requires_id
	`, tenantID, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading what %q requires: %w", courseID, err)
	}
	defer rows.Close()

	out := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("catalog: reading what %q requires: %w", courseID, err)
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

// Structure is every course's lessons and sections, for the whole school, with
// not a word of the material in it.
//
// ONE READ, BECAUSE THE RAIL NEEDS ALL OF IT. An interface that draws a lesson
// list beside every course would otherwise ask course by course — a hundred and
// twenty-two requests to paint a sidebar, most of them for courses nobody is
// looking at.
//
// IT IS NOT GATED, and that is the same decision the course view already makes:
// a locked course shows its shape and none of its words, because the shape is
// what somebody deciding whether to subscribe is reading. There is no prose in
// this answer at all, which is what makes it safe to serve whole.
//
// A SECTION'S TITLE IS PART OF THE SHAPE AND NOT PART OF THE MATERIAL, which
// this answer left out at first and should not have. The lesson's title is
// already here for exactly that reason; a section's is the same kind of thing —
// it is what the rail, the section strip and the "pick up where you left off"
// card call the place a student is going. Without it every one of them fell
// back to the id, and the dashboard offered to continue from "intro".
//
// IT IS ASKED FOR IN A LANGUAGE, because a title is a translated string and
// this school keeps its translations in its own rows rather than in a
// dictionary shipped with the interface. `COALESCE` is the field-by-field
// fallback the prose reader spells out at length (C-11), in one line here
// because there is one field: a section translated in its body but not its
// title keeps the English title rather than losing it.
func (s *Store) Structure(ctx context.Context, tenantID uuid.UUID,
	locale string) (map[string][]LessonView, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT l.course_id, l.id, l.title, s.id, s.kind, s.duration, s.countable,
		       COALESCE(NULLIF(t.title, ''), e.title)
		FROM catalog_lessons l
		JOIN catalog_courses c
		  ON c.tenant_id = l.tenant_id AND c.id = l.course_id AND NOT c.draft
		LEFT JOIN catalog_sections s
		       ON s.tenant_id = l.tenant_id AND s.course_id = l.course_id AND s.lesson_id = l.id
		LEFT JOIN catalog_prose e
		       ON e.tenant_id = s.tenant_id AND e.course_id = s.course_id
		      AND e.lesson_id = s.lesson_id AND e.section_id = s.id AND e.locale = 'en'
		LEFT JOIN catalog_prose t
		       ON t.tenant_id = s.tenant_id AND t.course_id = s.course_id
		      AND t.lesson_id = s.lesson_id AND t.section_id = s.id AND t.locale = $2
		WHERE l.tenant_id = $1
		ORDER BY l.course_id, l.position, s.position
	`, tenantID, locale)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the shape of every course: %w", err)
	}
	defer rows.Close()

	out := map[string][]LessonView{}
	for rows.Next() {
		var courseID, lessonID, title string
		var section, kind, duration, sectionTitle *string
		var countable *bool
		if err := rows.Scan(&courseID, &lessonID, &title,
			&section, &kind, &duration, &countable, &sectionTitle); err != nil {
			return nil, fmt.Errorf("catalog: reading the shape of every course: %w", err)
		}

		list := out[courseID]
		if len(list) == 0 || list[len(list)-1].ID != lessonID {
			list = append(list, LessonView{ID: lessonID, Title: title, Sections: []SectionView{}})
		}
		// A lesson with no sections joins as one row with nulls, which is a
		// lesson and not a section — the LEFT JOIN is what keeps it visible.
		if section != nil {
			last := &list[len(list)-1]
			view := SectionView{
				ID: *section, Kind: *kind, Duration: *duration, Countable: *countable,
			}
			// Absent rather than blank when nobody has written the section
			// yet: the interface falls back to the id, and an empty string
			// would give it a nameless row to draw instead.
			if sectionTitle != nil {
				view.Title = *sectionTitle
			}
			last.Sections = append(last.Sections, view)
		}
		out[courseID] = list
	}
	return out, rows.Err()
}

func (s *Store) lessons(ctx context.Context, tenantID uuid.UUID, courseID string) ([]LessonView, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT l.id, l.title, s.id, s.kind, s.duration, s.countable
		FROM catalog_lessons l
		LEFT JOIN catalog_sections s
		       ON s.tenant_id = l.tenant_id AND s.course_id = l.course_id AND s.lesson_id = l.id
		WHERE l.tenant_id = $1 AND l.course_id = $2
		ORDER BY l.position, s.position
	`, tenantID, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the lessons of %q: %w", courseID, err)
	}
	defer rows.Close()

	var out []LessonView
	at := map[string]int{}

	for rows.Next() {
		var lessonID, title string
		var section, kind, duration *string
		var countable *bool

		if err := rows.Scan(&lessonID, &title, &section, &kind, &duration, &countable); err != nil {
			return nil, fmt.Errorf("catalog: reading the lessons of %q: %w", courseID, err)
		}

		i, seen := at[lessonID]
		if !seen {
			out = append(out, LessonView{ID: lessonID, Title: title})
			i = len(out) - 1
			at[lessonID] = i
		}
		if section == nil {
			continue // a lesson with no sections, which the validator refuses
		}
		out[i].Sections = append(out[i].Sections, SectionView{
			ID: *section, Kind: *kind, Duration: *duration, Countable: *countable,
		})
	}
	return out, rows.Err()
}

// SectionsOf answers which sections each lesson of a course has.
//
// IT EXISTS FOR THE MODULE THAT RECORDS PROGRESS, which may not import this one
// and must not take a client's word for what a section is. A client that
// invented ids could otherwise finish a three-section course by sending thirty,
// and every count above it would rest on rows naming nothing.
func (s *Store) SectionsOf(ctx context.Context, tenantID uuid.UUID,
	courseID string) (map[string][]string, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT lesson_id, id FROM catalog_sections
		WHERE tenant_id = $1 AND course_id = $2
		ORDER BY lesson_id, position
	`, tenantID, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the sections of %q: %w", courseID, err)
	}
	defer rows.Close()

	out := map[string][]string{}
	for rows.Next() {
		var lesson, section string
		if err := rows.Scan(&lesson, &section); err != nil {
			return nil, fmt.Errorf("catalog: reading the sections of %q: %w", courseID, err)
		}
		out[lesson] = append(out[lesson], section)
	}
	return out, rows.Err()
}

/* ---------- the words ---------- */

// Lesson answers one lesson with its prose, in the locale asked for.
//
// IT REFUSES ON A LOCKED COURSE rather than returning the shape with the words
// removed. The shape is already on the course screen; a lesson request is a
// request to read, and answering it with an empty body would be a paywall that
// looks like a bug.
func (s *Store) Lesson(ctx context.Context, tenantID uuid.UUID,
	courseID, lessonID string, locale string, plan Plan) (*LessonView, error) {

	course, err := s.Course(ctx, tenantID, courseID, locale, plan)
	if err != nil {
		return nil, err
	}
	if course.Locked {
		return nil, ErrLocked
	}

	var found *LessonView
	for i := range course.Lessons {
		if course.Lessons[i].ID == lessonID {
			found = &course.Lessons[i]
			break
		}
	}
	if found == nil {
		return nil, ErrNotFound
	}

	prose, err := s.prose(ctx, tenantID, courseID, lessonID, locale)
	if err != nil {
		return nil, err
	}
	for i := range found.Sections {
		if p, ok := prose[found.Sections[i].ID]; ok {
			found.Sections[i].Title = p.Title
			found.Sections[i].Body = p.Body
		}
	}
	return found, nil
}

// ErrLocked is a course this plan does not open.
var ErrLocked = errors.New("catalog: this course is not open to this plan")

// Picture reads one of a course's images.
//
// IT ASKS `Course` FIRST RATHER THAN QUERYING THE TABLE, and that is the whole
// security of it: a picture belongs to a course, so it is exactly as readable
// as the course is — the same plan, the same draft rule, the same paywall.
//
// Going straight to `catalog_images` would have been three lines shorter and
// would have served every diagram in a paid course to anybody who could guess a
// file name. A test that only ever asked for the JSON would never have noticed:
// the paywall would be on the endpoint beside the picture rather than on the
// picture.
func (s *Store) Picture(ctx context.Context, tenantID uuid.UUID,
	courseID, name string, plan Plan) (mediaType string, body []byte, err error) {

	// The LANGUAGE IS IRRELEVANT HERE and English is asked for on purpose: this
	// call is the paywall and nothing else — it reads `Locked` and throws the
	// rest away. Passing a locale would suggest the name of the course matters
	// to a picture, which it does not.
	course, err := s.Course(ctx, tenantID, courseID, "en", plan)
	if err != nil {
		return "", nil, err
	}
	if course.Locked {
		return "", nil, ErrLocked
	}

	row := s.pool.QueryRow(ctx, `
		SELECT media_type, bytes
		FROM catalog_images
		WHERE tenant_id = $1 AND course_id = $2 AND name = $3
	`, tenantID, courseID, name)

	if err := row.Scan(&mediaType, &body); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", nil, ErrNotFound
		}
		return "", nil, fmt.Errorf("catalog: reading the picture %q: %w", name, err)
	}
	return mediaType, body, nil
}

// prose reads a lesson's words, falling back FIELD BY FIELD.
//
// A section translated in its title but not its body keeps the English body
// rather than losing the title too (C-11). That only works because a missing
// translation is a missing ROW rather than an empty one — the two are different
// things all the way down, and this is where the difference is spent.
func (s *Store) prose(ctx context.Context, tenantID uuid.UUID,
	courseID, lessonID, locale string) (map[string]Prose, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT section_id, locale, title, body
		FROM catalog_prose
		WHERE tenant_id = $1 AND course_id = $2 AND lesson_id = $3 AND locale IN ($4, 'en')
	`, tenantID, courseID, lessonID, locale)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the prose of %q: %w", lessonID, err)
	}
	defer rows.Close()

	english := map[string]Prose{}
	wanted := map[string]Prose{}

	for rows.Next() {
		var p Prose
		if err := rows.Scan(&p.SectionID, &p.Locale, &p.Title, &p.Body); err != nil {
			return nil, fmt.Errorf("catalog: reading the prose of %q: %w", lessonID, err)
		}
		if p.Locale == locale {
			wanted[p.SectionID] = p
		} else {
			english[p.SectionID] = p
		}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("catalog: reading the prose of %q: %w", lessonID, err)
	}

	out := map[string]Prose{}
	for id, source := range english {
		out[id] = source
	}
	for id, translated := range wanted {
		merged := out[id]
		merged.SectionID = id
		merged.Locale = translated.Locale
		if translated.Title != "" {
			merged.Title = translated.Title
		}
		if translated.Body != "" {
			merged.Body = translated.Body
		}
		out[id] = merged
	}
	return out, nil
}

/* ---------- tracks ---------- */

// TrackView is a track with its order and its forks intact.
type TrackView struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Goal    string `json:"goal,omitempty"`
	Outcome string `json:"outcome,omitempty"`

	Continues string     `json:"continues,omitempty"`
	Steps     []StepView `json:"steps"`

	// The track's own sequence — see Track.Links. Served in the catalogue's own
	// shape, a map from course id to a list of steps and course ids, so that
	// the interface reads it with no translation.
	Links map[string][]LinkTarget `json:"links,omitempty"`

	// Whether the track has a final. Empty on the list, which does not ask.
	Exam bool `json:"exam"`
}

// StepView is one position in a track. A step with options is a fork; a step
// with one course and no options is not.
type StepView struct {
	Choice  string       `json:"choice,omitempty"`
	Note    string       `json:"note,omitempty"`
	Course  string       `json:"course,omitempty"`
	Options []OptionView `json:"options,omitempty"`
}

type OptionView struct {
	Name    string   `json:"name"`
	Courses []string `json:"courses"`
}

func (s *Store) Tracks(ctx context.Context, tenantID uuid.UUID,
	locale string) ([]TrackView, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT c.id, coalesce(t.name, c.name), coalesce(t.goal, c.goal),
		       coalesce(t.outcome, c.outcome), c.continues
		FROM catalog_tracks c
		LEFT JOIN catalog_track_text t
		       ON t.tenant_id = c.tenant_id AND t.track_id = c.id AND t.locale = $2
		WHERE c.tenant_id = $1 ORDER BY c.position
	`, tenantID, locale)
	if err != nil {
		return nil, fmt.Errorf("catalog: listing the tracks: %w", err)
	}
	defer rows.Close()

	var out []TrackView
	for rows.Next() {
		var t TrackView
		if err := rows.Scan(&t.ID, &t.Name, &t.Goal, &t.Outcome, &t.Continues); err != nil {
			return nil, fmt.Errorf("catalog: listing the tracks: %w", err)
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("catalog: listing the tracks: %w", err)
	}

	// THE LIST CARRIES THE SEQUENCE TOO, and that is not padding. The interface
	// fills its whole catalogue from this one answer and draws every map from
	// it — there is no second request per track — so a field left out here is a
	// field no screen ever sees.
	for i := range out {
		if out[i].Steps, err = s.steps(ctx, tenantID, out[i].ID, locale); err != nil {
			return nil, err
		}
		if out[i].Links, err = s.links(ctx, tenantID, out[i].ID); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (s *Store) Track(ctx context.Context, tenantID uuid.UUID,
	id, locale string) (*TrackView, error) {

	var t TrackView
	err := s.pool.QueryRow(ctx, `
		SELECT c.id, coalesce(x.name, c.name), coalesce(x.goal, c.goal),
		       coalesce(x.outcome, c.outcome), c.continues
		FROM catalog_tracks c
		LEFT JOIN catalog_track_text x
		       ON x.tenant_id = c.tenant_id AND x.track_id = c.id AND x.locale = $3
		WHERE c.tenant_id = $1 AND c.id = $2
	`, tenantID, id, locale).Scan(&t.ID, &t.Name, &t.Goal, &t.Outcome, &t.Continues)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the track %q: %w", id, err)
	}

	if t.Steps, err = s.steps(ctx, tenantID, id, locale); err != nil {
		return nil, err
	}
	if t.Links, err = s.links(ctx, tenantID, id); err != nil {
		return nil, err
	}
	if t.Exam, err = s.hasExam(ctx, tenantID, ScopeTrack, id); err != nil {
		return nil, err
	}
	return &t, nil
}

// links reads a track's own sequence back into the shape the catalogue writes.
//
// ONE TRACK AT A TIME, and not on the list: the list draws no graph, and this
// is only read by the screen that does.
func (s *Store) links(ctx context.Context, tenantID uuid.UUID,
	trackID string) (map[string][]LinkTarget, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT course_id, target_course, target_step
		FROM catalog_track_links
		WHERE tenant_id = $1 AND track_id = $2
		ORDER BY course_id, position
	`, tenantID, trackID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the sequence of %q: %w", trackID, err)
	}
	defer rows.Close()

	out := map[string][]LinkTarget{}
	for rows.Next() {
		var course, target string
		var step *int
		if err := rows.Scan(&course, &target, &step); err != nil {
			return nil, fmt.Errorf("catalog: reading the sequence of %q: %w", trackID, err)
		}
		if step != nil {
			at := *step
			out[course] = append(out[course], LinkTarget{Step: &at})
			continue
		}
		out[course] = append(out[course], LinkTarget{Course: target})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("catalog: reading the sequence of %q: %w", trackID, err)
	}
	if len(out) == 0 {
		return nil, nil // absent rather than an empty object
	}
	return out, nil
}

// steps rebuilds a track's order from the flat rows the load job wrote.
func (s *Store) steps(ctx context.Context, tenantID uuid.UUID,
	trackID, locale string) ([]StepView, error) {

	// A FORK'S OPTION NAMES COME BACK AS AN ARRAY, matched to the options by
	// POSITION — which is the one join in this catalogue that a reordering can
	// break in silence, and why `validate.go` refuses a translation whose list
	// is a different length from the fork's. Here it is applied defensively as
	// well: an index past the end leaves the English name rather than reaching
	// out of the slice.
	optionNames := map[int][]string{}
	forks := map[int]StepView{}
	rows, err := s.pool.Query(ctx, `
		SELECT f.position, coalesce(t.choice, f.choice), coalesce(t.note, f.note),
		       t.options
		FROM catalog_track_forks f
		LEFT JOIN catalog_track_fork_text t
		       ON t.tenant_id = f.tenant_id AND t.track_id = f.track_id
		      AND t.position = f.position AND t.locale = $3
		WHERE f.tenant_id = $1 AND f.track_id = $2
	`, tenantID, trackID, locale)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the forks of %q: %w", trackID, err)
	}
	for rows.Next() {
		var at int
		var step StepView
		var names []string
		if err := rows.Scan(&at, &step.Choice, &step.Note, &names); err != nil {
			rows.Close()
			return nil, fmt.Errorf("catalog: reading the forks of %q: %w", trackID, err)
		}
		forks[at] = step
		optionNames[at] = names
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("catalog: reading the forks of %q: %w", trackID, err)
	}

	rows, err = s.pool.Query(ctx, `
		SELECT position, option_name, option_position, course_id
		FROM catalog_track_courses
		WHERE tenant_id = $1 AND track_id = $2
		ORDER BY position, option_position, course_position
	`, tenantID, trackID)
	if err != nil {
		return nil, fmt.Errorf("catalog: reading the order of %q: %w", trackID, err)
	}
	defer rows.Close()

	var out []StepView
	at := map[int]int{}
	option := map[string]int{}

	for rows.Next() {
		var position, optionAt int
		var name, courseID string
		if err := rows.Scan(&position, &name, &optionAt, &courseID); err != nil {
			return nil, fmt.Errorf("catalog: reading the order of %q: %w", trackID, err)
		}

		i, seen := at[position]
		if !seen {
			out = append(out, forks[position])
			i = len(out) - 1
			at[position] = i
		}

		if name == "" {
			out[i].Course = courseID
			continue
		}

		key := fmt.Sprint(position, "/", optionAt)
		j, known := option[key]
		if !known {
			shown := name
			if names := optionNames[position]; optionAt < len(names) && names[optionAt] != "" {
				shown = names[optionAt]
			}
			out[i].Options = append(out[i].Options, OptionView{Name: shown})
			j = len(out[i].Options) - 1
			option[key] = j
		}
		out[i].Options[j].Courses = append(out[i].Options[j].Courses, courseID)
	}
	return out, rows.Err()
}
