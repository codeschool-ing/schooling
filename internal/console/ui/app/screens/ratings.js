/* ==========================================================================
   What they think of it — the one screen in this console that measures US.

   Every other reading here is about the students: how many arrived, how far
   they got, what they got wrong, who is present. This one runs the other way,
   and it carries the only evidence this platform can get that a course was not
   worth somebody's evening. The grader knows whether they answered it; the
   funnel knows whether they left; neither of those is that question.

   # IT DRAWS THE SPREAD, AND THE MEAN IS THE SMALL PRINT

   A mean of 3.0 where everybody said 3 and a mean of 3.0 where half said 1 and
   half said 5 are two different problems, and only one of them is urgent. A
   screen ranked by the mean would show them as the same course — so the five
   bars are the row and the mean sits beside them in small type, where it can be
   read and cannot be sorted by.

   # AND `depth` HAS NO GOOD END

   Too easy and too hard are both misses. Its mean is meaningless by
   construction — a flat spread and a serene 3 produce the same number — so the
   server sends the sentence saying so and this screen prints it under that row
   rather than leaving somebody to work it out.

   # ONE ROW PER RELEASE, WHICH IS WHAT MAKES IT ACTIONABLE

   A course rewritten because it scored badly has to be comparable to itself,
   and nobody writes the old number down before the rewrite. Each row is one
   subject at one release, in the order they happened, so a fix that worked
   looks like a fix that worked instead of a lifetime average sinking slowly.

   # NOBODY IS NAMED, AND THERE IS NOTHING TO WITHHOLD

   The queue on `Reported content` holds the reporter's account and declines to
   draw it, and says so on the screen. This is stronger and the screen says that
   too: the aggregate was built without ever reading who gave what, so there is
   no field here that a later change could start filling in.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt } from '../../assets/language.js';

/* THE SENTENCE BESIDE EACH ASPECT, in English here and translated where it is
   drawn. This map is evaluated once when the module loads, so a `txt()` in it
   would bake in whatever language was chosen at that moment and keep saying it
   after somebody switches — the same reason `reports.js` keeps its two maps in
   English. The key is the server's word and stays it.

   EACH IS TWO ENDS AND NOT A NAME, because that is what the student was shown:
   a bar chart under the word "padding" cannot be read without knowing which
   direction is bad, and under "padded → direct" it can. */
const ENDS = {
  completeness: { low: 'something was missing', high: 'nothing was missing' },
  padding: { low: 'padded', high: 'direct' },
  interest: { low: 'not interesting', high: 'interesting' },
  depth: { low: 'too easy', high: 'too hard' },
};

const KINDS = {
  course: 'Courses',
  track: 'Tracks',
  platform: 'This platform',
};

