package report

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Who this is and where they are. Both come from the session and the host
// rather than from the request, for the reason every student route here does:
// which section is being reported is something a client chooses, and whose
// report it is is not.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

type Handler struct {
	store     *Store
	schoolOf  SchoolOf
	studentOf StudentOf
}

func NewHandler(store *Store, schoolOf SchoolOf, studentOf StudentOf) *Handler {
	return &Handler{store: store, schoolOf: schoolOf, studentOf: studentOf}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/reports", h.make)

	/* THE LIST IS THE STUDENT'S OWN AND NOBODY ELSE'S. It exists so the
	   interface can draw the control as already-used rather than inviting
	   somebody to report the same section twice — and it answers only what this
	   account said, which is the boundary that matters between students (P-05).

	   There is no route here that reads anybody else's: the queue is the
	   console's, behind the console's two gates. */
	mux.HandleFunc("GET /api/v1/reports", h.mine)
}

// The words the interface may choose between, sent with every answer.
//
// A SCREEN THAT HELD ITS OWN COPY OF THIS LIST would keep offering the old one
// after a reason was added, and the version that then arrives here is refused —
// so the list travels rather than being written down twice.
func lists() map[string]any {
	return map[string]any{"reasons": Reasons, "noteLimit": NoteLimit}
}

type madeBody struct {
	CourseID  string `json:"courseId"`
	LessonID  string `json:"lessonId"`
	SectionID string `json:"sectionId"`
	Reason    string `json:"reason"`
	Note      string `json:"note"`
}

func (h *Handler) make(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	var in madeBody
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 8<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that was not a report this understands")
		return
	}

	one, already, err := h.store.Make(r.Context(), New{
		School: school, Account: student,
		CourseID: in.CourseID, LessonID: in.LessonID, SectionID: in.SectionID,
		Reason: in.Reason, Note: in.Note,
	})
	switch {
	case errors.Is(err, ErrNoSuchSection):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound,
			"there is no such section in this school")
		return
	case errors.Is(err, ErrRefused):
		web.Fail(w, http.StatusBadRequest, "invalid", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("recording a report", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded — please try again")
		return
	}

	/* A SECOND REPORT IS NOT AN ERROR AND IT IS NOT A NEW REPORT. Answering
	   409 would put a failure in front of somebody who did nothing wrong; a
	   silent 201 would tell them the second note was kept when it was not. So
	   both answer 200 and say which happened, and the interface says "already
	   reported" in the one case and "thank you" in the other. */
	web.JSON(w, http.StatusOK, map[string]any{
		"id":        one.ID,
		"courseId":  one.CourseID,
		"lessonId":  one.LessonID,
		"sectionId": one.SectionID,
		"reason":    one.Reason,
		"note":      one.Note,
		"at":        one.ReportedAt,
		"already":   already,
	})
}

func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	rows, err := h.store.Mine(r.Context(), school, student)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a student's reports", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		out = append(out, map[string]any{
			"courseId":  one.CourseID,
			"lessonId":  one.LessonID,
			"sectionId": one.SectionID,
			"reason":    one.Reason,
			"at":        one.ReportedAt,
		})
	}

	answer := lists()
	answer["reports"] = out
	web.JSON(w, http.StatusOK, answer)
}

func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school, student uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a report route ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, uuid.Nil, false
	}

	student, ok = h.studentOf(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return uuid.Nil, uuid.Nil, false
	}
	return school, student, true
}
