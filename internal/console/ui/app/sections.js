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

export const SECTIONS = [
  { id: 'record', name: 'Student record', group: 'Operate', screen: studentRecord },
  { id: 'people', name: 'Personal data', group: 'Govern', screen: people },
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
