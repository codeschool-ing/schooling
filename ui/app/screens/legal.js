/* ==========================================================================
   The terms and the privacy policy.

   TWO SCREENS THE PORTAL DOES NOT HAVE, and they are here because this
   deployment is a school with customers rather than one product's student area.
   They are the one thing in the interface that is not for a student: they are
   for whoever needs to read what happens to their data, which includes people
   who have not signed in and never will.

   SO THEY ARE OUTSIDE EVERY GATE. No session, no school, no plan. In the
   offline copy they are baked in like a lesson — a policy that answered "this
   needs the school" would be unpublished for whoever is reading a bundle on a
   train, and that reader is the one most likely to want it, since a file on a
   laptop is what gets handed to somebody else.

   The Markdown goes through the same renderer a lesson's prose uses, so a
   heading looks the same in a policy as in a course and there is one place for
   it to be wrong.
   ========================================================================== */

import * as api from '../api.js';
import { render } from '../markdown.js';
import { empty } from './common.js';
import { esc } from '../text.js';

const titleOf = (which) => (which === 'terms' ? txt('Terms of use') : txt('Privacy policy'));

/* The language the document is asked for is the one on screen, read the way
   everything else reads it — see `wanted()` in api.js and the comment there
   about the global that never existed. */
const locale = () => (document.documentElement.lang || 'en').toLowerCase().split('-')[0];

async function legal(which) {
  let doc;
  try {
    doc = await api.legal(which, locale());
  } catch (e) {
    return {
      title: titleOf(which),
      el: empty(txt('That document could not be read.')),
    };
  }

  const other = which === 'terms' ? 'privacy' : 'terms';
  const el = document.createElement('div');
  el.className = 'view screen-legal';
  el.innerHTML =
    '<header class="view-head">' +
      '<h1>' + esc(doc.title || titleOf(which)) + '</h1>' +
      /* The date it took effect is beside the title rather than at the foot:
         which version somebody is reading is the first thing they need to know
         about a document like this. */
      (doc.effective
        ? '<p>' + txt('In effect since') + ' ' + esc(doc.effective) + '</p>'
        : '') +
    '</header>' +
    '<section class="block"><div class="prose">' + render(doc.body) + '</div></section>' +
    '<p class="legal-other">' +
      '<a class="btn" href="#/' + other + '">' + titleOf(other) + ' →</a>' +
    '</p>';

  return { title: titleOf(which), el };
}

export const terms = () => legal('terms');
export const privacy = () => legal('privacy');
