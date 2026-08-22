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

export const SECTIONS = [
  { id: 'people', name: 'Personal data', group: 'Govern', screen: people },
];

/* A DETAIL IS A ROUTE WITH NO RAIL ENTRY — one person's record is not a place
   in the navigation, but it is an address that has to survive a reload and a
   pasted link. There are none yet; the shape is here because the router takes
   them and a reader should not have to find that out from the router. */
export const DETAILS = [];

/* The order the rail's groups appear in, when there are sections to put in
   them. Empty ones are skipped, so this is settled before the screens are.

   THE SAME THREE JOBS `PLAN.md` SAYS MUST NOT MIX, minus the one that is not a
   screen: operate (now), understand (aggregates), watch (seconds) and audit
   (history). `Measure` is `understand` and `Watch`, which the rail can afford
   to fold together and the code cannot. */
export const GROUPS = ['Measure', 'Operate', 'Govern'];

export const sectionById = (id) => SECTIONS.find((s) => s.id === id) || null;
