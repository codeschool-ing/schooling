---
title: A ficha como arquivos, conferida antes que uma loja a veja
version: 1
---

**Uma ficha digitada num console mora só no console: ninguém a revisa, nada registra quem a mudou,
e os limites dela são conferidos no último momento.** Guardada como arquivos ao lado do código, ela
é revisada num pull request como qualquer outra mudança, e um script confere todo limite antes do
envio. O Fastlane, na lição 11, lê exatamente esta organização e a manda para as duas lojas: **uma
pasta por loja e idioma, um arquivo de texto por campo.**

## Os arquivos

Este script escreve a ficha do planner em inglês e em português. Ele é um script de shell, e não
TypeScript, porque o que ele faz é escrever arquivos. Salve-o como `make-listing.sh` em
`~/planner`:

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

Rode com `bash make-listing.sh`, e olhe as pastas que ele criou:

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

## Capturas para conferir

Uma captura de verdade vem do app. Para ter imagens de tamanhos exatos aqui, um programa curto
escreve um PNG de uma cor só em qualquer tamanho. Você não precisa lê-lo com atenção. Ele escreve um
PNG válido cujo cabeçalho leva a largura e a altura, e isso é tudo o que uma loja confere primeiro. Salve-o como `blank.ts`:

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

Crie quatro imagens, uma num tamanho que a Apple não aceita para o iPhone grande e uma alta demais
para o Google:

```
ana@dev:~/planner$ node blank.ts listing/ios/en-US/screenshots/1-week.png 1320 2868
ana@dev:~/planner$ node blank.ts listing/ios/pt-BR/screenshots/1-week.png 1170 2532
ana@dev:~/planner$ node blank.ts listing/android/en-US/screenshots/1-week.png 1080 1920
ana@dev:~/planner$ node blank.ts listing/android/pt-BR/screenshots/1-week.png 1080 2400
```

## A checagem

Salve isto como `listing.ts`. Ele conhece os limites de cada loja, conta caracteres como uma pessoa
conta e bytes onde a Apple conta, e lê o tamanho de cada captura no cabeçalho do PNG:

```schooling-example
{"language": "typescript", "file": "listing.ts", "parts": [{"code": "// listing.ts: check a store listing kept as files against each store's limits\nimport { readdirSync, readFileSync, existsSync } from \"node:fs\";\nimport { join } from \"node:path\";\n\ntype Limit = [number, \"chars\" | \"bytes\"];\nconst LIMITS: Record<string, Record<string, Limit>> = {\n  ios: { \"name.txt\": [30, \"chars\"], \"subtitle.txt\": [30, \"chars\"], \"keywords.txt\": [100, \"bytes\"], \"description.txt\": [4000, \"chars\"] },\n  android: { \"title.txt\": [30, \"chars\"], \"short_description.txt\": [80, \"chars\"], \"full_description.txt\": [4000, \"chars\"] },\n};", "note": "Os limites da seção \"O que a página da loja guarda\", uma tabela por loja. Só as palavras-chave da Apple são contadas em bytes."}, {"code": "let problems = 0;\nconst report = (where: string, what: string, detail: string, ok: boolean) => {\n  if (!ok) problems++;\n  console.log(`${where.padEnd(14)} ${what.padEnd(22)} ${detail.padEnd(16)} ${ok ? \"ok\" : \"OVER\"}`);\n};", "note": "Uma linha por checagem, e uma contagem das falhas para o status de saída."}, {"code": "function size(text: string, unit: \"chars\" | \"bytes\"): number {\n  return unit === \"bytes\" ? Buffer.byteLength(text, \"utf8\") : [...text].length;\n}", "note": "`[...text].length` conta caracteres como uma pessoa os vê; `.length` sozinho contaria unidades UTF-16 e erraria um emoji."}, {"code": "function pngSize(file: string): [number, number] {\n  const b = readFileSync(file);\n  return [b.readUInt32BE(16), b.readUInt32BE(20)];\n}", "note": "A largura e a altura de um PNG ficam nos bytes 16 e 20 do arquivo, no primeiro bloco dele."}, {"code": "for (const store of Object.keys(LIMITS)) {\n  for (const lang of readdirSync(join(\"listing\", store)).sort()) {\n    const dir = join(\"listing\", store, lang);\n    const where = `${store}/${lang}`;\n    for (const [file, [max, unit]] of Object.entries(LIMITS[store])) {\n      if (!existsSync(join(dir, file))) continue;\n      const text = readFileSync(join(dir, file), \"utf8\").replace(/\\n$/, \"\");\n      const n = size(text, unit);\n      report(where, file, `${n}/${max} ${unit}`, n <= max);\n    }", "note": "Todo campo de todo idioma, contra o limite da loja dele. A quebra de linha que fecha o arquivo não faz parte do campo."}, {"code": "    if (store === \"ios\" && existsSync(join(dir, \"keywords.txt\"))) {\n      const name = readFileSync(join(dir, \"name.txt\"), \"utf8\").toLowerCase().split(/\\W+/u);\n      for (const word of readFileSync(join(dir, \"keywords.txt\"), \"utf8\").trim().split(\",\")) {\n        if (word.length <= 2 || word !== word.trim() || name.includes(word.toLowerCase())) {\n          report(where, `keyword \"${word}\"`, \"short, spaced or in the name\", false);\n        }\n      }\n    }", "note": "As três regras de palavra-chave da Apple: mais de dois caracteres, sem espaços sobrando, e nenhuma palavra que o nome já tem."}, {"code": "    const shots = join(dir, \"screenshots\");\n    for (const png of existsSync(shots) ? readdirSync(shots).sort() : []) {\n      const [w, h] = pngSize(join(shots, png));\n      const ok = store === \"ios\"\n        ? [\"1320x2868\", \"1290x2796\"].includes(`${w}x${h}`)\n        : Math.min(w, h) >= 320 && Math.max(w, h) <= 3840 && Math.max(w, h) <= 2 * Math.min(w, h);\n      report(where, png, `${w}x${h}`, ok);\n    }\n  }\n}\nprocess.exitCode = problems ? 1 : 0;", "note": "A Apple aceita tamanhos exatos para o iPhone grande; o Google aceita uma faixa e um formato. Um pipeline lê o status de saída."}]}
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

Cinco problemas, e três merecem ser lidos devagar:

- **As palavras-chave em português passam com 100 caracteres e falham com 105 bytes.** Cinco letras
  com acento, cinco bytes a mais, e a mesma lista em inglês teria cabido.
- **`study` repete o nome em inglês**, então gasta seis bytes numa busca que o nome já ganha.
- **O subtítulo em português passa um caractere**, o tipo de excesso que ninguém vê a olho.

Os outros dois são imagens: 1170 × 2532 é a tela de um iPhone de verdade, e não um tamanho que a
Apple aceita para a tela grande, e 1080 × 2400 tem o lado maior com mais do dobro do menor. Quando
os cinco são corrigidos, o script sai com 0, e esse status é o que o pipeline da lição 10 lê.
