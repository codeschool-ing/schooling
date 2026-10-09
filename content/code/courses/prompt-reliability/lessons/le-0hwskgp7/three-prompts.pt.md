---
title: Três prompts que concordam demais
version: 2
---

O ensemble óbvio são três prompts que você já tem. `v3-examples`, `v4-only-json` e `v6-escaped`
foram escritos cada um para corrigir alguma coisa, e têm redações diferentes. Uma votação precisa de
um programa que a conte, e este é curto. Ele lê a categoria de cada resposta, só a conta como certa
quando a resposta é analisável e bate com o rótulo da pessoa, e fica com a maioria em cada caso. Uma
resposta que não é analisável não vota. Salve-o como `vote.py`:

```python
"""vote: the category each run gave each case, and what a majority of them
says. Several run files vote as one voter each; one run file with samples
votes with its samples."""
import collections
import sys

from pl import parse, read_jsonl


def answers(path):
    """case -> the categories its replies gave, None for a reply that does not parse."""
    found = collections.defaultdict(list)
    for r in read_jsonl(path):
        found[r["case"]].append((parse(r["text"]) or {}).get("category"))
    return found


paths = sys.argv[1:]
runs = [answers(p) for p in paths]
expect = {c["id"]: c["expect"]["category"] for c in read_jsonl(read_jsonl(paths[0])[0]["cases"])}
if len(runs) == 1:
    ballots = runs[0]
    voters = ["sample %d" % n for n in range(len(next(iter(ballots.values()))))]
    columns = [{k: v[n] for k, v in ballots.items()} for n in range(len(voters))]
else:
    voters = paths
    columns = [{k: v[0] for k, v in run.items()} for run in runs]
    ballots = {k: [col[k] for col in columns] for k in expect}

for name, col in zip(voters, columns):
    print("%-24s %3d/%d right" % (name, sum(col[k] == expect[k] for k in expect), len(expect)))
majority = unanimous = ties = 0
for k in expect:
    counts = collections.Counter(b for b in ballots[k] if b is not None).most_common()
    if len(counts) > 1 and counts[0][1] == counts[1][1]:
        ties += 1
    elif counts and counts[0][0] == expect[k]:
        majority += 1
    unanimous += len(set(ballots[k])) == 1
print("%-24s %3d/%d right" % ("majority of %d" % len(columns), majority, len(expect)))
print("unanimous on %d cases, a tie on %d" % (unanimous, ties))
```

Rode os três prompts sobre os setenta casos e vote:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl
70 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl
70 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ python3 vote.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl
runs/v3.jsonl             54/70 right
runs/v4.jsonl             45/70 right
runs/v6.jsonl             45/70 right
majority of 3             49/70 right
unanimous on 47 cases, a tie on 3
```

Os três fazem 54, 45 e 45. A maioria faz **49, cinco a menos que o `v3-examples` sozinho**. Três
tentativas na mesma pergunta se saíram pior que a melhor delas.

A conta da seção anterior explica parte disso, antes de qualquer medição. Com votantes que acertam
54, 45 e 45 vezes em setenta, e independentes entre si, uma maioria acertaria cerca de 0,77 das
vezes, perto de 54. **Uma votação de um votante forte e dois mais fracos é no máximo tão boa quanto
o forte**, porque os dois mais fracos o vencem toda vez que concordam. Aqui eles concordaram mais
vezes do que o acaso faria.

## Para onde foram os votos

Conte, para cada caso, quantos dos três erraram:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}'; done | sort | uniq -c | sort -rn
      3 t26
      3 t25
      3 t22
      3 h27
      3 h23
      3 h21
      3 h11
      3 h07
      3 h06
      3 h05
      3 h03
      3 h01
      2 t38
      2 t31
      2 t19
      2 t06
      2 h30
      2 h28
      2 h22
      2 h19
      2 h17
      2 h12
      1 t39
      1 t37
      1 t36
      1 t33
      1 t10
      1 t01
      1 h26
      1 h24
      1 h16
      1 h08
```

