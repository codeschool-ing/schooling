---
title: O que o backup leva, medido
version: 1
---

**O backup de um celular não leva a caixa de areia inteira, e no Android ele pode não levar nada.**
As duas plataformas deixam de fora as pastas que guardam o que dá para buscar de novo, e o Android
põe um limite no resto. As regras são curtas o bastante para virar um programa, então esta seção
escreve um e o roda contra um planner que cometeu o erro clássico.

## As regras, segundo a documentação

**O Backup automático do Android** (Android 6 em diante) copia o armazenamento privado do app para
o Google Drive da pessoa, mais ou menos uma vez por dia, quando o celular está ocioso, carregando e
no Wi-Fi. Ele deixa de fora `cache/`, `code_cache/` e `no_backup/`. A cota é de **25 MB por app**,
e a documentação do Google diz o que acontece depois dela: o backup não é feito. Não os primeiros
25 MB; nada. Um app escolhe o que deixar de fora com um arquivo de regras citado no manifesto,
`dataExtractionRules` a partir do Android 12 e `fullBackupContent` antes dele.

**O iOS** faz backup do contêiner no iCloud, ou num computador, e deixa de fora `Library/Caches/` e
`tmp/`. Não existe cota por app; o limite é o armazenamento do iCloud da pessoa, e o plano gratuito
tem 5 GB para tudo o que ela tem. Um arquivo sozinho fica de fora quando se marca
`isExcludedFromBackup` na URL dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l01-backup\" aria-label=\"Duas caixas de areia lado a lado. Android, em /data/data/&lt;package&gt;/: files, databases e shared_prefs entram no backup; cache e no_backup ficam de fora; acima de 25 MB nada entra no backup. iOS, o contêiner do app: Documents, Library/Application Support e Library/Preferences entram no backup; Library/Caches e tmp ficam de fora; não existe cota por app, só o armazenamento do iCloud da pessoa.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Android</text><text x=\"36\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/data/data/&lt;package&gt;/</text><rect x=\"36\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">files/</text><text x=\"248\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"36\" y=\"112\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">databases/</text><text x=\"248\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"36\" y=\"148\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shared_prefs/</text><text x=\"248\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"36\" y=\"184\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"46\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cache/</text><text x=\"248\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fica de fora</text><rect x=\"36\" y=\"220\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"46\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no_backup/</text><text x=\"248\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fica de fora</text><text x=\"36\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">acima de 25 MB, nada entra no backup</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS</text><text x=\"386\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o contêiner do app</text><rect x=\"386\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Documents/</text><text x=\"598\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"386\" y=\"112\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Library/Application Support/</text><text x=\"598\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"386\" y=\"148\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Library/Preferences/</text><text x=\"598\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">entra no backup</text><rect x=\"386\" y=\"184\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"396\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Library/Caches/</text><text x=\"598\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fica de fora</text><rect x=\"386\" y=\"220\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"396\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tmp/</text><text x=\"598\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fica de fora</text><text x=\"386\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">sem cota por app: o iCloud da pessoa</text></svg>", "caption": "O lugar onde um arquivo fica decide se o backup o leva. As pastas deixadas de fora são as que guardam o que dá para buscar de novo.", "same": ["Android", "iOS"]}
```

## Um planner que guarda um anexo de 24 MB

O programa abaixo monta uma caixa de areia do jeito que cada plataforma monta. Nela vão um banco,
um arquivo de configurações, um PDF de anotações que a pessoa baixou para o curso de Estatística,
uma imagem de capa em cache e um arquivo que cada plataforma mantém fora do backup. Depois ele percorre
a pasta e aplica as regras. Salve como `sandbox.ts` na `~/planner`:

```typescript
// sandbox.ts: build a planner's sandbox as each platform lays it out, and say
// what the phone's backup would take from it.
import { mkdirSync, writeFileSync, readdirSync, statSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";

const MB = 1024 * 1024;
type Layout = Record<string, number>; // path inside the sandbox -> size in MB

const layouts: Record<string, Layout> = {
  android: {
    "databases/planner.db": 3,
    "shared_prefs/settings.xml": 0.01,
    "files/attachments/statistics-notes.pdf": 24,
    "cache/covers/guitar.jpg": 6,
    "no_backup/device-id": 0.01,
  },
  ios: {
    "Library/Application Support/planner.db": 3,
    "Library/Preferences/settings.plist": 0.01,
    "Documents/statistics-notes.pdf": 24,
    "Library/Caches/covers/guitar.jpg": 6,
    "tmp/upload-part-1": 2,
  },
};

// What each platform's backup leaves out by default.
const leftOut: Record<string, RegExp> = {
  android: /^(cache|code_cache|no_backup)\//, // Auto Backup, Android 6 and later
  ios: /^(Library\/Caches|tmp)\//, // iCloud and computer backups
};
const quotaMB: Record<string, number> = { android: 25, ios: Infinity };

function make(root: string, layout: Layout) {
  rmSync(root, { recursive: true, force: true });
  for (const [path, size] of Object.entries(layout)) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), Buffer.alloc(Math.round(size * MB)));
  }
}

