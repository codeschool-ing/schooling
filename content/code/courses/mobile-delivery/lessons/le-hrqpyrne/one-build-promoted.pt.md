---
title: Um build, promovido
version: 1
---

**O build que chega à produção é o build que os seus testadores experimentaram, byte por byte.**
Ele é enviado uma vez, com o version code próprio, e depois **promovido** de faixa em faixa: a loja
move o mesmo arquivo para um público mais amplo. Uma equipe que gera o build de novo no topo da
escada publica um binário que ninguém testou, gerado do que o branch tinha naquela manhã, e o beta
testou outra coisa.

As duas lojas dificultam quebrar a regra. **Um version code, depois de enviado, nunca mais pode ser
enviado** no Google Play, e um número de build do iOS é único dentro da versão dele. A lição 9 trata
desses números; aqui eles são o que torna "o mesmo build" verificável.

## As faixas como script

As regras das duas últimas seções cabem numa página de TypeScript: cada faixa guarda um version
code, um envio recusa um código já usado, uma promoção copia um código para cima, e uma pessoa
recebe o código mais alto entre as faixas em que está. Três pessoas estão nas faixas do planner: a
Ana é da equipe, nas faixas interna e fechada; o Bruno é um aluno no beta fechado; a Carla só tem a
versão da loja. Salve isto como `tracks.ts`:

```schooling-example
{"language": "typescript", "file": "tracks.ts", "parts": [{"code": "// tracks.ts: Google Play's testing tracks as data, and which build each person gets\ntype Track = \"internal\" | \"closed\" | \"open\" | \"production\";\nconst onTrack = new Map<Track, number>();\nconst used = new Set<number>();", "note": "Cada faixa guarda um version code. `used` lembra todo código já enviado, em qualquer faixa."}, {"code": "function upload(code: number, track: Track) {\n  if (used.has(code)) return console.log(`upload ${code} to ${track}: refused, version code already used`);\n  used.add(code);\n  onTrack.set(track, code);\n  console.log(`upload ${code} to ${track}`);\n}", "note": "Um envio com um código que já foi usado é recusado, seja qual for a faixa."}, {"code": "function promote(from: Track, to: Track) {\n  const code = onTrack.get(from)!;\n  onTrack.set(to, code);\n  console.log(`promote ${code} from ${from} to ${to}`);\n}", "note": "Uma promoção não envia nada: o mesmo código é posto numa faixa mais ampla."}, {"code": "const people: [string, Track[]][] = [\n  [\"Ana\", [\"internal\", \"closed\", \"production\"]],\n  [\"Bruno\", [\"closed\", \"production\"]],\n  [\"Carla\", [\"production\"]],\n];\nfunction show() {\n  for (const [who, tracks] of people) {\n    const codes = tracks.flatMap((t) => (onTrack.has(t) ? [onTrack.get(t)!] : []));\n    console.log(`    ${who.padEnd(6)} gets ${Math.max(...codes)}`);\n  }\n}", "note": "Cada pessoa vê o código mais alto entre as faixas em que está."}, {"code": "upload(41, \"internal\"); promote(\"internal\", \"closed\"); promote(\"closed\", \"production\"); show();\nupload(42, \"closed\"); show();\nupload(43, \"internal\"); show();\nupload(42, \"production\"); promote(\"closed\", \"production\"); show();", "note": "Quatro momentos do mês do planner, em ordem."}]}
```

```
ana@dev:~/planner$ node tracks.ts
upload 41 to internal
promote 41 from internal to closed
promote 41 from closed to production
    Ana    gets 41
    Bruno  gets 41
    Carla  gets 41
upload 42 to closed
    Ana    gets 42
    Bruno  gets 42
    Carla  gets 41
upload 43 to internal
    Ana    gets 43
    Bruno  gets 42
    Carla  gets 41
upload 42 to production: refused, version code already used
promote 42 from closed to production
    Ana    gets 43
    Bruno  gets 42
    Carla  gets 42
```

Leia de cima para baixo:

- **O build 41 sobe a escada por promoção**, e as três pessoas o têm.
- **O build 42 vai direto para a faixa fechada**, e a Ana o recebe mesmo com a faixa interna ainda
  guardando o 41: ela está nas duas, e 42 é maior.
- **O build 43 é a correção da equipe**, só na interna, então a Ana o tem e os alunos não.
- **O 42 gerado de novo é recusado.** Alguém gerou de novo o código do beta e tentou enviá-lo para
  produção; o código já foi usado. O movimento certo é a última linha: promover o 42 que o Bruno
  vem usando, e a Carla o recebe.

## No iOS

O TestFlight e a App Store funcionam do mesmo jeito com outras palavras. Um build é enviado uma vez
ao App Store Connect, testado no TestFlight, e o **mesmo build** é então escolhido para a versão da
App Store e enviado para revisão. Nada é gerado de novo, e o arquivo do Xcode daquele build é
guardado, porque a lição 13 precisa dos símbolos dele para ler os crashes que ele produz.

## Num pipeline

O pipeline da lição 10 gera o build **uma vez**, no commit que está sendo liberado, envia para a
faixa mais baixa, e dali todo passo é uma promoção disparada por uma pessoa. O Fastlane, na lição
11, tem uma ação exatamente para isso: `upload_to_play_store` com `track_promote_to`, que move um
release sem enviar nada.
