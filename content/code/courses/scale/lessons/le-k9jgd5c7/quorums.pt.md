---
title: Quóruns, a aritmética da sobreposição
version: 1
---

A replicação do PostgreSQL tem um primário que decide tudo. Muitos bancos distribuídos não têm
primário nenhum: qualquer réplica aceita uma escrita, e o cliente, ou um coordenador agindo por ele,
manda a escrita para várias réplicas e lê de várias. **Quantas é o desenho inteiro**, e cabe em três
letras:

- **N**, quantas réplicas guardam cada valor;
- **W**, quantas precisam confirmar uma escrita antes de ela contar como feita;
- **R**, quantas são perguntadas numa leitura, vencendo a resposta mais nova.

A regra é curta: **se W + R > N, toda leitura se sobrepõe a toda escrita concluída em pelo menos uma
réplica**, então a leitura a vê. Com N = 3, uma escrita confirmada por duas e uma leitura que
pergunta a duas precisam dividir uma réplica, porque duas e duas de três não conseguem se evitar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três réplicas, a, b e c. Uma escrita confirmada por W igual a 2 réplicas, a e b, está contornada numa cor. Uma leitura que pergunta a R igual a 2 réplicas, b e c, está contornada em outra. Os dois contornos dividem a réplica b, que tem a versão nova, então a leitura a devolve.\"><circle cx=\"180\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"180\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">a</text><text x=\"180\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new</text><circle cx=\"330\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">b</text><text x=\"330\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">new</text><circle cx=\"480\" cy=\"110\" r=\"34\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"480\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">c</text><text x=\"480\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">old</text><rect x=\"130\" y=\"62\" width=\"250\" height=\"96\" rx=\"40\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></rect><rect x=\"280\" y=\"52\" width=\"250\" height=\"116\" rx=\"46\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"2 4\"></rect><text x=\"200\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">escrita: W = 2</text><text x=\"470\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">leitura: R = 2</text><text x=\"330\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">b está nas duas</text></svg>", "caption": "N = 3, W = 2, R = 2. Quaisquer dois de três se sobrepõem em pelo menos um, então toda leitura encontra toda escrita concluída."}
```

Este programa confere isso, e o preço de cada configuração quando uma réplica está fora:

```schooling-example
{"language": "python", "file": "quorum.py", "parts": [{"code": "# quorum.py\n\"\"\"Three replicas, one value, and what each choice of W and R can promise.\"\"\"\nN = 3", "note": "**N** é quantas réplicas guardam cada valor. Tudo abaixo trata de três."}, {"code": "\n\ndef run(w, r, down=()):\n    replicas = [{\"name\": n, \"version\": 1, \"value\": \"old\", \"up\": n not in down} for n in \"abc\"]", "note": "Cada réplica começa com a versão 1 do valor, `old`. `down` nomeia réplicas que não podem ser alcançadas."}, {"code": "    # A write is acknowledged once W replicas have it. The others get it\n    # later; this is the moment before they do.\n    reached = [rep for rep in replicas if rep[\"up\"]][:w]\n    wrote = len(reached) == w\n    if wrote:\n        for rep in reached:\n            rep[\"version\"], rep[\"value\"] = 2, \"new\"", "note": "**A escrita** dá certo quando **W** réplicas de pé a receberam. Se menos de W estão de pé, ela falha, que é o preço de um W grande."}, {"code": "    # A read asks R replicas, starting from the far end, the worst case,\n    # and keeps the answer with the highest version.\n    asked = [rep for rep in reversed(replicas) if rep[\"up\"]][:r]\n    read = max(asked, key=lambda rep: rep[\"version\"])[\"value\"] if len(asked) == r else None\n    return wrote, read", "note": "**A leitura** pergunta a **R** réplicas, escolhendo as que têm menos chance de ter a escrita, e confia na versão mais nova entre as respostas. Se menos de R estão de pé, ela falha."}, {"code": "\n\nprint(\" W  R  W+R>N  read after write   one replica down: write  read\")\nfor w, r in ((1, 1), (2, 2), (3, 1), (1, 3)):\n    _, seen = run(w, r)\n    wrote_down, read_down = run(w, r, down=\"c\")\n    print(f\" {w}  {r}  {'yes' if w + r > N else 'no ':5}  {seen:15}  \"\n          f\"{'ok' if wrote_down else 'FAILS':>22}  {'ok' if read_down else 'FAILS':>5}\")", "note": "Quatro configurações, cada uma rodada duas vezes: com toda réplica de pé, para ver o que uma leitura logo depois de uma escrita devolve, e com a réplica `c` fora, para ver quais operações ainda funcionam."}]}
```

```
ana@lab:~/tickets$ python3 quorum.py
 W  R  W+R>N  read after write   one replica down: write  read
 1  1  no     old                                  ok     ok
 2  2  yes    new                                  ok     ok
 3  1  yes    new                               FAILS     ok
 1  3  yes    new                                  ok  FAILS
```

Quatro configurações, e cada uma é uma posição de verdade:

- **W = 1, R = 1** é a mais rápida e não promete nada: a leitura perguntou a uma réplica que a
  escrita não tinha alcançado e devolveu `old`. As duas operações sobrevivem a uma réplica fora.
- **W = 2, R = 2**, um **quórum de maioria**, lê `new` e sobrevive a uma réplica fora nas duas
  operações. Com N = 3 é a escolha de costume, e custa esperar a segunda réplica mais rápida em toda
  operação.
- **W = 3, R = 1** deixa as leituras baratas e as escritas frágeis: uma réplica fora e **nenhuma
  escrita termina**.
- **W = 1, R = 3** é o espelho: escritas baratas, e nenhuma leitura termina com uma réplica fora.

Os quóruns são como um sistema transforma o CAP num botão. Durante uma partição, um lado com menos
de W réplicas não consegue escrever e um lado com menos de R não consegue ler; fora dela, um W + R
maior compra leituras mais frescas com operações mais lentas, que é a troca do PACELC com números.

**W + R > N é necessário e não suficiente.** Duas escritas no mesmo valor no mesmo instante podem
alcançar maiorias diferentes, e as réplicas então discordam sobre qual veio por último. Um quórum
garante que uma leitura encontra a versão mais nova; decidir qual versão é a mais nova é o problema
da seção 08.
