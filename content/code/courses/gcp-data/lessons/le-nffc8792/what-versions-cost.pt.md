---
title: O que custa guardar todas as versões
version: 1
---

**O versionamento multiplica a conta pelo número de gerações guardadas, e nada limita esse número a
não ser uma regra.** Um nome escrito uma vez por dia durante um ano são 365 gerações, cada uma cobrada
inteira, e a listagem que uma pessoa olha mostra um objeto. A exclusão reversível acrescenta um segundo
multiplicador que ninguém ligou: mais sete dias de todo objeto substituído ou apagado.

A tabela de clientes curada da Quitanda tem 50 GiB e é reescrita toda noite. O programa abaixo calcula
o preço de um ano dela em Standard, aos 0,035 USD por GiB-mês de São Paulo, em quatro arranjos:
versionamento sem regra; versionamento com uma regra que apaga cada versão não atual sete dias depois
de substituída; sem versionamento, com a exclusão reversível padrão; e sem versionamento com a exclusão
reversível desligada. Salve-o como `~/gcp/keep.py`:

```schooling-example
{"language": "python", "file": "keep.py", "parts": [{"code": "\"\"\"A table rewritten every night, for a year, under four arrangements.\"\"\"\n\nTABLE_GIB = 50     # the table, rewritten whole every night\nPRICE = 0.035      # Standard, southamerica-east1, USD per GiB-month\nKEEP = 7           # days a noncurrent version lives under the rule\nSOFT = 7           # days a deleted or replaced object stays soft-deleted\n\n\n", "note": "Os números de que a resposta depende. O preço é o Standard de São Paulo da página de preços, lida em 2026-10-30; `SOFT` é a duração da exclusão reversível que um bucket novo recebe, a não ser que alguém a mude."}, {"code": "def copies(day, arrangement):\n    most = {\n        'versions, no rule': day,\n        'versions, rule': 1 + KEEP + SOFT,\n        'no versions': 1 + SOFT,\n        'no soft delete': 1,\n    }[arrangement]\n    return min(day, most)\n\n\nARRANGEMENTS = ['versions, no rule', 'versions, rule', 'no versions', 'no soft delete']\n\n\n", "note": "**Quantas cópias da tabela o bucket paga num dado dia.** Com versionamento e sem regra, a versão de toda noite continua lá. Com regra, uma versão vive sete dias depois de substituída e mais sete excluída de forma reversível. Sem versionamento, cada tabela substituída fica excluída de forma reversível por sete dias. Só com a exclusão reversível desligada existe uma cópia só."}, {"code": "print(f'{\"month\":>5}' + ''.join(f'{a:>19}' for a in ARRANGEMENTS))\ntotal = dict.fromkeys(ARRANGEMENTS, 0.0)\nfor month in range(1, 13):\n    days = range((month - 1) * 30 + 1, month * 30 + 1)\n    row = f'{month:>5}'\n    for a in ARRANGEMENTS:\n        cost = sum(copies(d, a) for d in days) * TABLE_GIB * PRICE / 30\n        total[a] += cost\n        row += f'{cost:>19,.2f}'\n    print(row)\nprint(f'{\"year\":>5}' + ''.join(f'{total[a]:>19,.2f}' for a in ARRANGEMENTS))\nprint(f'{\"GiB\":>5}' + ''.join(f'{copies(360, a) * TABLE_GIB:>19,}' for a in ARRANGEMENTS))\n", "note": "Um mês tem 30 dias aqui, e o armazenamento de um dia é um trinta avos de um GiB-mês. Cada linha é o que o mês custou em cada arranjo; `year` soma os doze meses, e `GiB` é o que o bucket guarda no último dia do ano."}]}
```

```
ana@laptop:~/gcp$ python3 keep.py
month  versions, no rule     versions, rule        no versions     no soft delete
    1              27.13              20.13              12.37               1.75
    2              79.62              26.25              14.00               1.75
    3             132.13              26.25              14.00               1.75
    4             184.63              26.25              14.00               1.75
    5             237.13              26.25              14.00               1.75
    6             289.62              26.25              14.00               1.75
    7             342.13              26.25              14.00               1.75
    8             394.63              26.25              14.00               1.75
    9             447.13              26.25              14.00               1.75
   10             499.63              26.25              14.00               1.75
   11             552.12              26.25              14.00               1.75
   12             604.62              26.25              14.00               1.75
 year           3,790.50             308.88             166.37              21.00
  GiB             18,000                750                400                 50
```

