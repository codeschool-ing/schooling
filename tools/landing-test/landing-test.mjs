/* ==========================================================================
   Schooling — the page says where it came from, and this is what holds it

   THE SERVER CANNOT SEE AN ARRIVAL. `visitor.Identify` is mounted on
   `/api/v1/`, and the page is served from `/` and never passes through it. So
   the request that reaches the middleware is an XHR the page fired: its
   `Referer` is this site, its path is an API route, and the campaign that
   brought somebody was in the address bar and is on no request at all.

   `ui/app/api.js` therefore reads `location.href` and `document.referrer` once
   at load and sends them as headers. Everything downstream of that is held by
   Go tests. THIS HOLDS THE HALF THEY CANNOT REACH: that a real page, in a real
   browser, actually sends them.

   It is a small thing to get wrong and an invisible thing when it is wrong.
   The headers can stop being sent by a refactor of the request helper, by a
   `fetch` that builds its own options, or by the capture running after the
   router has already rewritten the address — and every one of those leaves a
   site that works perfectly and a funnel that quietly answers with this site's
   own name.

   # WHAT IT DOES NOT CHECK

   The row. What the server believes of these headers — the fragment being the
   page, a rubbish header being ignored, an empty referrer meaning "typed the
   address" — is `internal/visitor`'s, where it can be checked without a
   browser. Two suites, one claim each.

       node tools/landing-test/landing-test.mjs [base url]

   Wants the same server the other browser suites use.
   ========================================================================== */

import { chromium } from 'playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';
const REFERRER = 'http://news.example.tld:8099/issue-4';

/* The campaign, written the way a link builder writes it: the query before the
   fragment, the route after it. */
const LANDING = `${BASE}/?utm_source=newsletter&utm_medium=email&utm_campaign=launch#/plans`;

const problems = [];
const fail = (what) => problems.push(what);

const browser = await chromium.launch({
  // The same trick the graph and accessibility suites use: a school answers on
  // its own host, and the host is what the server resolves it by.
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1, MAP news.example.tld 127.0.0.1'],
});
const context = await browser.newContext();

/* THE VISIT STARTS SOMEWHERE ELSE, because `document.referrer` is only
   populated by an actual navigation — setting a header would prove nothing
   about what a browser does. This page is fulfilled by the browser itself and
   never reaches the server. */
await context.route(`${new URL(REFERRER).origin}/**`, (route) =>
  route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: `<!doctype html><meta charset="utf-8"><a id="go" href="${LANDING}">go</a>`,
  }));

const page = await context.newPage();

const carried = [];
const bare = [];
page.on('request', (request) => {
  if (!request.url().includes('/api/v1/')) return;
  const headers = request.headers();
  if (headers['x-schooling-landing'] === undefined) bare.push(request.url());
  else carried.push({ url: request.url(), headers });
});

await page.goto(REFERRER);
await page.click('#go');
await page.waitForLoadState('networkidle');

if (carried.length === 0) {
  fail('no API request carried X-Schooling-Landing — the arrival is invisible to the server');
}
if (bare.length > 0) {
  fail(`${bare.length} API request(s) went without the headers, including ${bare[0]}`);
}

for (const { url, headers } of carried) {
  const landing = headers['x-schooling-landing'];
  const referrer = headers['x-schooling-landing-referrer'];

  if (landing !== LANDING) {
    fail(`${url} said it landed at ${landing}, and the browser opened ${LANDING}`);
  }

  /* Cross-origin over the same scheme sends the origin and not the path, which
     is the browser's default policy and not something to work around: the site
     that sent them is the answer the funnel wants. What must NOT happen is an
     empty one, or this site's own name. */
  if (!referrer) {
    fail(`${url} carried no referrer, so an arrival from a newsletter reads as a typed address`);
  } else if (referrer.startsWith(new URL(BASE).origin)) {
    fail(`${url} named this very site as the referrer (${referrer}) — the defect this exists for`);
  }
}

await browser.close();

if (problems.length > 0) {
  console.error('the page is not saying where it came from:');
  for (const problem of problems) console.error(`  ✗ ${problem}`);
  process.exit(1);
}

console.log(`✓ ${carried.length} API requests, each carrying the landing and the referrer`);
console.log(`  landing:  ${carried[0].headers['x-schooling-landing']}`);
console.log(`  referrer: ${carried[0].headers['x-schooling-landing-referrer']}`);
