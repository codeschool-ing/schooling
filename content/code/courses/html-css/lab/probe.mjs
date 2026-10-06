/* probe opens a page in Chromium and prints what the browser made of it.
 *
 * Every number in this course that describes a rendered page was printed by
 * this file: a box's position and size, a computed value, which element sits
 * on top at a point, what a form would send. It asks the browser the same
 * questions the Elements panel of DevTools answers when you click on
 * something, and prints the answers as text so that a lesson can quote them.
 *
 *   probe [--width W] [--height H] [--dpr D] [--mobile] PAGE STEP...
 *
 * --hold-images keeps every image request waiting until a `release` step, so
 * that a page can be measured as it is before its pictures arrive.
 *
 * --mobile behaves like a phone's browser: it honours the viewport meta tag,
 * and without one it lays the page out 980 pixels wide and shrinks it to fit.
 *
 * The steps run in order, against one page, and each prints its own lines:
 *
 *   mode                  the rendering mode, standards or quirks
 *   dom                   the document as the parser built it
 *   title                 the document's title
 *   window                the window's inner size and its device pixel ratio
 *   text SEL              the text of every element SEL matches
 *   box SEL               position and size of every element SEL matches
 *   match SEL             which elements a selector matches
 *   style SEL PROP,...    computed values of the named properties; SEL may end
 *                         in ::before, ::after or ::marker
 *   rules SEL PROP        every rule that sets PROP on the element, in cascade
 *                         order, as the Styles panel of DevTools lists them
 *   tree [SEL]            the accessibility tree, as Playwright writes it
 *   axe                   the axe-core rules the page fails
 *   describe SEL          role, name, description and states, as a screen reader gets them
 *   validity SEL          a form field's validity and its message
 *   send SEL              presses SEL and prints the request the form made
 *   top X Y               the element painted on top at a point
 *   img SEL               which file an <img> chose, and its pixel size
 *   fetched               every file the page has asked for so far, once each
 *   release               lets the images held by --hold-images arrive
 *   scroll Y              scrolls the page to Y
 *   at MS                 freezes every animation at MS milliseconds
 *   width W               resizes the window to W pixels wide
 *   overflow              whether the page is wider than the window
 *   tab                   presses Tab and prints what has the focus now
 *   press KEY             presses a key, such as Enter or Space
 *   fill SEL TEXT · check SEL · click SEL · hover SEL · focus SEL
 *   shot FILE             a screenshot, for the author to look at
 *
 * The page is opened from disk. Nothing is fetched from a network: a request
 * that is not a file is answered with an empty 204 and listed by `fetched`.
 */
import { chromium } from 'playwright';
import { resolve, basename } from 'node:path';

const require = (await import('node:module')).createRequire(import.meta.url);

const argv = process.argv.slice(2);
const opt = { width: 1024, height: 768, dpr: 1, mobile: false };
while (argv[0]?.startsWith('--')) {
  const k = argv.shift().slice(2);
  if (k === 'mobile') opt.mobile = true;
  else if (k === 'hold-images') opt.hold = true;
  else opt[k] = Number(argv.shift());
}
const file = argv.shift();
if (!file) {
  console.error('usage: probe [--width W] [--height H] [--dpr D] [--mobile] PAGE STEP...');
  process.exit(2);
}

const n = (v) => String(Math.round(v * 100) / 100);
const pad = (s, w) => (s.length >= w ? s + ' ' : s + ' '.repeat(w - s.length));

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: opt.width, height: opt.height },
  deviceScaleFactor: opt.dpr,
  isMobile: opt.mobile,
  hasTouch: opt.mobile,
});
const page = await context.newPage();
const fetched = [];
const sheets = new Map();
let sent = null;
let opened = false;
const held = [];
await page.route('**/*', async (route) => {
  const req = route.request();
  const url = new URL(req.url());
  if (!opened && req.isNavigationRequest()) {
    opened = true;
    return route.continue();
  }
  if (url.protocol === 'file:' && req.method() === 'GET' && !req.isNavigationRequest()) {
    const f = basename(url.pathname) + url.search;
    if (!fetched.includes(f)) fetched.push(f);
    if (opt.hold && req.resourceType() === 'image') {
      return new Promise((done) => held.push(() => route.continue().then(done)));
    }
    return route.continue();
  }
  /* Anything else is a request the page made somewhere: a form being sent,
     usually. It is recorded and answered with nothing, so that the page stays
     where it is and no network is involved. */
  sent = { method: req.method(), url: '/' + url.pathname.split('/').pop() + url.search,
           body: req.postData(), type: req.headers()['content-type'] };
  fetched.push(url.pathname.split('/').pop() + url.search);
  return route.fulfill({ status: 204, body: '' });
});
page.on('pageerror', (e) => console.log('page error: ' + e.message));