**O último mês com versionamento e sem regra custa 604,62, e com a regra 26,25.** No fim do ano o
bucket sem regra guarda 360 cópias de uma tabela de 50 GiB, 18.000 GiB, para um conjunto de dados cujo
tamanho nunca mudou. O total do ano é 3.790,50 contra 308,88, mais de doze vezes, gasto em versões que
ninguém pediu depois da primeira semana.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"GiB guardados ao longo de um ano para uma tabela de 50 GiB reescrita toda noite. Com versionamento e sem regra a linha sobe 50 GiB por dia até 18.000 GiB no dia 360. Com uma regra de sete dias ela para em 750 GiB depois de quinze dias. Sem versionamento e com exclusão reversível ligada ela para em 400 GiB depois de oito dias.\" data-fig=\"l03-versions\"><path d=\"M90.0 260.0 L690.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 260.0 L90.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M235.0 260.0 L235.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"235.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M380.0 260.0 L380.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"380.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">180</text><path d=\"M525.0 260.0 L525.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"525.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">270</text><path d=\"M670.0 260.0 L670.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"670.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">360</text><path d=\"M85.0 260.0 L90.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M85.0 186.7 L90.0 186.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"186.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6.000</text><path d=\"M85.0 113.3 L90.0 113.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"113.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12.000</text><path d=\"M85.0 40.0 L90.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18.000</text><text x=\"20.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">GiB guardados</text><text x=\"690.0\" y=\"296.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">dia do ano</text><path d=\"M90.0 260.0 L670.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 260.0 L114.2 250.8 L670.0 250.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 260.0 L102.9 255.1 L670.0 255.1\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"666.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">versões, sem regra: 18.000 GiB</text><text x=\"670.0\" y=\"232.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">versões e regra de 7 dias: 750 GiB</text><text x=\"122.2\" y=\"243.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem versões, exclusão reversível: 400 GiB</text></svg>", "caption": "A mesma tabela e a mesma escrita toda noite. Uma regra transforma uma linha sem fim num teto; a exclusão reversível sozinha faz um teto mais baixo."}
```

**A regra muda a forma, e o tamanho da tabela não importa para o argumento.** Sem regra o tamanho
guardado cresce uma cópia da tabela toda noite, enquanto o bucket existir. Com regra ele sobe por
quinze dias e depois fica plano: a tabela viva, sete versões não atuais, e mais sete que a regra apagou
e a exclusão reversível ainda guarda. Uma tabela dez vezes maior dá uma conta dez vezes maior em toda
coluna, e as mesmas proporções entre elas.

**A terceira e a quarta colunas são o custo da exclusão reversível sozinha.** Com o versionamento
desligado, a tabela substituída de cada noite ainda é guardada por sete dias, então o bucket tem oito
cópias, 400 GiB, e paga 166,37 por ano onde uma cópia pagaria 21,00. Ninguém escolheu isso: é o padrão.
Para uma tabela que é reconstruída a partir das fontes toda noite, os sete dias protegem algo que pode
ser produzido de novo, e a Quitanda desliga a exclusão reversível nesse bucket com
`--clear-soft-delete`. No bucket raw, onde uma exportação apagada por engano não pode ser produzida de
novo, ela a mantém ligada.

A conta considera o armazenamento e nada mais, porque é o armazenamento que cresce. A escrita de cada
noite é uma operação Class A em qualquer arranjo, e uma exclusão feita por uma regra de ciclo de vida
nem é cobrada como operação; a página de preços lista o `Delete` do Object Lifecycle Management entre
as gratuitas.

## Quantos dias guardar

**Sete dias é uma escolha sobre quanto tempo um erro pode passar despercebido**, não um número com
resposta certa. Uma versão não atual é um caminho de volta de um job noturno ruim, e só serve enquanto
alguém ainda perceberia que o job foi ruim. Os analistas da Quitanda olham a tabela de clientes toda
manhã, então uma reescrita quebrada é vista em um dia e sete é generoso. Uma tabela lida uma vez por mês
precisa de um mês e alguns dias. Uma regra também pode guardar um número fixo de versões não atuais em
vez de um número de dias, com a condição `numNewerVersions`, o que serve para um nome escrito de forma
irregular: com `numNewerVersions: 3` uma versão é apagada quando existem três mais novas, por mais tempo
que isso tenha levado.

**Duas proteções com o mesmo trabalho são pagas duas vezes.** Num bucket versionado com uma regra de
sete dias, a exclusão reversível acrescenta mais sete dias a cada versão que a regra apaga. Isso vale a
pena onde um erro pode ser percebido tarde, e é desperdício onde os sete dias da regra já são a margem.
Escolha primeiro o total de dias de proteção, depois decida qual mecanismo os dá.
