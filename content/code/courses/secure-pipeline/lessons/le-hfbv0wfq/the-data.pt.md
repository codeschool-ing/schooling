---
title: Um ano de achados, gerado
version: 1
---

Achados reais pertencem a uma empresa real e não são algo que um curso possa distribuir, e um
pipeline num laptop produz algumas dezenas, poucos demais para mostrar o que uma mediana faz. Então o
conjunto de dados desta aula é gerado: um ano de achados de uma empresa inventada com quatro times,
catorze alvos e os quatro tipos de scanner que este curso pôs no pipeline.

**Gerado não quer dizer aleatório.** O programa abaixo fixa a semente do próprio gerador de números
aleatórios, então toda execução escreve os mesmos dois arquivos, e os números que você medir na sua
máquina são os desta aula. Isso também deixa você ler a causa por trás de cada padrão que as medições
encontram, coisa que um painel real nunca oferece: quando os números de um time parecerem bons demais
na seção sobre a lei de Goodhart, você pode achar a linha que os fez assim.

### O gerador

Crie um diretório para a aula, fora do projeto, já que esses números descrevem uma empresa e não o
linkbox:

```
ana@vm:~$ mkdir ~/metrics && cd ~/metrics
ana@vm:~/metrics$ python3 --version
Python 3.13.16
```

Ele só precisa de Python 3. Salve como `~/metrics/gen.py`:

