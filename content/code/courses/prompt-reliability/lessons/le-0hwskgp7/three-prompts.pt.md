---
title: Três prompts que concordam demais
version: 1
---

O ensemble óbvio são três prompts que você já tem. `v3-examples`, `v4-only-json` e `v6-escaped`
foram escritos cada um para corrigir alguma coisa, têm redações diferentes, e cada um acerta cerca
de 80% das vezes no conjunto completo:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl
70 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl
70 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl vote runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl
runs/v3.jsonl              56/70 right
runs/v4.jsonl              53/70 right
runs/v6.jsonl              56/70 right
majority of 3              58/70 right
unanimous on 54 cases, a tie on 0
```

O `pl vote` lê a categoria de cada resposta, só a conta como certa quando a resposta é analisável e
bate com o rótulo da pessoa, e fica com a maioria em cada caso. Dois dos prompts fazem 56 de 70,
exatamente 80%, e o terceiro 53. A maioria faz **58, duas a mais que o melhor prompt sozinho**. Se
os três fossem independentes, a conta da seção anterior diz que uma maioria de votantes a 80%
acertaria cerca de 0,896 × 70, quase 63.

Então os três não são independentes. O jeito de ver quanto falta para isso é contar, para cada
caso, quantos dos três erraram:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}'; done | sort | uniq -c
      3 h01
      3 h04
      1 h06
      1 h07
      3 h11
      3 h13
      3 h14
      3 h15
      3 h16
      3 h19
      3 h20
      1 h22
      3 h26
      3 h27
      2 h28
      1 h30
      1 t08
      1 t19
      1 t22
      1 t26
      1 t37
      1 t39
```

O laço imprime cada caso que falhou em `json` ou `category` com cada prompt, e o `uniq -c` conta
com quantos prompts cada um falhou. Dez casos erraram com um prompt só, e a votação corrigiu todos:
os outros dois venceram no voto. Isso inclui respostas que não eram analisáveis, que não chegam a
votar. Um caso, `h28`, errou com dois prompts, e a votação foi com eles. **Onze casos erraram com
os três**, e aí votação nenhuma resolve.

Votantes independentes a 80% errariam os três no mesmo caso cerca de 0,008 das vezes, meio caso em
setenta. Estes três fizeram isso onze vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Setenta casos, pelo número de prompts, entre três, que erraram cada um. Se três votantes que acertam 80 por cento das vezes fossem independentes: 35,8 casos sem erro, 26,9 com um, 6,7 com dois, 0,6 com os três. Os três prompts medidos: 48 sem erro, 10 com um, 1 com dois, 11 com os três.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 casos, por quantos dos três erraram cada um</text><text x=\"200\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nenhum</text><rect x=\"163\" y=\"120.97599999999997\" width=\"34\" height=\"129.02400000000003\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"180.0\" y=\"111.97599999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35,8</text><rect x=\"203\" y=\"77.19999999999999\" width=\"34\" height=\"172.8\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"220.0\" y=\"68.19999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">48</text><text x=\"335\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um</text><rect x=\"298\" y=\"153.232\" width=\"34\" height=\"96.768\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"315.0\" y=\"144.232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26,9</text><rect x=\"338\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"355.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois</text><rect x=\"433\" y=\"225.808\" width=\"34\" height=\"24.192\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"450.0\" y=\"216.808\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6,7</text><rect x=\"473\" y=\"246.4\" width=\"34\" height=\"3.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"490.0\" y=\"237.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"605\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os três</text><rect x=\"568\" y=\"247.984\" width=\"34\" height=\"2.0160000000000005\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"585.0\" y=\"238.984\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,6</text><rect x=\"608\" y=\"210.4\" width=\"34\" height=\"39.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"625.0\" y=\"201.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><path d=\"M110 250 L660 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"218\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">se independentes</text><rect x=\"420\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estes três</text></svg>", "caption": "Votantes independentes espalham os erros pelos casos, onde uma maioria consegue vencê-los no voto. Estes três prompts empilharam os seus nos mesmos onze casos, onde voto nenhum ajuda."}
```

## Por que eles concordam

No substituto o motivo está à vista: os três prompts são lidos pela mesma tabela de palavras-chave.
Uma mensagem que o substituto lê errado, ele lê errado com qualquer redação, porque a redação muda
o que está em volta da mensagem e não a pontuação dela. Os onze são casos do holdout, as mensagens
mais difíceis, que é onde um ponto cego compartilhado estaria.

Modelos reais não são uma tabela de palavras-chave, mas o formato se mantém como observação de quem
trabalha com eles: **prompts enviados ao mesmo modelo tendem a compartilhar os erros dele**, porque
o que o modelo não sabe ele não sabe com redação nenhuma. A diversidade precisa vir de algum lugar
real, como outro modelo, outra evidência no prompt ou outro caminho até a resposta. Três redações de
um prompt são quase um votante contado três vezes.