await page.goto('file://' + resolve(file), { waitUntil: opt.hold ? 'domcontentloaded' : 'load' });
/* document.fonts.ready also waits for the page's pending loads in Chromium,
   so with images held it would wait for ever; those pages use no web fonts. */
if (!opt.hold) await page.evaluate(() => document.fonts.ready);

/* What an element is called in the output: its tag, then its id or its first
   class, then its position among the matches when there is more than one. */
const label = (el) => el.evaluate((e) => {
  let s = e.tagName.toLowerCase();
  if (e.id) s += '#' + e.id;
  else if (e.classList.length) s += '.' + [...e.classList].join('.');
  return s;
});

const steps = {
  async mode() {
    console.log('compatMode: ' + (await page.evaluate(() => document.compatMode)));
  },
  async title() {
    console.log('title: ' + JSON.stringify(await page.title()));
  },
  async window() {
    const v = await page.evaluate(() => [innerWidth, innerHeight, devicePixelRatio]);
    console.log(`window: ${v[0]}×${v[1]}, device pixel ratio ${v[2]}`);
  },
  async text(sel) {
    for (const el of await page.$$(sel)) {
      console.log(`${await label(el)}  ${JSON.stringify(await el.evaluate((e) => e.textContent))}`);
    }
  },
  async json(sel) {
    const out = [];
    for (const el of await page.$$(sel)) {
      const b = await el.evaluate((e) => {
        const r = e.getBoundingClientRect();
        return { x: r.x + scrollX, y: r.y + scrollY, w: r.width, h: r.height };
      });
      out.push({ label: await label(el), ...b });
    }
    console.log(JSON.stringify(out));
  },
  async dom() {
    console.log(await page.evaluate(() => document.documentElement.outerHTML));
  },
  async box(sel) {
    const els = await page.$$(sel);
    if (!els.length) console.log(sel + ': nothing matches');
    const rows = [];
    for (const el of els) {
      const b = await el.evaluate((e) => {
        const r = e.getBoundingClientRect();
        return { x: r.x + scrollX, y: r.y + scrollY, w: r.width, h: r.height };
      });
      rows.push([await label(el), b]);
    }
    const w = Math.max(...rows.map((r) => r[0].length)) + 2;
    for (const [l, b] of rows) {
      console.log(pad(l, w) + `x ${pad(n(b.x), 7)}y ${pad(n(b.y), 7)}width ${pad(n(b.w), 7)}height ${n(b.h)}`);
    }
  },
  async match(sel) {
    const els = await page.$$(sel);
    console.log(`${sel}  matches ${els.length}`);
    for (const el of els) {
      const t = await el.evaluate((e) => e.textContent.replace(/\s+/g, ' ').trim());
      console.log(`  ${await label(el)}  "${t.length > 36 ? t.slice(0, 35) + '…' : t}"`);
    }
  },
  /* Every rule that sets PROP on the element, in the order the cascade
     considers them, with the selector's specificity and where it came from.
     The last one listed that is not crossed out is the one that applies, which
     is the same list the Styles panel of DevTools draws, read from the same
     place: Chromium's DevTools protocol. */
  async rules(sel, prop) {
    const cdp = await page.context().newCDPSession(page);
    cdp.on('CSS.styleSheetAdded', (e) => sheets.set(e.header.styleSheetId,
      e.header.isInline ? '<style> in the page' : basename(e.header.sourceURL)));
    await cdp.send('DOM.enable');
    await cdp.send('CSS.enable');
    const { root } = await cdp.send('DOM.getDocument', { depth: -1 });
    const { nodeId } = await cdp.send('DOM.querySelector', { nodeId: root.nodeId, selector: sel });
    const m = await cdp.send('CSS.getMatchedStylesForNode', { nodeId });
    const out = [];
    for (const r of m.matchedCSSRules || []) {
      for (const d of r.rule.style.cssProperties) {
        if (d.name !== prop || d.disabled || d.value === undefined || !d.range && r.rule.origin !== 'user-agent') continue;
        const sels = r.rule.selectorList.selectors;
        const s = sels[r.matchingSelectors[r.matchingSelectors.length - 1]];
        const sp = s.specificity ? `(${s.specificity.a},${s.specificity.b},${s.specificity.c})` : '';
        const where = r.rule.origin === 'user-agent' ? 'browser default'
          : (r.rule.styleSheetId && r.rule.origin === 'regular' ? sheetName(m, r) : r.rule.origin);
        const layer = (r.rule.layers || []).map((l) => l.text).filter(Boolean).join('.');
        out.push({ text: `${s.text} ${sp}`, value: d.value + (d.important && !d.value.includes('!important') ? ' !important' : ''), where: where + (layer ? ' @layer ' + layer : ''), important: !!d.important });
      }
    }
    if (m.inlineStyle) for (const d of m.inlineStyle.cssProperties) {
      if (d.name === prop && d.range) out.push({ text: 'style attribute', value: d.value + (d.important && !d.value.includes('!important') ? ' !important' : ''), where: 'inline', important: !!d.important });
    }
    if (!out.length) { console.log(`${sel}  no rule sets ${prop}`); return; }
    const winner = await page.$eval(sel, (e, p) => getComputedStyle(e).getPropertyValue(p), prop);
    const w = Math.max(...out.map((o) => o.text.length)) + 2;
    for (const o of out) console.log(pad(o.text, w) + pad(`${prop}: ${o.value}`, 32) + o.where);
    console.log(`computed ${prop}: ${winner}`);
    function sheetName(mm, rr) { return sheets.get(rr.rule.styleSheetId) || 'stylesheet'; }
  },
  async style(sel, props) {
    const pseudo = sel.match(/(::[a-z-]+)$/);
    if (pseudo) {
      const base = sel.slice(0, -pseudo[1].length);
      for (const el of await page.$$(base)) {
        const vals = await el.evaluate((e, [ps, pe]) => {
          const cs = getComputedStyle(e, pe);
          return ps.map((p) => [p, cs.getPropertyValue(p)]);
        }, [props.split(','), pseudo[1]]);
        const l = await label(el);
        for (const [p, v] of vals) console.log(`${l}${pseudo[1]}  ${p}: ${v}`);
      }
      return;
    }
    const els = await page.$$(sel);
    if (!els.length) console.log(sel + ': nothing matches');
    for (const el of els) {
      const vals = await el.evaluate((e, ps) => {
        const cs = getComputedStyle(e);
        return ps.map((p) => [p, cs.getPropertyValue(p)]);
      }, props.split(','));
      const l = await label(el);
      for (const [p, v] of vals) console.log(`${l}  ${p}: ${v}`);
    }
  },
  async tree(sel = 'body') {
    console.log(await page.locator(sel).first().ariaSnapshot());
  },
  async axe() {
    await page.addScriptTag({ path: require.resolve('axe-core/axe.min.js') });
    const r = await page.evaluate(() => window.axe.run(document, {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'] },
    }));
    if (!r.violations.length) console.log('axe: no violations');
    for (const v of r.violations) {
      console.log(`${v.id} (${v.impact}, ${v.nodes.length} element${v.nodes.length > 1 ? 's' : ''}): ${v.help}`);
    }
  },
  /* What assistive technology is told about one element: its role, its name,
     its description and the states that matter for a form field. Read from
     Chromium's own accessibility tree through the DevTools protocol. */
  async describe(sel) {
    const cdp = await page.context().newCDPSession(page);
    const { root } = await cdp.send('DOM.getDocument', { depth: -1 });
    const { nodeIds } = await cdp.send('DOM.querySelectorAll', { nodeId: root.nodeId, selector: sel });
    for (const nodeId of nodeIds) {
      const { nodes } = await cdp.send('Accessibility.getPartialAXTree', { nodeId, fetchRelatives: false });
      const n = nodes[0];
      const props = Object.fromEntries((n.properties || []).map((p) => [p.name, p.value.value]));
      const out = [`role ${n.role?.value}`, `name ${JSON.stringify(n.name?.value ?? '')}`];
      if (n.description?.value) out.push(`description ${JSON.stringify(n.description.value)}`);
      for (const k of ['required', 'invalid']) if (props[k] && props[k] !== 'false') out.push(k === 'invalid' ? 'invalid' : k);
      console.log(out.join(', '));
    }
  },
  async validity(sel) {
    for (const el of await page.$$(sel)) {
      const v = await el.evaluate((e) => {
        const flags = [];
        for (const k in e.validity) if (e.validity[k]) flags.push(k);
        return { value: e.value, flags, msg: e.validationMessage };
      });
      console.log(`${await label(el)}  value ${JSON.stringify(v.value)}  ${v.flags.join(' ')}` +
        (v.msg ? `\n  message: ${v.msg}` : ''));
    }
  },
  async send(sel) {
    sent = null;
    await page.click(sel);
    await page.waitForTimeout(300);
    if (!sent) {
      const invalid = await page.evaluate(() =>
        [...document.querySelectorAll(':invalid')].filter((e) => e.tagName !== 'FORM')
          .map((e) => (e.name || e.id || e.tagName.toLowerCase()) + ': ' + e.validationMessage));
      console.log('nothing was sent');
      for (const i of invalid) console.log('  invalid ' + i);
      return;
    }
    console.log(`${sent.method} ${sent.url}`);
    if (sent.type) console.log('Content-Type: ' + sent.type);
    if (sent.body) console.log(sent.body);
  },
  async top(x, y) {
    const t = await page.evaluateHandle(([a, b]) => document.elementFromPoint(a, b), [Number(x), Number(y)]);
    const el = t.asElement();
    console.log(`at ${x},${y}: ` + (el ? await label(el) : 'nothing'));
  },
  async img(sel) {
    for (const el of await page.$$(sel)) {
      const v = await el.evaluate(async (e) => {
        if (!e.complete) await new Promise((r) => e.addEventListener('load', r, { once: true }));
        /* naturalWidth on an <img> with srcset is already divided by the
           density the browser assumed, so the file is measured on its own. */
        const f = new Image();
        f.src = e.currentSrc;
        await f.decode();
        return { src: e.currentSrc.split('/').pop(), w: f.naturalWidth, h: f.naturalHeight,
                 rw: e.getBoundingClientRect().width };
      });
      console.log(`${await label(el)}  chose ${v.src} (${v.w}×${v.h} pixels), drawn ${n(v.rw)} wide`);
    }
  },
  async fetched() {
    console.log(fetched.length ? fetched.join('\n') : 'nothing fetched');
  },
  async release() {
    while (held.length) await held.shift()();
    await page.waitForLoadState('load');
    await page.waitForTimeout(100);
  },
  async scroll(y) {
    await page.evaluate((v) => window.scrollTo(0, v), Number(y));
    await page.waitForTimeout(100);
  },
  async at(ms) {
    await page.evaluate((t) => {
      for (const a of document.getAnimations()) { a.pause(); a.currentTime = t; }
    }, Number(ms));
  },
  async width(w) {
    await page.setViewportSize({ width: Number(w), height: opt.height });
    await page.waitForTimeout(100);
  },
  async overflow() {
    const v = await page.evaluate(() => ({
      s: document.documentElement.scrollWidth, c: document.documentElement.clientWidth }));
    console.log(v.s > v.c ? `page is ${v.s} wide in a ${v.c} window: it scrolls sideways`
                          : `page fits: ${v.s} wide in a ${v.c} window`);
  },
  async fill(sel, text) { await page.fill(sel, text); },
  async check(sel) { await page.check(sel); },
  async click(sel) { await page.click(sel); await page.waitForTimeout(100); },
  async hover(sel) { await page.hover(sel); await page.waitForTimeout(50); },
  async focus(sel) { await page.focus(sel); },
  async tab() {
    await page.keyboard.press('Tab');
    const l = await page.evaluate(() => {
      const e = document.activeElement;
      if (e === document.body) return 'body (nothing left to focus)';
      const t = (e.textContent || e.value || '').replace(/\s+/g, ' ').trim().slice(0, 40);
      return e.tagName.toLowerCase() + (e.id ? '#' + e.id : '') + (t ? ' "' + t + '"' : '');
    });
    console.log('focus: ' + l);
  },
  async press(key) { await page.keyboard.press(key); await page.waitForTimeout(100); },
  async shot(f) { await page.screenshot({ path: f, fullPage: true }); },
};

const arity = { match: 1, rules: 2, describe: 1, press: 1, text: 1, json: 1, box: 1, style: 2, tree: -1, validity: 1, send: 1, top: 2, img: 1, scroll: 1,
  at: 1, width: 1, fill: 2, check: 1, click: 1, hover: 1, focus: 1, shot: 1 };
try {
  while (argv.length) {
    const name = argv.shift();
    if (!steps[name]) throw new Error('unknown step ' + name);
    let args = [];
    if (arity[name] === -1) { if (argv[0] && !steps[argv[0]]) args = [argv.shift()]; }
    else args = argv.splice(0, arity[name] || 0);
    await steps[name](...args);
  }
} finally {
  await browser.close();
}