```schooling-example
{"language": "python", "file": "gen.py", "parts": [{"code": "\"\"\"A year of security findings for a made-up company of four teams, the\nsame every time it runs. It writes two files: inventory.csv, what exists\nand which scanners look at it, and findings.csv, what those scanners found\nand what happened to each finding.\"\"\"\nimport csv\nimport datetime as dt\nimport math\nimport random\n", "note": "Só a biblioteca padrão, então o programa roda em qualquer Python 3 sem instalar nada."}, {"code": "rng = random.Random(19)\nSTART, TODAY = dt.date(2025, 10, 1), dt.date(2026, 10, 1)\n", "note": "**A semente é o que faz disto um conjunto de dados e não um sorteio.** Toda execução de `random.Random(19)` produz a mesma sequência, então os seus arquivos batem byte a byte com os medidos nesta aula. `TODAY` é fixo pelo mesmo motivo: a idade de um achado aberto depende dele."}, {"code": "# What exists: name, team, kind, and the scanners that run on it.\nINVENTORY = [\n    (\"linkbox\", \"links\", \"repo\", \"sast sca secrets\"),\n    (\"linkbox\", \"links\", \"image\", \"image\"),\n    (\"link-stats\", \"links\", \"repo\", \"sast sca secrets\"),\n    (\"billing-api\", \"payments\", \"repo\", \"sast sca secrets\"),\n    (\"billing-api\", \"payments\", \"image\", \"image\"),\n    (\"invoices\", \"payments\", \"repo\", \"sca secrets\"),\n    (\"refunds-worker\", \"payments\", \"image\", \"\"),\n    (\"storefront\", \"web\", \"repo\", \"sast sca secrets\"),\n    (\"storefront\", \"web\", \"image\", \"image\"),\n    (\"web-assets\", \"web\", \"repo\", \"secrets\"),\n    (\"auth-gateway\", \"platform\", \"repo\", \"sast sca secrets\"),\n    (\"auth-gateway\", \"platform\", \"image\", \"image\"),\n    (\"legacy-reports\", \"platform\", \"repo\", \"\"),\n    (\"legacy-reports\", \"platform\", \"image\", \"\"),\n]\n", "note": "Catorze alvos: oito repositórios e seis imagens, e os scanners apontados para cada um. Dois nomes não têm nada apontado para eles, e `invoices` não tem análise estática. A cobertura é medida a partir desta lista, nunca a partir dos achados."}, {"code": "# Findings a scanner raises per month on one target, and their severities.\nRATE = {\"sast\": 2.0, \"sca\": 2.5, \"secrets\": 0.2, \"image\": 4.0}\nSEVERITY = {\"critical\": 0.05, \"high\": 0.20, \"medium\": 0.45, \"low\": 0.30}\n# The median number of days a fix takes, per severity.\nTYPICAL_FIX = {\"critical\": 5, \"high\": 18, \"medium\": 40, \"low\": 70}\n\n", "note": "O quanto cada scanner é ruidoso, por alvo e por mês, e a mistura de severidades. `TYPICAL_FIX` é a mediana que uma correção leva quando alguém de fato corrige."}, {"code": "def poisson(mean):\n    n, p, limit = 0, 1.0, math.exp(-mean)\n    while True:\n        p *= rng.random()\n        if p < limit:\n            return n\n        n += 1\n\n", "note": "Um sorteio de Poisson, pelo método de Knuth: quantos achados chegam num dia quando a média é uma fração de um."}, {"code": "def outcome(team, severity):\n    \"\"\"How a finding leaves the open list, and how many days that takes.\"\"\"\n    roll = rng.random()\n    if roll < 0.08:\n        return \"false_positive\", rng.randint(1, 10)\n    # One team closes much of what is not urgent as \"won't fix\", and fast.\n    if team == \"payments\" and severity in (\"medium\", \"low\") and roll < 0.55:\n        return \"wont_fix\", rng.randint(1, 5)\n    if roll < 0.12:\n        return \"wont_fix\", rng.randint(10, 60)\n    return \"fixed\", max(1, round(TYPICAL_FIX[severity] * rng.lognormvariate(0, 0.9)))\n\n", "note": "Como um achado sai da lista. A maioria é corrigida, depois de um número de dias sorteado em torno de `TYPICAL_FIX` com uma cauda longa; alguns são falsos positivos descobertos rápido; alguns são fechados como \"não vou corrigir\". **A linha do `payments` foi plantada de propósito**, para a seção sobre a lei de Goodhart ter um time manipulando a mediana para você achar."}, {"code": "findings = []\nfor name, team, kind, scanners in INVENTORY:\n    for tool in scanners.split():\n        day = START\n        while day < TODAY:\n            for _ in range(poisson(RATE[tool] / 30)):\n                severity = rng.choices(list(SEVERITY), list(SEVERITY.values()))[0]\n                if tool == \"secrets\":  # a leaked credential is high, always\n                    severity = \"high\"\n                resolution, days = outcome(team, severity)\n                closed = day + dt.timedelta(days=days)\n                if closed > TODAY:\n                    resolution, closed = \"\", None\n                findings.append([name, kind, team, tool, severity, day, closed, resolution])\n            day += dt.timedelta(days=1)\n", "note": "Um dia de cada vez, para cada scanner em cada alvo. Um achado cuja data de fechamento cai depois de `TODAY` continua aberto, então `closed` e `resolution` ficam vazios."}, {"code": "findings.sort(key=lambda f: f[5])\nwith open(\"findings.csv\", \"w\", newline=\"\") as out:\n    w = csv.writer(out)\n    w.writerow([\"id\", \"target\", \"kind\", \"team\", \"tool\", \"severity\", \"opened\", \"closed\", \"resolution\"])\n    for n, f in enumerate(findings, 1):\n        w.writerow([f\"F{n:04d}\", *f[:6], f[6] or \"\", f[7]])\nwith open(\"inventory.csv\", \"w\", newline=\"\") as out:\n    w = csv.writer(out)\n    w.writerow([\"target\", \"team\", \"kind\", \"scanners\"])\n    w.writerows(INVENTORY)\nprint(f\"{len(findings)} findings on {len(INVENTORY)} targets\")", "note": "Dois arquivos CSV, ordenados pelo dia em que cada achado foi aberto, com um id por achado."}]}
```

Três escolhas dentro dele dão forma a tudo o que é medido depois, e cada uma imita algo real.

**Os tempos de correção têm cauda longa.** Uma correção é sorteada como um número típico de dias para
a severidade dela, multiplicado por um fator log-normal. A maioria das correções cai perto do valor
típico e algumas levam três ou quatro vezes mais: a dependência cuja atualização quebra uma
interface, o achado que não tem dono. Tempos de correção costumam ter esse formato, e é por causa
dele que a próxima seção defende a mediana.

