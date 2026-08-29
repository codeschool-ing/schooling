/* ==========================================================================
   The console's sections — the rail, and the route behind each entry.

   ONE ENTRY, AND THAT IS HONEST. The console starts from the obligation phase 0
   is waiting on and nothing else: no placeholder standing in for work that has
   not been done, no rail entry leading to "coming soon". A section exists once
   something is built behind it, and until then the rail is quieter for not
   naming it.

   `docs/CONSOLE.md` lists what the console IS, whole — the funnel, cohorts,
   item analysis, presence, the map, the parameters, view-as-student, the audit.
   That list is the plan; this one is the state. Adding a section is one object
   here and the module it names: the route, the rail entry and the empty state
   follow from it, and nothing else has to be told.

     `id`     the route (`#/people`) and the rail's key. Lower case, no spaces.
     `name`   what the rail shows.
     `group`  the heading it sits under. A group with no sections is skipped, so
              GROUPS can hold names before it holds entries.
     `screen` the module: `async (section) => ({ title, el, after?, onLeave? })`
   ========================================================================== */

import people from './screens/people.js';
import history, { byActor, onSubject, entry } from './screens/history.js';
import studentRecord, { record } from './screens/record.js';
import schools from './screens/schools.js';
import plan from './screens/plan.js';
import parameters from './screens/settings.js';
import funnel from './screens/funnel.js';
import questions from './screens/questions.js';
import cohorts from './screens/cohorts.js';
import countries from './screens/countries.js';
import presence from './screens/presence.js';
import reports from './screens/reports.js';
import jobs from './screens/jobs.js';
import staff from './screens/staff.js';

export const SECTIONS = [
  /* WHO IS HERE COMES FIRST, and it is the only entry under `Measure` that is
     not an aggregate — the group's comment below says the rail folds `watch`
     into `understand` and the code does not. It is the question somebody opens
     this console to ask on the way to asking anything else, and the one that is
     worthless five minutes old, so it sits above the reports it has nothing in
     common with rather than after them. */
  { id: 'presence', name: 'Who is here', group: 'Measure', screen: presence },

  /* JOBS SITS BESIDE PRESENCE because it is the same job of the four — `watch`,
     measured in seconds rather than in days — and not beside the funnel it
     produces. It is also the only section here whose subject is US: whether the
     machinery behind another screen ran at all. */
  { id: 'jobs', name: 'Jobs', group: 'Measure', screen: jobs },
  { id: 'funnel', name: 'The funnel', group: 'Measure', screen: funnel },
  { id: 'questions', name: 'Questions', group: 'Measure', screen: questions },
  { id: 'cohorts', name: 'Cohorts', group: 'Measure', screen: cohorts },

  /* WHERE THEY ARE IS LAST UNDER `Measure`, and it is named for the question
     it answers rather than for the picture on it. There IS a world map on this
     screen — but the map cannot say how many, and the ranked list under it is
     what somebody came for. A rail entry called "the map" would promise the
     half that is decoration. */
  { id: 'countries', name: 'Where they are', group: 'Measure', screen: countries },
  /* REPORTED CONTENT IS FIRST UNDER `Operate`, above the record and the
     schools, because it is the only section in this console that somebody
     outside it is waiting on. The other two are opened when an operator has a
     question; this one is opened because a student had one. */
  { id: 'reports', name: 'Reported content', group: 'Operate', screen: reports },
  { id: 'record', name: 'Student record', group: 'Operate', screen: studentRecord },
  { id: 'schools', name: 'Schools', group: 'Operate', screen: schools },

  /* WHAT IT COSTS IS ITS OWN SECTION AND NOT A PANEL UNDER `schools`. It was
     one — a price form under every school's colour — until `0041` moved the
     price to the platform, because one subscription opens every school (N-02).
     A form on a school's page would now change what everybody pays from a
     screen about one school. */
  { id: 'plan', name: 'What it costs', group: 'Operate', screen: plan },

  /* AND WHAT IT IS SET TO, BESIDE WHAT IT COSTS AND NOT INSIDE IT. The two are
     the same job — deciding something the whole platform then behaves by — and
     they are different subjects: one is the offer, and a price is appended
     because a March invoice has to stay explicable in November. The other is
     every remaining knob, replaced rather than appended, because none of them
     is money.

     IT IS LAST UNDER `Operate` on purpose. The three above it are opened
     because somebody has a question about a person or a school; this one is
     opened to change how the system behaves for everybody, which is the rarer
     and larger act and does not want to be the first thing under the heading. */
  { id: 'settings', name: 'What it is set to', group: 'Operate', screen: parameters },
  { id: 'people', name: 'Personal data', group: 'Govern', screen: people },

  /* WHO CAN OPEN THIS, BETWEEN THE TWO IT BELONGS WITH. `Personal data` is what
     this console holds about somebody; the history is what it did about them;
     this is who was able to do it. The three are one question asked from three
     sides, and it sits in the middle because the roster is what makes the other
     two reviewable rather than merely available.

     IT IS NOT WHAT K-22 GOVERNS — see `console/staff.go`. That decision is
     about listing STUDENTS, and it has since been amended: the section above
     lists them now, under four conditions. Neither version reaches this one.
     There is no reviewing an access-control list an address at a time, because
     the whole question is who is on it that nobody thought to ask about. */
  { id: 'staff', name: 'Who can open this', group: 'Govern', screen: staff },

  { id: 'audit', name: 'History', group: 'Govern', screen: history },
];

/* A DETAIL IS A ROUTE WITH NO RAIL ENTRY — one entry of the history is not a
   place in the navigation, but it is an address that has to survive a reload
   and a pasted link.

   THE TWO FILTERED LISTS ARE HERE FOR THE SAME REASON. "One actor's entries"
   and "everything done to one subject" are the two questions this section
   answers besides the plain one, and a filter that lives in a variable is a
   filter somebody has to describe over the phone. All three sit under `audit/`,
   so the rail stays lit on the section they belong to. */
export const DETAILS = [
  { path: '/record/:id', screen: record },
  { path: '/audit/entry/:id', screen: entry },
  { path: '/audit/by/:actor', screen: byActor },
  { path: '/audit/on/:kind/:subject', screen: onSubject },
];

/* The order the rail's groups appear in, when there are sections to put in
   them. Empty ones are skipped, so this is settled before the screens are.

   THE SAME THREE JOBS `PLAN.md` SAYS MUST NOT MIX, minus the one that is not a
   screen: operate (now), understand (aggregates), watch (seconds) and audit
   (history). `Measure` is `understand` and `Watch`, which the rail can afford
   to fold together and the code cannot. */
export const GROUPS = ['Measure', 'Operate', 'Govern'];

export const sectionById = (id) => SECTIONS.find((s) => s.id === id) || null;
