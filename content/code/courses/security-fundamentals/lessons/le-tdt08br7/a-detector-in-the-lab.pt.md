---
title: Um detector no laboratório
version: 1
---

Para contar os quatro resultados você precisa de duas coisas: um detector, e a verdade para comparar
com ele. A verdade é a parte difícil na vida real, porque ninguém rotula os ataques para você. Aqui ela
vem do mesmo lugar de onde uma equipe real a tira durante um exercício roxo: **o cronograma do próprio
exercício.**

O laboratório guarda uma semana de tentativas de login nos sistemas da loja, de segunda, 28 de
setembro, a domingo, 4 de outubro. Ela é gerada, e não gravada, para que a verdade de cada linha seja
conhecida; o script que monta o laboratório diz exatamente o que entrou nela. Em resumo: as nove
pessoas da equipe fazendo login com um ou outro erro de digitação, um backup cuja senha expirou
falhando toda noite, e um exercício autorizado a partir de dois endereços na internet, um adivinhando
rápido e outro devagar.

```
ana@laptop:~$ wc -l logins.csv
275 logins.csv
ana@laptop:~$ grep -m 3 ",fail$" logins.csv
2026-09-28T02:00:05,192.168.20.40,svc-backup,fail
2026-09-28T02:00:25,192.168.20.40,svc-backup,fail
2026-09-28T02:00:45,192.168.20.40,svc-backup,fail
ana@laptop:~$ cat red-team-sources.txt
203.0.113.50
203.0.113.77
```

O arquivo tem um cabeçalho e 274 tentativas, uma por linha: quando, de onde, qual conta e se deu certo.
As primeiras falhas da semana são da conta do backup às duas da manhã. O cronograma do exercício nomeia
os dois endereços de origem, e essa é toda a verdade contra a qual o detector vai ser medido: **uma
falha de um desses dois endereços era o exercício, e qualquer outra não era.**

### O detector

A regra é a que a maioria dos sistemas usa no começo: **gerar um alerta quando um endereço falha o
login pelo menos N vezes em dez minutos.** Aqui está ela, em umas vinte linhas de Python, com a nota ao
lado de cada pedaço dizendo o que ele faz. Você não precisa escrever Python para ler as notas.

```schooling-example
{"language": "python", "file": "detect.py", "parts": [{"code": "import csv\nimport sys\nfrom collections import Counter"}, {"code": "threshold = int(sys.argv[1])\nignored = set(sys.argv[2:])", "note": "O limite N vem da linha de comando, assim como uma lista opcional de contas a deixar de fora; a última execução desta aula a usa."}, {"code": "failures = Counter()\nfor row in csv.DictReader(open('logins.csv')):\n    if row['result'] == 'fail' and row['user'] not in ignored:\n        window = row['time'][:15]\n        failures[(row['source'], window)] += 1", "note": "Conta as falhas por endereço e por janela de dez minutos. Sucessos não contam, nem as contas deixadas de fora."}, {"code": "red = set(open('red-team-sources.txt').read().split())\ntp = fp = fn = tn = 0\nfor (source, window), count in failures.items():\n    alert = count >= threshold\n    attack = source in red\n    if alert and attack:\n        tp += 1\n    elif alert:\n        fp += 1\n    elif attack:\n        fn += 1\n    else:\n        tn += 1", "note": "A verdade são os dois endereços do exercício. Cada caso vai para uma das quatro caixas: a regra alertou, e era o exercício?"}, {"code": "print(f'threshold {threshold}: {tp + fp} alerts')\nprint(f'  TP {tp:3}   FP {fp:3}')\nprint(f'  FN {fn:3}   TN {tn:3}')\nprint(f'precision {tp / (tp + fp):.0%}   recall {tp / (tp + fn):.0%}')", "note": "Imprime a matriz e os dois números que a próxima seção explica."}]}
```

Os dez minutos vêm de cortar a hora nos primeiros quinze caracteres: `2026-09-29T14:03:12` vira
`2026-09-29T14:0`, que é igual para todo segundo de 14:00:00 a 14:09:59. Cada endereço em cada janela
de dez minutos com pelo menos uma falha é um **caso**, e todo caso cai em exatamente uma das quatro
caixas da seção anterior.