**Nem tudo sai da lista por ter sido corrigido.** Cerca de um achado em doze é falso positivo,
descoberto em poucos dias, e alguns são fechados como "não vou corrigir" depois de semanas. O time
`payments` fecha quase metade dos achados médios e baixos como "não vou corrigir" em até cinco dias.
Nada na saída marca esse time como especial; só as medições conseguem achá-lo.

**O inventário faz parte dos dados.** Dois alvos não têm scanner nenhum e alguns têm só um ou dois.
Um gerador só de achados não conseguiria mostrar o que falta, porque um alvo sem scanner não produz
linha nenhuma.

### Rodando

```
ana@vm:~/metrics$ python3 gen.py
509 findings on 14 targets
ana@vm:~/metrics$ sha256sum findings.csv inventory.csv
fc6105a65c5c57724e841df691dfa1f73a1b7617e5ca611df3ef3239226b5faa  findings.csv
3b06a2c6982610dcb6849d9bd4538fd97f9d6db9201241ec9014d7db9c218960  inventory.csv
ana@vm:~/metrics$ python3 gen.py
509 findings on 14 targets
ana@vm:~/metrics$ sha256sum findings.csv inventory.csv
fc6105a65c5c57724e841df691dfa1f73a1b7617e5ca611df3ef3239226b5faa  findings.csv
3b06a2c6982610dcb6849d9bd4538fd97f9d6db9201241ec9014d7db9c218960  inventory.csv
```

Duas execuções, os mesmos checksums: é isso que a semente compra. Se os seus checksums forem
diferentes, a sua cópia do programa difere da de cima, e todo número desta aula também vai ser
diferente.

O arquivo de achados começa assim, uma linha por achado, com o cabeçalho primeiro:

```
ana@vm:~/metrics$ head -n 6 findings.csv
id,target,kind,team,tool,severity,opened,closed,resolution
F0001,linkbox,repo,links,secrets,high,2025-10-01,2025-11-06,fixed
F0002,linkbox,image,links,image,medium,2025-10-02,2025-11-27,fixed
F0003,billing-api,image,payments,image,medium,2025-10-02,2025-10-24,fixed
F0004,auth-gateway,repo,platform,sast,medium,2025-10-04,2025-11-18,fixed
F0005,linkbox,repo,links,sast,high,2025-10-06,2025-10-16,fixed
ana@vm:~/metrics$ wc -l findings.csv inventory.csv
  510 findings.csv
   15 inventory.csv
  525 total
```

509 achados e a linha de cabeçalho, 14 alvos e a deles. Cada linha diz onde estava o achado
(`target` e `kind`), de quem ele é (`team`), qual scanner o levantou (`tool`), o quanto é sério
(`severity`) e as duas datas. `resolution` é como ele saiu da lista, e `closed` e `resolution` ficam
vazios enquanto ele está aberto.

### Uma primeira olhada, sem programa nenhum

Antes de escrever qualquer medição, conte a coluna que mais importa. O `cut` pega o nono campo, e o
`uniq -c` conta cada valor:

```
ana@vm:~/metrics$ cut -d, -f9 findings.csv | sort | uniq -c
     59 
     42 false_positive
    338 fixed
      1 resolution
     70 wont_fix
```

O valor vazio são os achados abertos, 59 deles, e `resolution` é a linha de cabeçalho contada junto.
338 foram corrigidos, 70 fechados como "não vou corrigir" e 42 se revelaram falsos positivos. Essa
linha já diz algo que um total não diria: **cerca de um achado fechado em quatro saiu da lista sem
ser corrigido**, e qualquer número que trate "fechado" como "corrigido" está contando esses 112 como
trabalho feito.

Uma contagem dessas vale a pena em dados reais antes de qualquer outra coisa, pelo mesmo motivo. Se
uma ferramenta de acompanhamento guarda só "aberto" e "fechado", não há nada para contar aqui, e todo
número posterior é construído sobre uma mistura de três desfechos diferentes.
