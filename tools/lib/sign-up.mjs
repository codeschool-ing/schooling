/* ==========================================================================
   Signing a student up through the form.

   IT IS HERE BECAUSE TWO SUITES DO IT AND ONE OF THEM WAS WRONG. The
   accessibility pass and the second-factor round trip both need an account and
   both must make one the way a person does — through the screen, because a
   suite that posts to `/api/v1/sign-up` proves the API works and says nothing
   about the form. Written out twice, the fix below would have landed in one of
   them.

   # WHAT WENT WRONG, WHICH IS NOT WHAT IT LOOKED LIKE

   CI failed on `main` with a timeout waiting for `POST /api/v1/sign-up`, and the
   server's log showed what had arrived instead: `POST /api/v1/sign-in`, 401.

   The screen is ONE screen in two modes — `#e-toggle` swaps between signing in
   and registering, and `mode` is a variable inside the closure that draws the
   form. Nothing in the document says which mode it is in except that the name
   field exists in one of them. And the screen is REBUILT after it is first
   drawn: the language is applied at boot and calls the router again, so a fresh
   sign-in screen replaces the one on the glass, in the default mode, with empty
   inputs.

   So the old sequence — toggle, wait for the name field, fill three inputs,
   submit — has a window in it. Fill the fields, have the screen rebuilt
   underneath, and the submit that follows goes to the form that is there now:
   sign-in mode, empty fields, and `novalidate` on the form so the browser does
   not stop it. What comes back is a 401 for a person who does not exist, and
   the suite sits waiting fifteen seconds for a request that was never going to
   be made.

   # SO IT IS CHECKED RATHER THAN TIMED

   The form is filled and then READ BACK — the name field still there, the
   values still the ones that were typed — and only submitted once that holds.
   If the screen rebuilt in between, the whole thing is done again on the form
   that replaced it, up to a few times.

   And the response is checked for WHICH endpoint answered. If a sign-in comes
   back where a sign-up was asked for, that is said in one line instead of
   arriving as a timeout that names none of its causes.
   ========================================================================== */

const PASSWORD = 'a long enough password here';

export async function signUpThroughTheForm(page, base, { name, email,
  password = PASSWORD, tries = 4 } = {}) {

  await page.goto(`${base}/#/sign-in`, { waitUntil: 'load' });
  await page.waitForSelector('#content[data-screen="/sign-in"]', { timeout: 10000 });

  for (let go = 1; ; go += 1) {
    await page.waitForSelector('#e-toggle', { timeout: 8000 });

    // Already in register mode is the ordinary case on a second pass: toggling
    // again would take it back to signing in.
    if (!(await page.locator('#e-name').count())) {
      await page.click('#e-toggle');
      await page.waitForSelector('#e-name', { timeout: 8000 });
    }

    await page.fill('#e-name', name);
    await page.fill('#e-email', email);
    await page.fill('#e-password', password);

    /* THE PAUSE IS A WINDOW FOR THE REBUILD TO HAPPEN IN, not a hope that it
       has: what settles this is the read below, and the wait only decides how
       long the read has to become wrong. */
    await page.waitForTimeout(200);

    const held = await page.evaluate(([n, a]) => {
      const named = document.querySelector('#e-name');
      const address = document.querySelector('#e-email');
      const secret = document.querySelector('#e-password');
      return Boolean(named && named.value === n
        && address && address.value === a
        && secret && secret.value);
    }, [name, email]);

    if (held) break;
    if (go >= tries) {
      throw new Error(`the sign-in screen kept being rebuilt under the form: after ${tries} `
        + 'attempts the fields were empty or the register mode had gone. Submitting now would '
        + 'send a sign-in for somebody who does not exist yet.');
    }
  }

  const [answered] = await Promise.all([
    page.waitForResponse((r) => {
      const path = new URL(r.url()).pathname;
      return path === '/api/v1/sign-up' || path === '/api/v1/sign-in';
    }, { timeout: 15000 }),
    page.click('#form-signin button[type=submit]'),
  ]);

  const path = new URL(answered.url()).pathname;
  if (path !== '/api/v1/sign-up') {
    throw new Error(`the form was submitted as ${path} rather than a sign-up, which means it `
      + 'was in the wrong mode when the button was pressed');
  }
  if (!answered.ok()) {
    throw new Error(`signing a student up: ${answered.status()} ${await answered.text()}`);
  }

  /* THE APP AND NOT THE RESPONSE. Signing up lands on the dashboard, and the
     state that says who is signed in is written on the way there — navigating
     on the 201 alone is a hash change into a screen whose session has not
     arrived, which sends it straight back to sign-in. */
  await page.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 15000 });
}
