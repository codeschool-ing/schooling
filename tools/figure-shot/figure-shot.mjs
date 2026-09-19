/*
 * figure-shot renders one `schooling-figure` to a PNG, in both themes, so that
 * somebody can look at it.
 *
 * # WHY THIS EXISTS WHEN `check-figures` ALREADY RUNS
 *
 * They answer different questions and neither covers the other. `check-figures`
 * asks whether every colour names a token that exists — the failure with no
 * symptom, where a shape renders invisible. It cannot ask whether two things
 * overlap, whether a label runs off the edge, or whether an arrow points at the
 * wrong box, because all three are perfectly valid SVG.
 *
 * The first figure drawn after that tool existed had a note at the right-hand
 * edge sitting on top of the last block's own text. Every check in this
 * repository passed. It took one render to see, which is the same sentence
 * `CLAUDE.md` already writes about `ui/`: three of the defects there were
 * invisible to every check and obvious in a screenshot.
 *
 * # THE PALETTE IS READ OUT OF THE STYLESHEETS
 *
 * Both of them, exactly as `check-figures` does, because a render against a
 * palette written here would be a render of a figure nobody will ever see. The
 * light theme is drawn as well as the dark, for the reason the accessibility
 * pass gives: a colour that reads in one and not the other is one `data-theme`
 * away from shipping.
 *
 *   node tools/figure-shot/figure-shot.mjs <file.md> [index] [out-prefix]
 */
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';

const [, , file, index = '0', out = 'figure'] = process.argv;
if (!file) {
  console.error('usage: figure-shot <file.md> [figure index] [out prefix]');
  process.exit(2);
}

const blocks = [...readFileSync(file, 'utf8')
  .matchAll(/```schooling-figure\n([\s\S]*?)\n```/g)];
if (!blocks.length) {
  console.error(`${file} holds no schooling-figure`);
  process.exit(1);
}
const at = Number(index);
if (!blocks[at]) {
  console.error(`${file} holds ${blocks.length} figure(s); asked for index ${at}`);
  process.exit(1);
}
const figure = JSON.parse(blocks[at][1]);

const palette = ['ui/assets/base.css', 'ui/assets/terminal.css']
  .map((f) => readFileSync(f, 'utf8')).join('\n');

const browser = await chromium.launch();
for (const theme of ['dark', 'light']) {
  const page = await browser.newPage({ viewport: { width: 780, height: 480 } });
  await page.setContent(`<!doctype html>
    <html${theme === 'light' ? ' data-theme="light"' : ''}>
    <style>${palette}
      body{background:var(--ink);margin:0;padding:16px;font-family:system-ui}
      figure{margin:0}
      svg{width:720px;height:auto;display:block}
      figcaption{color:var(--paper-dim);font-size:13px;margin-top:10px;max-width:720px}
    </style>
    <figure>${figure.svg}<figcaption>${figure.caption ?? ''}</figcaption></figure>`);
  const path = `${out}-${theme}.png`;
  await page.locator('figure').screenshot({ path });
  console.log(path);
  await page.close();
}
await browser.close();
