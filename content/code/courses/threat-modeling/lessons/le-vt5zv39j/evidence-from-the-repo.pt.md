---
title: Evidência a partir do repositório
version: 1
---

Cada aula deste curso acrescentou um commit a `~/tm/portal-model`. Um auditor que pede "me mostre que
modelagem de ameaças acontece aqui, e quando" está pedindo exatamente esse histórico:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %an %s" --date=short
fa6c2ba 2026-10-06 ana List what the insurer asked for, and check it
d3b266b 2026-10-05 ana Map the controls to ISO 27001 and the NIST CSF
7060908 2026-10-01 ana Record the first decisions
dfe7ca2 2026-09-29 ana Rank the controls by what they save
dfe011c 2026-09-24 ana Simulate the ranges, and compare with a matrix
16259cb 2026-09-22 ana Estimate the expected loss of the larger risks
2b965bc 2026-09-17 ana Write a requirement for each threat
72b7507 2026-09-14 ana Add the threats the abuse cases found
23e3e45 2026-09-10 ana Draw the console as it is: reachable from the internet
088ee69 2026-09-10 ana List the entry and exit points
f602de2 2026-09-08 ana Model one goal as an attack tree
4799e48 2026-09-03 ana List the threats found with STRIDE
839eba3 2026-09-03 ana Summarise what pytm finds
0cc253e 2026-09-01 ana Draw the portal as a data flow diagram
```

Catorze commits em cinco semanas, cada um um passo que uma pessoa sabe nomear. É boa evidência de um
**processo**: o modelo foi construído ao longo do tempo, numa ordem que faz sentido, e não montado na
semana antes da auditoria. Um único commit de 6 de outubro com todos os arquivos diria o contrário,
por melhores que fossem os arquivos.

O histórico de um arquivo responde a uma pergunta mais estreita, como quando a lista de ameaças mudou
pela última vez:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %s" --date=short -- threats.csv
72b7507 2026-09-14 Add the threats the abuse cases found
4799e48 2026-09-03 List the threats found with STRIDE
```

Duas mudanças, a última em 14 de setembro. Um auditor lê isso de dois jeitos: as ameaças foram
revisitadas uma vez depois da primeira passada, o que é bom; e **nada foi acrescentado desde então**,
embora o console tenha sido redesenhado e três documentos tenham chegado de fora. A aula 15 é sobre
essa segunda leitura.

### O que ele não prova

O git é evidência forte de algumas coisas e fraca de outras, e a diferença importa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l14-git\" aria-label=\"O que um histórico git mostra como evidência, e com que força. O conteúdo de cada arquivo em cada commit: forte, porque cada commit nomeia o pai por hash. A ordem dos commits: forte depois de enviada a um remoto que outros usam. A data de um commit: fraca, porque quem faz o commit a escreve. Quem escreveu: fraco, um nome na configuração, a não ser que o commit seja assinado. Que o daniel aprovou o RA-001: só o que o arquivo diz.\"><rect x=\"20.0\" y=\"20.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o conteúdo de cada arquivo em cada commit</text><rect x=\"340.0\" y=\"20.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">forte: cada commit nomeia o pai por hash</text><rect x=\"20.0\" y=\"66.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a ordem dos commits</text><rect x=\"340.0\" y=\"66.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">forte, depois de enviado a um remoto que outros usam</text><rect x=\"20.0\" y=\"112.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a data de um commit</text><rect x=\"340.0\" y=\"112.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fraca: quem faz o commit a escreve</text><rect x=\"20.0\" y=\"158.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem escreveu</text><rect x=\"340.0\" y=\"158.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fraca: um nome na configuração, a não ser que assinado</text><rect x=\"20.0\" y=\"204.0\" width=\"300.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">que o daniel aprovou o RA-001</text><rect x=\"340.0\" y=\"204.0\" width=\"360.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só o que o arquivo diz</text></svg>", "caption": "O git é ótima evidência do que mudou e em que ordem, e evidência fraca de quando e por quem. Um auditor cuidadoso sabe qual metade está lendo."}
```

**O conteúdo e a ordem são fortes.** Cada commit nomeia o pai por um hash do conteúdo, então mudar um
arquivo antigo muda todos os hashes depois dele. Depois que o histórico é enviado a um remoto de onde
outras pessoas buscam, reescrevê-lo aparece.

**As datas e os nomes são fracos.** Os dois são escritos por quem faz o commit. O próprio laboratório
deste curso define todas as datas de propósito, para as capturas se repetirem, e nada no histórico
acima mostra isso. Um auditor trata a data de um commit como a afirmação de quem o fez, mais forte
com o registro do próprio remoto hospedado de quando um push chegou, ou com branches protegidas que
só aceitam mudanças por revisão.

**Uma aprovação num arquivo é só o que o arquivo diz.** O RA-001 nomeia o dono:

```
(.venv) ana@vm:~/tm/portal-model$ grep owner decisions/RA-001-crafted-pdf.md
owner: daniel
(.venv) ana@vm:~/tm/portal-model$ git log --format="%an <%ae>" -- decisions/RA-001-crafted-pdf.md
ana <ana@vereda.example>
```

O daniel é o dono, e a ana fez o commit do arquivo. Nada no repositório mostra que o daniel o leu.
Isso não é um defeito do RA-001; é uma lacuna em como as aprovações são registradas, e há correções
comuns. O daniel pode aprovar a mudança na revisão da plataforma de hospedagem, que registra a conta
do daniel e a hora; ou o próprio daniel pode fazer o commit, assinado com a própria chave. Qualquer um dos dois
transforma "o arquivo diz daniel" em "o daniel fez".

### O modelo confere a si mesmo

Algumas evidências são produzidas rodando os próprios programas do modelo. O `trace.py` da aula 8
resume a cobertura:

```
(.venv) ana@vm:~/tm/portal-model$ python3 trace.py | tail -3
17 threats, 19 requirements
no requirement: T14
not verified:   R14 R17
```

Esta é uma evidência de outro tipo: não de que algo aconteceu, mas de que o modelo sabe onde está
incompleto. A T14 não tem requisito porque foi aceita, e o RA-001 diz isso. O R14 e o R17 ainda não
têm verificação. **Um auditor confia mais num modelo que lista as próprias lacunas** do que num que não
tem nenhuma, porque um modelo sem lacunas normalmente não foi olhado de perto.
