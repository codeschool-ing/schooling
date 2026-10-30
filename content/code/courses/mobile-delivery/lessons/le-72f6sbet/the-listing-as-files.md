---
title: The listing as files, checked before a store sees it
version: 1
---

**A listing typed into a console lives only in the console: nobody reviews it, nothing records who
changed it, and its limits are checked at the last moment.** Kept as files beside the code, it is
reviewed in a pull request like any other change, and a script checks every limit before upload.
Fastlane, in lesson 11, reads exactly this layout and sends it to both stores: **one folder per
store and language, one text file per field.**

## The files

This script writes the planner's listing in English and Portuguese. It is a shell script and not
TypeScript, because what it does is write files. Save it as `make-listing.sh` in `~/planner`:

```sh
# make-listing.sh: the planner's listing, one folder per store and language, one file per field
set -e
cd ~/planner
w() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }

w listing/ios/en-US/name.txt "Study Planner"
w listing/ios/en-US/subtitle.txt "Plan sessions, see your week"
w listing/ios/en-US/keywords.txt "study,timetable,revision,exam,schedule,habit,focus,homework,student,timer"
w listing/ios/en-US/description.txt "List the courses you study, add sessions with a date and a length, tick them off, and see how many minutes your week holds. It works offline."

w listing/ios/pt-BR/name.txt "Planner de Estudos"
w listing/ios/pt-BR/subtitle.txt "Planeje sessões e veja a semana"
w listing/ios/pt-BR/keywords.txt "estudo,planejador,cronograma,revisão,prova,agenda,hábito,foco,lição,vestibular,concurso,sessões,enem"
w listing/ios/pt-BR/description.txt "Liste os cursos que você estuda, adicione sessões com data e duração, marque as feitas e veja quantos minutos a sua semana tem. Funciona offline."

w listing/android/en-US/title.txt "Study Planner: sessions & week"
w listing/android/en-US/short_description.txt "Plan study sessions, tick them off, and see how many minutes your week holds."
w listing/android/en-US/full_description.txt "List the courses you study, add sessions with a date and a length, tick them off, and see how many minutes your week holds. It works offline and syncs when it can."

w listing/android/pt-BR/title.txt "Planner de Estudos: semana"
w listing/android/pt-BR/short_description.txt "Planeje sessões de estudo, marque as feitas e veja quantos minutos a semana tem."
w listing/android/pt-BR/full_description.txt "Liste os cursos que você estuda, adicione sessões com data e duração, marque as feitas e veja quantos minutos a sua semana tem. Funciona offline e sincroniza quando pode."
```

Run it with `bash make-listing.sh`, and look at the folders it made:

```
ana@dev:~/planner$ bash make-listing.sh
ana@dev:~/planner$ find listing -type f | sort
listing/android/en-US/full_description.txt
listing/android/en-US/short_description.txt
listing/android/en-US/title.txt
listing/android/pt-BR/full_description.txt
listing/android/pt-BR/short_description.txt
listing/android/pt-BR/title.txt
listing/ios/en-US/description.txt
listing/ios/en-US/keywords.txt
listing/ios/en-US/name.txt
listing/ios/en-US/subtitle.txt
listing/ios/pt-BR/description.txt
listing/ios/pt-BR/keywords.txt
listing/ios/pt-BR/name.txt
listing/ios/pt-BR/subtitle.txt
```

## Screenshots to check

A real screenshot comes from the app. To have pictures of exact sizes here, a short program writes
a PNG of one colour at any size. You do not need to read it closely. It writes a valid PNG whose
header carries the width and height, and that is all a store checks first. Save it as
`blank.ts`:

```typescript
// blank.ts: write a PNG of one colour, WIDTH x HEIGHT pixels, to stand in for a screenshot
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const [file, width, height] = [process.argv[2], Number(process.argv[3]), Number(process.argv[4])];

const table = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc(bytes: Buffer): number {
  let c = 0xffffffff;
  for (const b of bytes) c = table[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type: string, data: Buffer): Buffer {
  const head = Buffer.alloc(8);
  head.writeUInt32BE(data.length, 0);
  head.write(type, 4, "ascii");
  const tail = Buffer.alloc(4);
  tail.writeUInt32BE(crc(Buffer.concat([head.subarray(4), data])), 0);
  return Buffer.concat([head, data, tail]);
}

const header = Buffer.alloc(13);
header.writeUInt32BE(width, 0);
header.writeUInt32BE(height, 4);
header[8] = 8; // bits per channel
header[9] = 2; // colour type: RGB
const row = Buffer.concat([Buffer.from([0]), Buffer.alloc(width * 3, 0x2f)]);
const pixels = deflateSync(Buffer.concat(Array(height).fill(row)));

mkdirSync(dirname(file), { recursive: true });
writeFileSync(file, Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", header), chunk("IDAT", pixels), chunk("IEND", Buffer.alloc(0)),
]));
```

Make four pictures, one of them at a size Apple does not take for the large iPhone and one too tall
for Google:

```
ana@dev:~/planner$ node blank.ts listing/ios/en-US/screenshots/1-week.png 1320 2868
ana@dev:~/planner$ node blank.ts listing/ios/pt-BR/screenshots/1-week.png 1170 2532
ana@dev:~/planner$ node blank.ts listing/android/en-US/screenshots/1-week.png 1080 1920
ana@dev:~/planner$ node blank.ts listing/android/pt-BR/screenshots/1-week.png 1080 2400
```

## The check

Save this as `listing.ts`. It knows each store's limits, counts characters as a person does and
bytes where Apple does, and reads the size of every screenshot from the PNG header:

```schooling-example
{"language": "typescript", "file": "listing.ts", "parts": [{"code": "// listing.ts: check a store listing kept as files against each store's limits\nimport { readdirSync, readFileSync, existsSync } from \"node:fs\";\nimport { join } from \"node:path\";\n\ntype Limit = [number, \"chars\" | \"bytes\"];\nconst LIMITS: Record<string, Record<string, Limit>> = {\n  ios: { \"name.txt\": [30, \"chars\"], \"subtitle.txt\": [30, \"chars\"], \"keywords.txt\": [100, \"bytes\"], \"description.txt\": [4000, \"chars\"] },\n  android: { \"title.txt\": [30, \"chars\"], \"short_description.txt\": [80, \"chars\"], \"full_description.txt\": [4000, \"chars\"] },\n};", "note": "The limits from section \"What the store page holds\", one table per store. Only Apple's keywords are counted in bytes."}, {"code": "let problems = 0;\nconst report = (where: string, what: string, detail: string, ok: boolean) => {\n  if (!ok) problems++;\n  console.log(`${where.padEnd(14)} ${what.padEnd(22)} ${detail.padEnd(16)} ${ok ? \"ok\" : \"OVER\"}`);\n};", "note": "One line per check, and a count of the failures for the exit status."}, {"code": "function size(text: string, unit: \"chars\" | \"bytes\"): number {\n  return unit === \"bytes\" ? Buffer.byteLength(text, \"utf8\") : [...text].length;\n}", "note": "`[...text].length` counts characters as a person sees them; `.length` alone would count UTF-16 units and get an emoji wrong."}, {"code": "function pngSize(file: string): [number, number] {\n  const b = readFileSync(file);\n  return [b.readUInt32BE(16), b.readUInt32BE(20)];\n}", "note": "A PNG's width and height sit at bytes 16 and 20 of the file, in its first chunk."}, {"code": "for (const store of Object.keys(LIMITS)) {\n  for (const lang of readdirSync(join(\"listing\", store)).sort()) {\n    const dir = join(\"listing\", store, lang);\n    const where = `${store}/${lang}`;\n    for (const [file, [max, unit]] of Object.entries(LIMITS[store])) {\n      if (!existsSync(join(dir, file))) continue;\n      const text = readFileSync(join(dir, file), \"utf8\").replace(/\\n$/, \"\");\n      const n = size(text, unit);\n      report(where, file, `${n}/${max} ${unit}`, n <= max);\n    }", "note": "Every field of every language, against its store's limit. The newline that ends the file is not part of the field."}, {"code": "    if (store === \"ios\" && existsSync(join(dir, \"keywords.txt\"))) {\n      const name = readFileSync(join(dir, \"name.txt\"), \"utf8\").toLowerCase().split(/\\W+/u);\n      for (const word of readFileSync(join(dir, \"keywords.txt\"), \"utf8\").trim().split(\",\")) {\n        if (word.length <= 2 || word !== word.trim() || name.includes(word.toLowerCase())) {\n          report(where, `keyword \"${word}\"`, \"short, spaced or in the name\", false);\n        }\n      }\n    }", "note": "Apple's three keyword rules: longer than two characters, no stray spaces, and no word the name already has."}, {"code": "    const shots = join(dir, \"screenshots\");\n    for (const png of existsSync(shots) ? readdirSync(shots).sort() : []) {\n      const [w, h] = pngSize(join(shots, png));\n      const ok = store === \"ios\"\n        ? [\"1320x2868\", \"1290x2796\"].includes(`${w}x${h}`)\n        : Math.min(w, h) >= 320 && Math.max(w, h) <= 3840 && Math.max(w, h) <= 2 * Math.min(w, h);\n      report(where, png, `${w}x${h}`, ok);\n    }\n  }\n}\nprocess.exitCode = problems ? 1 : 0;", "note": "Apple takes exact sizes for the large iPhone; Google takes a range and a shape. A pipeline reads the exit status."}]}
```

```
ana@dev:~/planner$ node listing.ts; echo "exit status $?"
ios/en-US      name.txt               13/30 chars      ok
ios/en-US      subtitle.txt           28/30 chars      ok
ios/en-US      keywords.txt           73/100 bytes     ok
ios/en-US      description.txt        141/4000 chars   ok
ios/en-US      keyword "study"        short, spaced or in the name OVER
ios/en-US      1-week.png             1320x2868        ok
ios/pt-BR      name.txt               18/30 chars      ok
ios/pt-BR      subtitle.txt           31/30 chars      OVER
ios/pt-BR      keywords.txt           105/100 bytes    OVER
ios/pt-BR      description.txt        145/4000 chars   ok
ios/pt-BR      1-week.png             1170x2532        OVER
android/en-US  title.txt              30/30 chars      ok
android/en-US  short_description.txt  77/80 chars      ok
android/en-US  full_description.txt   163/4000 chars   ok
android/en-US  1-week.png             1080x1920        ok
android/pt-BR  title.txt              26/30 chars      ok
android/pt-BR  short_description.txt  80/80 chars      ok
android/pt-BR  full_description.txt   170/4000 chars   ok
android/pt-BR  1-week.png             1080x2400        OVER
exit status 1
```

Five problems, and three are worth reading slowly:

- **The Portuguese keywords pass at 100 characters and fail at 105 bytes.** Five letters with
  accents, five extra bytes, and the same list in English would have fitted.
- **`study` repeats the English name**, so it spends six bytes on a search the name already wins.
- **The Portuguese subtitle is one character over**, the kind of overrun nobody sees by eye.

The other two are pictures: 1170 × 2532 is a real iPhone's screen, and not a size Apple takes for
the large display, and 1080 × 2400 has a long side more than twice the short one. Once all five
are fixed, the script exits with 0, and that status is what lesson 10's pipeline reads.