export default async function ratings(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('What they think of it')) + '</h1>' +
      '<p>' + esc(txt('What students say about a course as a whole, which no single '
        + 'section is responsible for and nothing else here can ask. It is counted and never '
        + 'attributed.')) + '</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">' +
      esc(txt('There are no schools on this platform yet, so there is nothing to have an opinion about.')) +
      '</p></section>';
    return { title: section.name, el };
  }

  const asking = { school: schools[0].id, kind: 'course' };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>' + esc(txt('What to look at')) + '</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>' + esc(txt('School')) + '</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +

        /* THE THREE KINDS ARE THREE QUESTIONS AND NOT ONE TABLE WITH A COLUMN.
           Every student meets a course, few finish a track, everybody is on the
           platform — three populations, and a screen showing all of them at
           once would be three tables somebody has to notice are unrelated. */
        '<label class="field">' +
          '<span>' + esc(txt('About')) + '</span>' +
          '<select id="kind">' +
            Object.keys(KINDS).map((k) =>
              '<option value="' + esc(k) + '">' + esc(txt(KINDS[k])) + '</option>').join('') +
          '</select>' +
        '</label>' +
      '</form>' +
    '</section>' +
    '<div id="rows"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const rows = body.querySelector('#rows');
  body.querySelector('#ask').addEventListener('change', (event) => {
    if (event.target.id === 'school') asking.school = event.target.value;
    if (event.target.id === 'kind') asking.kind = event.target.value;
    draw();
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    rows.innerHTML = '<p class="checking">' + esc(txt('Reading…')) + '</p>';

    /* WHAT WAS ASKED FOR IS HELD AND COMPARED WHEN THE ANSWER LANDS, because
       two selects mean somebody can change their mind while a read is in
       flight — and the slower answer arriving second would draw the school
       they just left. `reports.js` does this with one field; this has two. */
    const mine = asking.school + ':' + asking.kind;

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(asking.school) +
        '/ratings?kind=' + encodeURIComponent(asking.kind));
    } catch (e) {
      if (mine !== asking.school + ':' + asking.kind) return;
      rows.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) +
        '</p></section>';
      return;
    }
    if (mine !== asking.school + ':' + asking.kind) return;

    const all = answer.ratings || [];

    rows.innerHTML =
      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc(txt(KINDS[asking.kind] || asking.kind)) + '</h2>' +
          '<span class="block-score mono">' + all.length + '</span>' +
        '</div>' +

        /* NOTHING YET IS A REAL STATE AND NOT A FAILED READ, and on this screen
           it is the ordinary one for a long time: a rating is only offered to
           somebody who has FINISHED a course. */
        (all.length === 0
          ? '<p class="none">' + esc(txt('Nobody has rated anything here yet. The control is only offered to somebody who has finished, so this stays empty until the first person does.')) + '</p>'
          : all.map((one) => card(one, answer.aspects || [], answer.depth || '')).join('')) +

        '<p class="aside">' + esc(txt(answer.anonymous || '')) + '</p>' +
      '</section>';
  }

  /* One subject at one release.

     `warnAboutDepth` IS PASSED IN AND NOT READ FROM THE ANSWER, because this
     function is a sibling of `draw` rather than inside it and the answer is not
     in scope here. It is the server's sentence either way: a screen that wrote
     its own would be a screen that can forget to. */
  function card(one, aspects, warnAboutDepth) {
    const stars = one.stars || { at: [], count: 0, mean: 0 };
    return '<article class="rated">' +
      '<div class="rated-top">' +
        '<span class="rated-what mono">' + esc(one.subject_id || txt('the platform')) + '</span>' +
        '<span class="rated-version mono">' + esc(one.version) + '</span>' +
        '<span class="rated-count mono">' +
          esc(String(stars.count)) + ' ' + esc(txt('ratings')) + '</span>' +
      '</div>' +

      spread(txt('Stars'), stars, ['1', '5']) +

      aspects.map((name) => {
        const it = (one.aspects || {})[name];
        if (!it) return '';
        const ends = ENDS[name] || { low: name, high: name };
        return spread(txt(name), it, [txt(ends.low), txt(ends.high)]) +
          /* THE WARNING SITS UNDER THE ROW IT IS ABOUT, and it comes from the
             server so that the screen cannot forget to say it. */
          (name === 'depth' && warnAboutDepth
            ? '<p class="rated-warn">' + esc(txt(warnAboutDepth)) + '</p>'
            : '');
      }).join('') +
    '</article>';
  }

  /* Five bars, and the mean in small type beside them.

     THE BARS ARE THE ROW AND THE MEAN IS THE FOOTNOTE, which is the whole
     argument of this screen written as a layout: what is big is what should be
     read, and a mean read first is a mean that hides the shape under it. */
  function spread(label, it, ends) {
    const at = it.at || [];
    const most = Math.max(1, ...at.slice(1));
    let bars = '';
    for (let n = 1; n <= 5; n += 1) {
      const many = at[n] || 0;
      bars += '<span class="rated-bar" title="' + esc(String(n) + ': ' + many) + '">' +
        '<span class="rated-fill" style="height:' +
          Math.round((many / most) * 100) + '%"></span>' +
        '<span class="rated-n mono">' + esc(String(n)) + '</span>' +
      '</span>';
    }
    return '<div class="rated-row">' +
      '<span class="rated-label">' + esc(label) + '</span>' +
      '<span class="rated-end">' + esc(ends[0]) + '</span>' +
      '<span class="rated-bars">' + bars + '</span>' +
      '<span class="rated-end">' + esc(ends[1]) + '</span>' +
      '<span class="rated-mean mono">' +
        (it.count ? esc(it.mean.toFixed(1)) : '—') + '</span>' +
    '</div>';
  }
}
