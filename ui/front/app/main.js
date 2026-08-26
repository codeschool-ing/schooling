/* ==========================================================================
   The platform's front door — boot.

   THERE IS ALMOST NOTHING HERE ON PURPOSE. What the platform's front page
   should say is not settled, and a page written to fill the space would be a
   design nobody agreed to, standing at the most public address this platform
   has. So this file boots the shell, remembers the theme, and stops.

   WHAT IS SETTLED IS EVERYTHING AROUND IT, and that is what the pull request
   this arrives in is about: which host answers, which tree is served, that the
   address is indexable, and that it asks nothing of anybody.

   # WHEN THERE IS A PAGE, THIS IS WHERE IT STARTS

   No router, for `my.`'s reason: one address, one screen, and a fragment router
   would be machinery for a choice nobody is offered. The day this page has
   destinations is the day to add one, with somewhere to go to justify it.

   And whatever it draws will need data, which is not fetched here yet — there
   is nothing to fetch it for. When it is, `visitor.Identify` belongs on that
   route, so that somebody who reads about the platform here and then opens a
   school is ONE visitor rather than two; the cookie is on the parent domain
   and has been since before this address answered anything.
   ========================================================================== */

/* ---------- the theme ----------

   The study interface's key, so the choice made at a school and the choice made
   here are the same word in two origins' storage. They cannot be the same
   VALUE — `localStorage` is per origin — and at this address that matters less
   than anywhere: most people arriving have never been here before. */
const THEME = 'codeschool-theme';

const themeButton = document.getElementById('theme');
if (themeButton) {
  themeButton.addEventListener('click', () => {
    const light = document.documentElement.dataset.theme === 'light';
    if (light) {
      delete document.documentElement.dataset.theme;
    } else {
      document.documentElement.dataset.theme = 'light';
    }
    try {
      localStorage.setItem(THEME, light ? 'dark' : 'light');
    } catch (e) { /* private mode: the choice holds for this page and no longer */ }
  });
}
