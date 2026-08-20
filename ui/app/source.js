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

/* ---------- THE SCHOOL'S NAME, WHEREVER A NAME IS PRINTED ----------

   `codeschool.ing` was written into the interface in four places, and the one
   that matters is not on a screen: the certificate carries it on the sheet and
   in the name of the PNG a student downloads. A student of another school was
   handing an employer a document with somebody else's brand on it.

   THE NAME IS TWO PARTS BECAUSE THE DESIGN IS. `.cert-brand b` paints the tail
   in the accent, which is what makes `codeschool.ing` read as one word with a
   domain in it. Split at the LAST DOT rather than at `.ing`: a school called
   `Programming` has no dot and comes out whole, and one called `escola.dev`
   gets the same treatment codeschool.ing gets, without either being named
   here.

   `is()` answers whether there is a school yet, for the boot order. */
export const is = () => Boolean(school && school.name);
export const name = () => (school && school.name) || 'codeschool.ing';

export function brand() {
  const whole = name();
  const cut = whole.lastIndexOf('.');
  return cut > 0
    ? { head: whole.slice(0, cut), tail: whole.slice(cut) }
    : { head: whole, tail: '' };
}

/* For a file name: lowercase, and everything that is not a word becomes a
   dash. `codeschool.ing` → `codeschool-ing`, which is what it always was. */
export const fileBrand = () =>
  name().toLowerCase().replace(/[^\w]+/g, '-').replace(/^-|-$/g, '') || 'school';

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
    /* TWO NAMES. `id` is opaque and permanent — it is what `requires`, a
       track's steps and every progress row point at. `slug` is readable and is
       what an address shows. See `catalog.js` for the two lookups, and never
       build a link out of an id. */
    id: c.id,
    slug: c.slug || c.id,
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

/* Which language the catalogue was last fetched in. The school's own rows carry
   the translations now, so a language switch is a REQUEST rather than a
   dictionary lookup — see `reload` below and `redrawAll` in main.js. */
export let loadedLocale = null;

const wanted = () => (document.documentElement.lang || 'en').toLowerCase().split('-')[0];

export const languageChanged = () => loadedLocale !== null && loadedLocale !== wanted();

export async function load(api) {
  const locale = wanted();
  const lang = '?lang=' + encodeURIComponent(locale);
  const [courses, tracks, about] = await Promise.all([
    api.get('/api/v1/courses' + lang).catch(() => null),
    api.get('/api/v1/tracks' + lang).catch(() => null),
    api.get('/api/v1/school').catch(() => null),
  ]);
  loadedLocale = locale;

  COURSES.length = 0;
  ((courses && courses.courses) || []).forEach((c) => COURSES.push(courseFrom(c)));

  TRACKS.length = 0;
  ((tracks && tracks.tracks) || []).forEach((t) => TRACKS.push({
    id: t.id,
    slug: t.slug || t.id,
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

  /* ---------- THE SCHOOL'S OWN PRICE ----------

     `plans.js` is the portal's file and it carries codeschool.ing's offer: one
     yearly subscription at 490, with `R$` written into the markup beside it.
     Every school was quoting that.

     THE SHAPE OF THE OFFER IS THE PLATFORM'S and stays in the file — the first
     course of every track free, one yearly subscription for the rest, and a
     list of feature KEYS the server authorises by. What is the school's is the
     NUMBER, so only the number is replaced, before `saveBase()` snapshots the
     plans for translation.

     A school with no price set keeps none: `price` goes to zero and the screen
     that would name it says what the subscription opens instead. */
  const paid = (globalThis.PLANS || []).find((p) => p.id === 'student');
  if (paid && school) {
    paid.price = (school.planPriceCents || 0) / 100;
    paid.currency = school.planCurrency || '';
  }

  return { courses: COURSES.length, tracks: TRACKS.length };
}
