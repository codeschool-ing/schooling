/* ==========================================================================
   An operator, made the only way there is.

   IT IS HERE FOR THE REASON `sign-up.mjs` IS: two suites need one. The
   accessibility pass measures the console's screens and the console round trip
   presses their buttons, and both need a staff account with a second factor
   already shown. Written out twice, the next thing learnt about making one
   would land in whichever copy the person was looking at.

   # THE ORDER IS NOT INTERCHANGEABLE

   Sign up, then `cmd/staff` for the role, then enrol a factor. `RequireStaff`
   asks for a live role AND a factor shown on this session; enrolling before the
   grant would leave a session that carries the factor and no role, and the
   console would answer 403 to an account that has one.

   # THE FIRST ROLE CANNOT COME FROM THE CONSOLE

   That is the point of `cmd/staff` rather than an oversight: reaching the
   console needs a role, so the first one is granted from a terminal, and it
   writes to the audit like every other administrative path. A suite that
   inserted a row would be testing a door the platform does not have.

   # THE SECOND FACTOR IS THIRTY LINES RATHER THAN A DEPENDENCY

   The same argument `internal/identity/totp.go` makes. It is an HMAC and a
   truncation, and a wrong one is not a subtle failure here: the server answers
   `wrong_code` and the run stops.
   ========================================================================== */

import { execFileSync } from 'node:child_process';
import { createHmac } from 'node:crypto';

/* RFC 6238: base32 without padding, HMAC-SHA1, six digits, thirty seconds —
   the same four parameters the server writes out. */
export function totp(secret, at = Date.now()) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of secret.toUpperCase().replace(/[\s=]/g, '')) {
    const v = alphabet.indexOf(ch);
    if (v < 0) throw new Error(`the secret is not base32: ${ch}`);
    bits += v.toString(2).padStart(5, '0');
  }
  const key = Buffer.from((bits.match(/.{8}/g) || []).map((b) => parseInt(b, 2)));

  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / 30)));

  const mac = createHmac('sha1', key).update(counter).digest();
  const offset = mac[mac.length - 1] & 0x0f;
  const truncated = mac.readUInt32BE(offset) & 0x7fffffff;
  return String(truncated % 1_000_000).padStart(6, '0');
}

/* Turn an already-open page into an operator's.

   THE PAGE IS PASSED IN RATHER THAN MADE HERE, because the two callers want
   different ones — one sets a theme before the first paint, the other does not
   care — and a helper that made its own would be a helper one of them has to
   work around.

   `by` goes into the audit entry `cmd/staff` writes. It says which suite did
   this, which is the difference between reading that history later and
   wondering. */
export async function makeAnOperator(page, base, { name, email, by }) {
  await page.goto(`${base}/`, { waitUntil: 'load' });

  const failed = await page.evaluate(async ([label, address]) => {
    const r = await fetch('/api/v1/sign-up', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: label, email: address, password: 'a long enough password here' }),
    });
    return r.ok ? '' : `${r.status} ${await r.text()}`;
  }, [name, email]);
  if (failed) throw new Error(`signing the operator up: ${failed}`);

  execFileSync('go', ['run', './cmd/staff', 'grant', email, 'operator', '--by', by],
    { stdio: 'pipe' });

  const secret = await page.evaluate(async () => {
    const r = await fetch('/api/v1/second-factor/start', { method: 'POST' });
    if (!r.ok) throw new Error(`starting the second factor: ${r.status}`);
    return (await r.json()).secret;
  });

  /* THE CODE IS ENROLLED ON THIS SESSION, which is what marks the factor as
     shown — so nothing has to present one again to open the console. That is
     the server's design and not a shortcut: a factor is enforced on the
     session, not on the account. */
  const enrolled = await page.evaluate(async ([s, c]) => {
    const r = await fetch('/api/v1/second-factor/enrol', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ secret: s, code: c }),
    });
    return r.ok ? '' : `${r.status} ${await r.text()}`;
  }, [secret, totp(secret)]);
  if (enrolled) throw new Error(`enrolling the second factor: ${enrolled}`);

  return { email, secret };
}