O laço imprime cada caso que reprovou em `json` ou `category` em cada prompt, e o `uniq -c` conta
em quantos prompts cada um reprovou. Dez casos erraram em um prompt só, e a votação corrigiu todos.
Dez erraram em dois. **Doze erraram nos três**, e ali voto nenhum faz nada.

Votantes com essa taxa de acerto, se fossem independentes, errariam todos o mesmo caso cerca de 2
vezes em setenta. Estes três fizeram isso doze vezes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Setenta casos, pelo número de prompts, entre três, que erraram cada um. Se os três, que acertam 54, 45 e 45 vezes em 70, fossem independentes: 22,3 casos sem erro, 31,4 com um, 14,2 com dois, 2,0 com os três. Os três prompts medidos: 38 sem erro, 10 com um, 10 com dois, 12 com os três.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 casos, por quantos dos três erraram cada um</text><text x=\"200\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nenhum</text><rect x=\"163\" y=\"169.7\" width=\"34\" height=\"80.3\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"180.0\" y=\"160.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22,3</text><rect x=\"203\" y=\"113.2\" width=\"34\" height=\"136.8\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"220.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">38</text><text x=\"335\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um</text><rect x=\"298\" y=\"137.0\" width=\"34\" height=\"113.0\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"315.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">31,4</text><rect x=\"338\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"355.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois</text><rect x=\"433\" y=\"198.9\" width=\"34\" height=\"51.1\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"450.0\" y=\"189.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14,2</text><rect x=\"473\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"490.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"605\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os três</text><rect x=\"568\" y=\"242.8\" width=\"34\" height=\"7.2\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"585.0\" y=\"233.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2,0</text><rect x=\"608\" y=\"206.8\" width=\"34\" height=\"43.2\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"625.0\" y=\"197.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M110 250 L660 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"218\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">se independentes</text><rect x=\"420\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estes três</text></svg>", "caption": "Votantes independentes espalhariam os erros pelos casos, onde uma maioria consegue vencê-los no voto. Estes três prompts empilharam os seus nos mesmos doze casos, onde voto nenhum ajuda."}
```

Os casos errados em dois prompts são onde a votação perdeu para o `v3-examples`. Grave as falhas de
cada prompt num arquivo e peça ao `comm` os casos que o `v4-only-json` e o `v6-escaped` erraram e o
`v3-examples` acertou, e o inverso:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}' | sort > runs/$r.wrong; done
ana@lab:~/triage$ comm -12 runs/v4.wrong runs/v6.wrong | comm -23 - runs/v3.wrong | paste -sd " "
h12 h17 h22 h28 h30 t06 t19 t31 t38
ana@lab:~/triage$ comm -23 runs/v3.wrong <(sort -m runs/v4.wrong runs/v6.wrong) | paste -sd " "
h08 h16 t33
```

Nove casos foram para um lado e três para o outro. Dos nove, cinco perderam no voto. Três foram
empates, porque os dois prompts mais fracos não concordaram na resposta errada, ou um deles não era
analisável, e o `vote.py` conta empate como erro. E o `t38` sobreviveu: nenhuma das respostas dos
prompts mais fracos era analisável, então o único voto foi o do `v3-examples`, e estava certo. Os
três casos do outro lado, `h08`, `h16` e `t33`, são onde a votação cumpriu seu papel. Cinco perdidos
no voto, três em empates, três recuperados: 54 − 8 + 3 = 49.

## Por que concordam

Os três prompts são lidos pelo mesmo modelo. **Prompts enviados ao mesmo modelo tendem a compartilhar
os erros dele**, porque o que o modelo erra sobre uma mensagem, ele erra na maioria das redações. Nove
dos doze são casos do holdout, as mensagens mais difíceis, que é onde um ponto cego comum apareceria.

É uma observação de quem pratica, e os doze daqui são uma medição dela, não uma prova. Na prática, a
diversidade tem de vir de algum lugar real: outro modelo, outra evidência no prompt, ou outro caminho
até a resposta. Três reescritas de um prompt estão mais perto de um votante contado três vezes do
que de três votantes.
