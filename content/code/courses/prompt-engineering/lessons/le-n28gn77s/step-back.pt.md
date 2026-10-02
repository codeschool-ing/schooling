---
title: Pedindo o princípio, depois a resposta
version: 1
---

Quando um modelo erra uma pergunta, o instinto é acrescentar detalhe à pergunta: mais
especificidades, mais ênfase na parte difícil. O prompting de recuo (*step-back prompting*) vai
pelo outro lado. **Antes da pergunta específica, você faz uma mais geral: de que princípio, regra
ou categoria isto é um caso?** A resposta do modelo a essa pergunta entra no prompt, e a pergunta
específica é respondida com o princípio já escrito na frente dela.

## Uma pergunta cuja redação esconde a regra

A página de horários do manual do Café Aurora tem quatro linhas. A ana pôs a página num prompt com
uma pergunta vinda do balcão e salvou como `direct.txt`:

```
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
```

Todo fato necessário está no prompt. O curso escreveu esta resposta como ilustração do erro que um
modelo pode cometer com ele; não é uma captura:

```localised
Sim. Às quartas o café fica aberto até as 18:00, então a cozinha aceita
pedidos de comida quente até as 17:30.
```

A pergunta diz **quarta-feira** (*Wednesday*), a primeira linha do manual diz de segunda a sábado,
e as duas combinam fortemente. A regra que decide o caso está duas linhas abaixo e é alcançada por
uma palavra, *holiday*, que fica no meio da pergunta. A resposta segue a combinação mais óbvia e
para ali, que é o mesmo hábito de próximo token que a lição 1 mostrou: o que é provável dado o
texto, não o que decorre dele.

## O recuo

A primeira chamada pede só as regras gerais. O `step1.txt` é o mesmo bloco do manual, seguido de:

```
Do not answer any particular question yet. Step back: what general rules decide the last time the kitchen takes a hot food order on a given day? List the rules from the handbook that apply, and what they give for each kind of day.
```

Eis a ilustração do curso para uma resposta a ele:

```localised
1. O horário de fechamento depende do dia: 18:00 de segunda a sábado,
   12:00 no domingo.
2. Um feriado segue o horário de domingo, caia no dia da semana que cair.
3. A cozinha para de aceitar pedidos de comida quente 30 minutos antes
   de fechar.
Então o último pedido de comida quente é às 17:30 num dia comum de
segunda a sábado, e às 11:30 num domingo ou feriado.
```

Nada ali é novo: todas as regras já estavam no manual. **O que mudou foi a ordem em que os fatos
estão dispostos**, com a regra do feriado dita como regra, e não enterrada como exceção, e a conta
feita uma vez para cada tipo de dia.

A segunda chamada é a pergunta original com essas regras na frente. A ana colou a resposta entre
tags `<rules>` e salvou o `step2.txt`:

```
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

<rules>
1. The closing time depends on the day: 18:00 from Monday to Saturday, 12:00 on Sunday.
2. A public holiday follows the Sunday hours, whatever day of the week it falls on.
3. The kitchen stops taking hot food orders 30 minutes before closing.
So the last hot food order is at 17:30 on an ordinary day from Monday to Saturday, and at 11:30 on a Sunday or a public holiday.
</rules>

Using the rules above, answer the question. Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
```

E a ilustração do curso para a resposta que ele recebe:

```localised
Não. Um feriado segue o horário de domingo, então o café fecha às 12:00
e a cozinha parou de aceitar pedidos de comida quente às 11:30.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas linhas. Chamada 1: a pergunta de recuo, que regras decidem isso, entra no modelo, que devolve as regras gerais, entre elas a de que feriado segue o horário de domingo. Uma seta leva essas regras para a chamada 2: as regras mais a pergunta original sobre 11:45 numa quarta de feriado entram no modelo, que devolve a resposta: não, o último pedido é às 11:30.\"><defs><marker id=\"sb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chamada 1</text><text x=\"40\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chamada 2</text><rect x=\"80\" y=\"40\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a pergunta de recuo</text><text x=\"180\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que regras decidem isso?</text><path d=\"M280 70 L318 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"320\" y=\"45\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M420 70 L458 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"460\" y=\"40\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">as regras gerais</text><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">feriado segue o domingo</text><path d=\"M560 100 L560 135 L180 135 L180 168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><text x=\"370\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">coladas no segundo prompt</text><rect x=\"80\" y=\"170\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">as regras + a pergunta</text><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">11:45, quarta de feriado</text><path d=\"M280 200 L318 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"320\" y=\"175\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M420 200 L458 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"460\" y=\"170\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a resposta</text><text x=\"560\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não: último pedido 11:30</text></svg>", "caption": "O prompting de recuo como duas chamadas. A primeira pede o princípio por trás da pergunta; a resposta dela entra no segundo prompt, ao lado da pergunta original."}
```

O formato é sempre o mesmo: **a chamada um transforma a pergunta na sua forma geral e responde a
ela; a chamada dois responde à pergunta específica com a resposta geral no prompt.** A pergunta
geral é escrita por você, ou pelo próprio modelo, se você pedir antes que ele "diga a pergunta
mais geral por trás desta".

## O mesmo movimento fora do café

O prompting de recuo foi apresentado com perguntas de ciências, e lá o formato fica mais claro.
"O que acontece com a pressão de um gás se a temperatura dobra e o volume fica oito vezes maior?"
convida a um chute sobre dobrar. A pergunta de recuo é "que lei física relaciona pressão,
temperatura e volume?", e a resposta, a lei dos gases ideais, torna a pressão proporcional à
temperatura dividida pelo volume. Com isso no prompt, a pergunta específica é uma divisão:

```
ana@lab:~/pe$ python3 -c "print(2 / 8)"
0.25
```

A pressão cai para um quarto do que era. **O princípio transformou uma pergunta que parecia pedir
intuição numa que pedia uma fórmula**, e uma fórmula é algo que você pode conferir, como aqui, com
um programa de verdade, em vez de aceitar a palavra do modelo.
