---
title: Medindo quais linhas rodaram
version: 1
---

**O Python vem com um módulo chamado `trace` que observa um programa rodando e conta quantas vezes cada
linha executou.** Essa contagem é a cobertura de comandos, e não exige nada instalado. Para usá-lo, os
testes também precisam ser um programa: eis os seis casos da aula 6, os da tabela da regra, escritos de um
jeito que o `trace` consiga observar. Salve em `~/aurora` como `cases.py`.

```schooling-example
{"language": "python", "file": "cases.py", "parts": [{"code": "# cases.py\nfrom tickets import price\n", "note": "Chama o `price` do `tickets.py` diretamente, sem a linha de comando, para o módulo trace poder observar quais linhas do `price` rodam."}, {"code": "\nCASES = [\n    (35, False, \"thu\", \"16:59\", 2800),\n    (35, False, \"thu\", \"17:00\", 3600),\n    (20, True, \"thu\", \"20:00\", 1800),\n    (11, False, \"thu\", \"20:00\", 1800),\n    (12, False, \"thu\", \"20:00\", 3600),\n    (35, False, \"wed\", \"20:00\", 1800),\n]\n", "note": "Os seis casos da tabela da aula 6, cada um com o preço que deveria dar, em centavos."}, {"code": "\nfor age, student, day, time, expected in CASES:\n    got = price(age, student, day, time)\n    print(\"ok  \" if got == expected else \"FAIL\", age, student, day, time, got)\n", "note": "Roda cada caso e imprime `ok` ou `FAIL` ao lado. Um programa que confere as respostas de outro contra respostas esperadas é um teste, e a aula 15 dá a esse tipo uma casa de verdade."}]}
```

## Rodando sob o trace

`-m trace` roda o `cases.py` sob o módulo trace. `--count` conta as linhas, `--missing` marca as que nunca
rodaram, `--summary` imprime uma porcentagem por arquivo, e `-C .` grava as cópias anotadas no diretório
atual.

```
lia@lab:~/aurora$ python -m trace --count --missing --summary -C . cases.py
ok   35 False thu 16:59 2800
ok   35 False thu 17:00 3600
ok   20 True thu 20:00 1800
ok   11 False thu 20:00 1800
ok   12 False thu 20:00 3600
ok   35 False wed 20:00 1800
lines   cov%   module   (path)
    5   100%   cases   (cases.py)
   24    83%   home.lia.aurora.tickets   (/home/lia/aurora/tickets.py)
```

Seis `ok`: os seis casos passam, como na aula 6. Abaixo deles, o resumo: toda linha do `cases.py` rodou, e
83% das linhas do `tickets.py` rodaram. Os outros 17% são o assunto desta aula.

## Lendo a cópia anotada

O `trace` gravou uma cópia do `tickets.py` com uma contagem na frente de cada linha que roda. Ele dá à cópia
o nome do caminho completo do arquivo, então na máquina da gravação ela se chama
`home.lia.aurora.tickets.cover`; na sua, a parte do meio é o seu nome de usuário, e `*tickets.cover` a acha
seja qual for o nome.

```
lia@lab:~/aurora$ ls *.cover
cases.cover
home.lia.aurora.tickets.cover
lia@lab:~/aurora$ cat *tickets.cover
       # tickets.py
    1: import sys
       
    1: EVENING = 3600
    1: MATINEE = 2800
       
       
    1: def price(age, student, day, time):
    6:     if time < "17:00":
    1:         full = MATINEE
           else:
    5:         full = EVENING
    6:     half = False
    6:     if student:
    1:         half = True
    6:     if age > 60:
>>>>>>         half = True
    6:     if age < 12:
    1:         half = True
    6:     if day == "wed":
    1:         full = full // 2
    6:     if half:
    2:         return full // 2
    4:     return full
       
       
    1: def brl(cents):
>>>>>>     return f"R$ {cents // 100},{cents % 100:02d}"
       
       
    1: if __name__ == "__main__":
>>>>>>     age, student, day, time = sys.argv[1:]
>>>>>>     print(brl(price(int(age), student == "yes", day, time)))
```

O número antes de cada linha é quantas vezes ela rodou; uma linha marcada com `>>>>>>` nunca rodou. Três
grupos de linhas nunca rodaram, e cada um quer dizer uma coisa:

- **o `brl` e as duas últimas linhas**: a parte da linha de comando. O `cases.py` chama o `price`
  diretamente, então isso era esperado, e a aula 6 já rodou essas linhas de fora. Um relatório de
  cobertura sempre precisa dessa leitura: nem toda linha não rodada é uma lacuna;
- **o `half = True` depois de `if age > 60`**: nenhum caso tinha mais de sessenta, então a linha que dá o
  desconto às pessoas idosas **nunca foi rodada por estes testes**. Faça ela o que fizer, certo ou errado,
  nada conferiu;
- mais nada no `price`. Todas as outras linhas rodaram pelo menos uma vez.

Esse segundo achado é para o que o relatório serve. A tabela da aula 6 foi montada a partir da regra, e a
regra tem três descontos; a tabela testou dois. Ninguém percebeu a lacuna lendo a tabela. O relatório de
cobertura percebeu numa linha.

## Fechando a lacuna, e o que isso prova

A resposta óbvia é acrescentar um caso que rode a linha: um cliente com mais de sessenta. Eis o `cases.py`
de novo com um sétimo caso, um adulto de sessenta e um anos numa sessão da noite:

```python
# cases.py
from tickets import price

CASES = [
    (35, False, "thu", "16:59", 2800),
    (35, False, "thu", "17:00", 3600),
    (20, True, "thu", "20:00", 1800),
    (11, False, "thu", "20:00", 1800),
    (12, False, "thu", "20:00", 3600),
    (35, False, "wed", "20:00", 1800),
    (61, False, "thu", "20:00", 1800),
]

for age, student, day, time, expected in CASES:
    got = price(age, student, day, time)
    print("ok  " if got == expected else "FAIL", age, student, day, time, got)
```

```
lia@lab:~/aurora$ python -m trace --count --missing --summary -C . cases.py
ok   35 False thu 16:59 2800
ok   35 False thu 17:00 3600
ok   20 True thu 20:00 1800
ok   11 False thu 20:00 1800
ok   12 False thu 20:00 3600
ok   35 False wed 20:00 1800
ok   61 False thu 20:00 1800
lines   cov%   module   (path)
    5   100%   cases   (cases.py)
   24    87%   home.lia.aurora.tickets   (/home/lia/aurora/tickets.py)
lia@lab:~/aurora$ grep -A1 "age > 60" *tickets.cover
    7:     if age > 60:
    1:         half = True
```

Sete `ok`, a cobertura do arquivo sobe de 83% para 87%, e a linha agora rodou uma vez. Toda linha do
`price` rodou. Pela cobertura de comandos, o `price` está completamente testado.

**E o defeito dos sessenta anos continua lá.** Sessenta e um é mais de sessenta em qualquer leitura da
regra, então a linha rodou e deu a resposta certa; o caso que teria falhado é sessenta, e ninguém o
escolheu. A cobertura de comandos perguntou se a linha rodou. Nunca perguntou se a linha estava certa, e
não consegue, porque isso exige um resultado esperado, que só a regra pode dar.

Essa é a coisa mais importante a saber sobre cobertura, e é por isso que a aula 22 põe a porcentagem de
cobertura entre os números que viram teatro quando alguém é julgado por eles.
