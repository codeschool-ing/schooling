---
title: A file per platform
version: 1
---

**When Metro resolves an import, it looks first for a file whose name carries the platform it is
bundling for.** `import { savedWhere } from "./savedWhere"` finds `savedWhere.ios.ts` in an iOS bundle,
`savedWhere.android.ts` in an Android one, and `savedWhere.ts`, the file with no platform in its name, in
any other, the web included. The import does not change. The file it reaches does.

## Three small files

The planner will say at the foot of its screen where the plan is kept: on the phone, or in the browser.
Each sentence is a file. Save these three, with the names in their first lines:

```typescript
// src/savedWhere.ios.ts: Metro picks this file when it bundles for iOS.
export const savedWhere = "Saved on this iPhone";
```

```typescript
// src/savedWhere.android.ts: Metro picks this file when it bundles for Android.
export const savedWhere = "Saved on this Android device";
```

```typescript
// src/savedWhere.ts: every other platform, which here means the web.
export const savedWhere = "Saved in this browser";
```

**They must export the same names, with the same types.** TypeScript checks the import against
`savedWhere.ts`, the one without a platform, and knows nothing about the other two; a `.ios.ts` that
forgot an export compiles here and fails in the iOS bundle. Keeping the files tiny, as here, and
testing each platform, as the last section of this lesson does, is the defence.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l06-resolve\" aria-label=\"One import, ./savedWhere, resolved by Metro once per platform. The iOS bundle receives savedWhere.ios.ts, the Android bundle savedWhere.android.ts, and the web bundle the plain savedWhere.ts. Each bundle carries only its own file.\"><defs><marker id=\"l06-resolve-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-resolve-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the import, unchanged</text><rect x=\"20\" y=\"80\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">from \"./savedWhere\"</text><text x=\"290\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">Metro, at bundle time</text><path d=\"M220 102 L350 48\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"30\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.ios.ts</text><path d=\"M540 48 L580 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"30\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">iOS bundle</text><path d=\"M220 102 L350 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"86\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.android.ts</text><path d=\"M540 104 L580 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"86\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Android bundle</text><path d=\"M220 102 L350 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"142\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.ts</text><path d=\"M540 160 L580 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"142\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web bundle</text></svg>", "caption": "The choice is made when the bundle is built: the iPhone's sentence is not in the Android app at all."}
```

## Proved in the bundles

Export the app for two platforms and look for each sentence in each bundle. The strings survive into
the bytecode, as lesson 1 showed:

```
ana@dev:~/planner$ npx expo export --platform android --output-dir out-android > /dev/null 2>&1
ana@dev:~/planner$ npx expo export --platform web --output-dir out-web > /dev/null 2>&1
ana@dev:~/planner$ grep -c "this Android device" out-android/_expo/static/js/android/*.hbc
1
ana@dev:~/planner$ grep -c "this iPhone" out-android/_expo/static/js/android/*.hbc
0
ana@dev:~/planner$ grep -c "in this browser" out-web/_expo/static/js/web/*.js
1
ana@dev:~/planner$ rm -r out-android out-web
```

**The Android bundle holds the Android sentence and not the iPhone's, and the web bundle holds its own.** The choice was made by Metro,
when the bundle was built, not by a branch at run time; the iOS sentence is not in the Android app at
all. The web bundle is JavaScript rather than bytecode, and it carries the third file.

## When to use which

| the difference is | use |
|---|---|
| one value: a size, a colour, a word | `Platform.select` |
| a whole component, with different code inside | `.ios.tsx` and `.android.tsx` |
| something only one platform has | a `.ios.tsx` that does it and a plain `.tsx` that renders nothing |
| a native API | a library that already did this, or lesson 17 |

`.native.ts` is a fourth suffix, matched by both phones and not by the web, for the case where the
browser is the odd one out.
