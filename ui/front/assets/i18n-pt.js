/* ==========================================================================
   The platform's front door — the Portuguese of it.

   IT HAS ONE ENTRY, AND THAT IS NOT AN OVERSIGHT. The page this dictionary
   belongs to is empty on purpose: what the platform's front page should say is
   not settled, and the only string on screen today is the label on the theme
   button. Every sentence the page eventually says lands here beside it.

   THIS IS THIS ADDRESS'S DICTIONARY AND NOBODY ELSE'S, for the reason `my.`'s
   header gives: the study interface says hundreds of things this screen never
   says, and one dictionary shared between two interfaces makes every string of
   the one read as a stale entry to the other — which is precisely what
   `check-interface` reports and precisely what it is for. CI runs it against
   this directory as a third invocation, so the first string added here without
   its Portuguese fails a pull request exactly as it does over there.

   IT ASSIGNS RATHER THAN MERGES, because at this origin there is nothing to
   merge into: `i18n.js` before it carries es, fr and it, and no other file
   writes `pt`.

   THE KEY IS THE ENGLISH STRING, as everywhere in this organisation: there is
   no `en` dictionary because it would be an identity map.
   ========================================================================== */

window.I18N = window.I18N || {};
window.I18N.pt = window.I18N.pt || {};
window.I18N.pt.ui = {
  'Switch theme': 'Trocar o tema',
};
