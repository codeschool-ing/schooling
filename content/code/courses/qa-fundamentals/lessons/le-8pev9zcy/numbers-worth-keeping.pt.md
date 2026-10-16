---
title: Alguns números que valem a pena guardar
version: 1
---

**Um punhado de medidas se sustenta melhor que o resto, porque olha para o que chega aos clientes e é difícil de
melhorar sem melhorar o produto.** Nenhuma está a salvo da lei de Goodhart; todas estão mais a salvo que contar
atividade.

## Defeitos que escaparam, e o percentual de detecção

Um **defeito que escapou** é um achado depois da entrega, por um cliente ou pela equipe usando o produto de verdade. A
contagem de defeitos que escaparam, por área e por severidade, responde a pergunta que toda pessoa que testa está de
fato fazendo: *o que estamos deixando passar?*

O **percentual de detecção de defeitos** põe isso em proporção: de todos os defeitos conhecidos, a parte achada antes
da entrega.

> **percentual de detecção = defeitos achados antes da entrega ÷ todos os defeitos achados**

Ele não pode ser lido no dia da entrega, só semanas depois, quando os clientes tiveram tempo de achar o que o teste
deixou passar. Essa demora também o torna difícil de manipular: um defeito que um cliente relata não pode ser fechado
como "não vamos corrigir" na quinta à noite.

## Os registros do Cine Aurora, no laboratório

A Lia guarda os registros de defeito do time num arquivo simples, uma linha por defeito: a área, se foi achado
**antes** (*before*) ou **depois** (*after*) da entrega, a severidade, e os dias que levou para corrigir, ou `open`
(aberto). Salve isto em `~/aurora` como `defects.csv`:

```
# defects.csv
id,area,found,severity,days_to_fix
1,prices,before,high,1
2,prices,after,high,open
3,prices,before,high,1
4,prices,before,medium,2
5,orders,before,high,1
6,coupons,after,medium,1
7,refunds,before,critical,0
8,seat map,after,medium,3
9,report,before,low,1
```

Estes são os defeitos que este curso encontrou: a linha da idade, a sessão das 9:30, o empilhamento da quarta, as
entradas que ninguém mencionou, os pedidos recusados, os códigos de cupom colados, a queda do reembolso, e mais dois da
entrega de sexta. Um deles é o defeito 8: o mapa de assentos em celulares, que o resumo da aula 20 listou como *não
testado*, mostrava um assento ocupado como livre, e um cliente achou no primeiro fim de semana.

Um programa curto transforma o arquivo nos três números da primeira seção:

```schooling-example
{"language": "python", "file": "metrics.py", "parts": [{"code": "# metrics.py\nimport csv\n\nwith open(\"defects.csv\") as f:\n    rows = list(csv.DictReader(line for line in f if not line.startswith(\"#\")))\n", "note": "O módulo `csv` do Python lê o arquivo num dicionário por linha, com as chaves do cabeçalho. A linha que começa com `#` é pulada, porque nomeia o arquivo e não é um registro."}, {"code": "\nbefore = [r for r in rows if r[\"found\"] == \"before\"]\nafter = [r for r in rows if r[\"found\"] == \"after\"]\n", "note": "Os defeitos divididos em dois por uma pergunta: achados antes da entrega, ou depois."}, {"code": "print(\"defects:\", len(rows))\nprint(\"found before release:\", len(before))\nprint(\"found after release:\", len(after))\nprint(f\"detection percentage: {len(before) / len(rows):.0%}\")\n", "note": "As contagens, e o percentual de detecção: achados antes, dividido por todos. `:.0%` imprime uma fração como porcentagem inteira."}, {"code": "print(\"escaped, by area:\", \", \".join(r[\"area\"] for r in after))\nprint(\"still open:\", \", \".join(\"defect \" + r[\"id\"] for r in rows if r[\"days_to_fix\"] == \"open\"))\n", "note": "E as duas listas sem as quais um número nunca deveria ser mostrado: onde estavam os defeitos que escaparam, e quais continuam abertos."}]}
```

```
lia@lab:~/aurora$ python metrics.py
defects: 9
found before release: 6
found after release: 3
detection percentage: 67%
escaped, by area: prices, coupons, seat map
still open: defect 2
```

Nove defeitos, seis achados primeiro, um percentual de detecção de 67%, e o defeito 2, a sessão das 9:30, ainda
aberto com seu contorno. Os três que escaparam valem uma frase cada. A sessão das 9:30 escapou porque ninguém tinha
perguntado como os horários eram digitados. Os espaços do cupom escaparam porque ninguém tinha visto a Célia colar. O
mapa de assentos em celulares escapou porque estava na lista do que não foi testado, escrita e aceita: uma lacuna
*conhecida* e *escolhida*, que é o tipo honesto de escape.

## Números de fluxo, lidos com cuidado

O lead time, o tempo de ciclo e a eficiência de fluxo da aula 13 são úteis do mesmo jeito: descrevem o que o cliente
vive, esperando. Os cuidados daquela aula continuam valendo. Um lead time que cai porque os cartões pulam o teste é o
teatro da seção anterior.

## Como o Cine Aurora os usa

Uma vez por mês, na revisão das medidas de fluxo, a Lia leva três números e nenhum a mais: defeitos que escaparam
desde a última revisão, o percentual de detecção dos últimos três meses, e os dias para corrigir qualquer defeito de
preço. Cada um aparece com os defeitos por trás dele, nunca sozinho. Ninguém é classificado por eles. Todo mês o time
faz a mesma pergunta a cada número, **o que isto muda no que fazemos em seguida?**, e quando a resposta é *nada* duas
vezes seguidas, o número sai.