function walk(root: string, dir = ""): [string, number][] {
  return readdirSync(join(root, dir), { withFileTypes: true }).flatMap((e) => {
    const path = dir ? `${dir}/${e.name}` : e.name;
    return e.isDirectory() ? walk(root, path) : [[path, statSync(join(root, path)).size] as [string, number]];
  });
}

const [platform, ...excluded] = process.argv.slice(2);
const root = `sandbox-${platform}`;
make(root, layouts[platform]);
let total = 0;
for (const [path, bytes] of walk(root).sort()) {
  const skip = leftOut[platform].test(path) || excluded.some((p) => path.startsWith(p));
  if (!skip) total += bytes;
  console.log(`${skip ? "left out " : "backed up"}  ${(bytes / MB).toFixed(2).padStart(6)} MB  ${path}`);
}
const fits = total <= quotaMB[platform] * MB;
console.log(`backup: ${(total / MB).toFixed(2)} MB` + (fits ? "" : `, over the ${quotaMB[platform]} MB quota: nothing is backed up`));
```

Os tamanhos estão escritos em `layouts`, e os arquivos são preenchidos com zeros, então a pasta que
ele cria é a mesma em todo computador. Rode para o Android, de novo deixando de fora a pasta de
anexos, que é o que um arquivo de regras faria, e depois para o iOS:

```
ana@dev:~/planner$ node sandbox.ts android
left out     6.00 MB  cache/covers/guitar.jpg
backed up    3.00 MB  databases/planner.db
backed up   24.00 MB  files/attachments/statistics-notes.pdf
left out     0.01 MB  no_backup/device-id
backed up    0.01 MB  shared_prefs/settings.xml
backup: 27.01 MB, over the 25 MB quota: nothing is backed up
ana@dev:~/planner$ node sandbox.ts android files/attachments/
left out     6.00 MB  cache/covers/guitar.jpg
backed up    3.00 MB  databases/planner.db
left out    24.00 MB  files/attachments/statistics-notes.pdf
left out     0.01 MB  no_backup/device-id
backed up    0.01 MB  shared_prefs/settings.xml
backup: 3.01 MB
ana@dev:~/planner$ node sandbox.ts ios
backed up   24.00 MB  Documents/statistics-notes.pdf
backed up    3.00 MB  Library/Application Support/planner.db
left out     6.00 MB  Library/Caches/covers/guitar.jpg
backed up    0.01 MB  Library/Preferences/settings.plist
left out     2.00 MB  tmp/upload-part-1
backup: 27.01 MB
```

**Dois megabytes acima da linha, e o banco foi junto com o PDF.** No Android, quem reinstala recebe
um planner vazio, todas as sessões que digitou perdidas, porque um arquivo que dava para baixar de
novo estava ao lado delas. Excluir `files/attachments/` derruba o backup para 3,01 MB, e o planner
volta inteiro.

O iOS levou tudo menos o cache e o arquivo de rascunho, PDF incluído. Nada falhou, e a pessoa paga
24 MB do armazenamento do iCloud dela para guardar um documento que o planner poderia baixar de
novo. Marcar `isExcludedFromBackup` nele, ou colocá-lo em `Library/Caches/`, é a correção ali.

A mesma pergunta resolve os dois casos: **dá para buscar este arquivo de novo?** Se dá, ele não
pertence ao backup. A aula 18 volta aos arquivos grandes, e ao que acontece quando acaba o disco, e
não a cota.
