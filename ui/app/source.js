/* ==========================================================================
   Where the catalogue comes from.

   THIS FILE IS WHY THE COPY WORKS FOR MANY SCHOOLS. Over there `COURSES` and
   `TRACKS` are two `const`s in a file that ships with the portal, because the
   portal is one school. Here they are filled, before anything renders, from the
   API of whichever school the address names — and after that every copied file
   reads them exactly as it always did.

   THE GLOBALS ARE THE CONTRACT AND THEY ARE KEPT. `app/catalog.js`,
   `i18n-runtime.js` and a dozen screens read `COURSES` and `TRACKS` by name;
   turning them into imports would have been a change to every one of those
   files, which is the opposite of copying them.

   THEY ARE FILLED ONCE AND NEVER REPLACED, so a screen cannot hold a reference
   to last school's array: the arrays are created here and their contents are
   pushed into them, which matters because `i18n-runtime.js` translates the
   catalogue IN PLACE.
   ========================================================================== */

const COURSES = [];
const TRACKS = [];

globalThis.COURSES = COURSES;
globalThis.TRACKS = TRACKS;

/* The school itself — name and accent — which the bar and the title read. */
export let school = null;

/* A step of a track is either a course id or a fork. The API answers the same
   shape the portal's file declares, because both were written from the same
   decision about what a track is; what differs is only that this one arrives
   over HTTP. */
function stepsOf(track) {
  return (track.steps || track.courses || []).map((step) => {
    if (typeof step === 'string') return step;
    if (step.course) return step.course;
    return {
      choice: step.choice,
      note: step.note,
      options: (step.options || []).map((o) => ({ name: o.name, courses: o.courses || [] })),
    };
  });
}

/* WHAT A COURSE LOOKS LIKE TO THE COPIED SCREENS. Every field the portal's
   catalogue declares, filled from this API — including `topics`, which is not
   decoration here: `courseLessons` in the copied `app/catalog.js` derives a
   course's LESSONS from it, so a course whose topics were dropped would be a
   course with no lessons on every screen. */
function courseFrom(c) {
  return {
    id: c.id,
    name: c.name,
    category: c.category,
    level: c.level,
    hours: c.hours,
    summary: c.summary,
    syllabus: c.syllabus || [],
    topics: c.topics || [],
    requires: c.requires || [],
    prerequisites: c.prerequisites || '',
    /* Not the portal's fields, and carried anyway: the paywall is decided by
       the server here, per plan and per school, and the screens that draw a
       locked course read them. */
    free: c.free,
    locked: c.locked,
    sections: c.sections,
  };
}

export async function load(api) {
  const [courses, tracks, about] = await Promise.all([
    api.get('/api/v1/courses').catch(() => null),
    api.get('/api/v1/tracks').catch(() => null),
    api.get('/api/v1/school').catch(() => null),
  ]);

  COURSES.length = 0;
  ((courses && courses.courses) || []).forEach((c) => COURSES.push(courseFrom(c)));

  TRACKS.length = 0;
  ((tracks && tracks.tracks) || []).forEach((t) => TRACKS.push({
    id: t.id,
    name: t.name,
    goal: t.goal || '',
    outcome: t.outcome || '',
    courses: stepsOf(t),
    /* `links` IS THE TRACK'S OWN SEQUENCE — "here, this one comes after that
       one" — and it is the other half of the rule that `requires` is knowledge
       only. It draws an arrow in this track and nowhere else.

       It was an empty list here for a while, on the reasoning that the track's
       order already says it. The order says WHERE a course sits, not what it
       follows: without the links the graph falls back to the previous step, so
       what was lost was not an arrow but the RIGHT arrow — the front-end map
       drew fourteen edges where the vitrine draws seventeen. */
    links: t.links || {},
    continues: t.continues || null,
  }));

  school = about || null;
  return { courses: COURSES.length, tracks: TRACKS.length };
}
