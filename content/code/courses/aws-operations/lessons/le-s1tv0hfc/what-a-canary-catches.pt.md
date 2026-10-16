---
title: O que um canário pega, e quando não pega nada
version: 1
---

A promessa do canário é aritmética: se um release é ruim, só um décimo dos usuários o encontra, e só
por cinco minutos. **Essa promessa só vale se alguma coisa perceber**, e o que percebe é um alarme.
Onde o alarme olha decide se o canário protege alguém, e o jeito mais claro de ver isso é contar. O
moto não roda deploy nenhum, então esta seção conta com um modelo: um programa curto que passa um
release ruim por cada estratégia, minuto a minuto.

```schooling-example
{"language": "python", "file": "canary.py", "parts": [{"code": "\"\"\"canary.py: how many requests a bad release fails under each strategy.\n\nA model, not CodeDeploy. Each minute the new version takes a share of the\ntraffic; a share of its requests fail; an alarm watches an error rate and\nfires after two minutes in a row above the threshold; the minute after it\nfires, all traffic is back on the old version.\n\"\"\"\n", "note": "**Um modelo, e a docstring diz isso primeiro.** Ele tem quatro suposições, todas declaradas, e nenhuma é o jeito como o CodeDeploy mede alguma coisa."}, {"code": "RPM = 1000          # requests a minute\nBAD = 0.20          # share of the new version's requests that fail\nTHRESHOLD = 0.02    # the alarm fires above a 2% error rate\nMINUTES = 15\n\n", "note": "Os números para mudar: mil requisições por minuto, um release que falha uma requisição em cinco, e um alarme que dispara acima de 2%."}, {"code": "STRATEGIES = {\n    'all at once': lambda m: 1.0,\n    'canary 10%, 5 min': lambda m: 0.1 if m < 5 else 1.0,\n    'linear 10%/min': lambda m: min(1.0, 0.1 * (m + 1)),\n}\n\n\n", "note": "Cada estratégia é uma função do minuto para a fatia da versão nova. O canário fica com 10% por cinco minutos e depois leva tudo; o linear soma 10% por minuto."}, {"code": "def run(share, scope):\n    failed, above = 0, 0\n    for m in range(MINUTES):\n        s = share(m)\n        errors = RPM * s * BAD\n        failed += errors\n        seen = RPM * s if scope == 'new version' else RPM\n        above = above + 1 if errors / seen > THRESHOLD else 0\n        if above == 2:\n            return round(failed), m + 1\n    return round(failed), None\n\n\n", "note": "Minuto a minuto: a fatia do tráfego que vai para a versão nova falha na taxa ruim. O alarme vê os erros divididos por **todas as requisições ou só pelas da versão nova**, e essa única escolha é o assunto da saída. Dois minutos acima da linha e ele dispara; o minuto seguinte já está de volta na versão antiga."}, {"code": "print(f'{\"strategy\":<20}{\"alarm watches\":<16}{\"failed\":>8}  rolled back')\nfor name, share in STRATEGIES.items():\n    for scope in ('whole service', 'new version'):\n        failed, when = run(share, scope)\n        after = f'after minute {when}' if when else 'never'\n        print(f'{name:<20}{scope:<16}{failed:>8}  {after}')\n", "note": "Cada estratégia duas vezes, uma por escopo do alarme."}]}
```

Grave-o como `canary.py` e rode:

```
ana@laptop:~/aws/deploy$ python3 canary.py
strategy            alarm watches     failed  rolled back
all at once         whole service        400  after minute 2
all at once         new version          400  after minute 2
canary 10%, 5 min   whole service        500  after minute 7
canary 10%, 5 min   new version           40  after minute 2
linear 10%/min      whole service        120  after minute 3
linear 10%/min      new version           60  after minute 2
```

Leia primeiro a terceira linha. **Um canário vigiado por um alarme no serviço inteiro falhou 500
requisições, mais do que liberar tudo de uma vez.** Com 10% do tráfego, um release que falha 20% das
requisições leva a taxa de erro do serviço a exatamente 2%, que não está acima do limite. O alarme fica quieto nos cinco minutos do canário, o deploy passa tudo, e aí leva mais dois minutos
para disparar. O canário diluiu o próprio sinal por dez e o alarme não conseguiu vê-lo.

A quarta linha é o mesmo canário com o alarme **só na versão nova**: 40 requisições falhadas,
revertido depois do segundo minuto. Mesmo release, mesmo limite, um doze avos do estrago. Esse é o
argumento inteiro para os nomes de alarme no deployment group desta lição, `api-green-5xx` e
`api-green-p99`: no ECS, o conjunto verde fica atrás do próprio target group, e o balanceador informa
`HTTPCode_Target_5XX_Count` por target group, então o alarme pode vigiar só a versão nova.

## O que o modelo deixa de fora

Vale ser exato sobre as simplificações, porque cada uma mexe num número:

- **o tráfego real não é plano**, e um canário às 3 da manhã vê uma fração das requisições que veria
  ao meio-dia, então os mesmos cinco minutos carregam menos evidência;
- **erro não é o único sintoma**: um release que fica lento em vez de falhar precisa de um alarme de
  latência, e por isso o grupo nomeia dois;
- **um minuto é um relógio grosso**: o CloudWatch consegue avaliar um alarme a cada dez segundos em
  métricas de alta resolução, e a lição 10 é sobre quantos períodos um alarme deve esperar;
- **um rollback não é instantâneo**, embora no blue/green seja rápido, porque as tarefas antigas ainda
  estão rodando e só o listener muda.

Troque `BAD` por `0.05` e rode de novo. Com 5% de falhas, um canário de 10% leva a taxa do serviço a
0,5%, e um alarme no serviço inteiro fica quieto durante o canário inteiro: ele só consegue disparar
quando mais de 40% do tráfego estiver na versão nova. **Falhas pequenas são as que mais precisam do
alarme estreito.**
