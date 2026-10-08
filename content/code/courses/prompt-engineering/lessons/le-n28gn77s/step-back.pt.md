---
title: Pedindo o princípio, depois a resposta
version: 2
---

Quando um modelo erra uma pergunta, o instinto é acrescentar detalhe à pergunta: mais
especificidades, mais ênfase na parte difícil. O prompting de recuo (*step-back prompting*) vai
pelo outro lado. **Antes da pergunta específica, você faz uma mais geral: de que princípio, regra
ou categoria isto é um caso?** A resposta do modelo a essa pergunta entra no prompt, e a pergunta
específica é respondida com o princípio já escrito na frente dela.

## Uma pergunta cuja redação esconde a regra

A página de horários do manual do Café Aurora tem quatro linhas. A ana pôs a página num prompt com
uma pergunta do balcão, e o salvou como `direct.txt`:

```
ana@lab:~/pe$ cat direct.txt
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
ana@lab:~/pe$ ask - --temperature 0 < direct.txt
No, the kitchen cannot take the order because it stops taking hot food orders 30 minutes before closing, and it closes at 12:00 on public holidays.
-- llama3.2:3b, finish: stop, prompt 142 tokens, output 34 tokens
```

Todo fato necessário está no prompt, e o modelo acertou: a regra do feriado, o fechamento às 12:00,
os 30 minutos. A pergunta ainda tem a forma para a qual o prompting de recuo existe. Ela diz
**quarta-feira**, a primeira linha do manual diz de segunda a sábado, e as duas casam com força; a
regra que decide o caso está duas linhas abaixo, alcançada por uma palavra, *feriado*, no meio da
pergunta. Um modelo que seguisse o casamento mais óbvio responderia sim, pelo horário de dia de
semana, que é o hábito da lição 1 de prever a próxima palavra: o que é provável dado o texto, não o
que decorre dele. Este não fez isso, nesta execução. A técnica é para as execuções e os modelos que
fazem.

## O recuo

A primeira chamada pede só as regras gerais. O `step1.txt` é o mesmo bloco do manual, seguido da
linha impressa aqui:

```
ana@lab:~/pe$ tail -1 step1.txt
Do not answer any particular question yet. Step back: what general rules decide the last time the kitchen takes a hot food order on a given day? List the rules from the handbook that apply, and what they give for each kind of day.
ana@lab:~/pe$ ask - --temperature 0 --plain < step1.txt > rules.txt; cat rules.txt
Based on the handbook, the general rules that decide the last time the kitchen takes a hot food order on a given day are:

1. The kitchen stops taking hot food orders 30 minutes before closing.
2. On public holidays, the café follows the Sunday hours.

These rules imply that:

* On weekdays (Monday to Saturday), the kitchen will stop taking hot food orders 30 minutes before the closing time, which is 17:30 (18:00 - 30 minutes).
* On Sundays, the kitchen will stop taking hot food orders 30 minutes before the closing time, which is 11:30 (12:00 - 30 minutes).
* On public holidays, the café follows the Sunday hours, so the kitchen will stop taking hot food orders 30 minutes before the Sunday closing time, which is 11:30.
```

Nada nela é novo: toda regra já estava no manual. **O que mudou foi a ordem em que os fatos estão
dispostos**, com a regra do feriado dita como regra e não enterrada como exceção, e a conta feita
uma vez para cada tipo de dia: 17:30, 11:30, 11:30.

A segunda chamada é a pergunta original com essas regras na frente. Um comando a monta a partir do
bloco do manual, da resposta e da pergunta, e a manda:

```
ana@lab:~/pe$ { sed -n "1,/^<\/handbook>/p" direct.txt; echo; echo "<rules>"; cat rules.txt; echo "</rules>"; echo; echo "Using the rules above, answer the question. $(tail -1 direct.txt)"; } > step2.txt
ana@lab:~/pe$ ask - --temperature 0 < step2.txt
No, the kitchen cannot take the order at 11:45 because it stops taking hot food orders 30 minutes before closing, which would be 11:15 on a public holiday.
-- llama3.2:3b, finish: stop, prompt 327 tokens, output 39 tokens
```

A resposta continua sendo não, e **o motivo agora tem um horário errado**: 11:15, onde as regras no
mesmo prompt dizem 11:30, duas vezes. O recuo produziu regras certas; a segunda chamada refez a
subtração e errou. Nada na técnica impede isso, e a próxima seção de leitura volta a esse ponto.

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
convida a um chute. A pergunta de recuo é "que lei física relaciona pressão, temperatura e
volume?", e a resposta dela vai para o prompt antes da pergunta:

```
ana@lab:~/pe$ ask "What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0
If the temperature of a gas is doubled and its volume is made eight times larger, the pressure of the gas will decrease by a factor of 16, since the ideal gas law (PV = nRT) shows that pressure is directly proportional to temperature and inversely proportional to volume.
-- llama3.2:3b, finish: stop, prompt 51 tokens, output 58 tokens
ana@lab:~/pe$ ask "Which physical law relates the pressure, temperature and volume of a gas? State it as a formula, in one line." --temperature 0 --plain > law.txt; cat law.txt
The ideal gas law is: PV = nRT, where P is pressure, V is volume, n is the number of moles, R is the gas constant, and T is temperature.
ana@lab:~/pe$ ask "$(cat law.txt)

Using that law: What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0
If the temperature of a gas is doubled and its volume is made eight times larger, the pressure of the gas will decrease by a factor of 16, since the pressure is directly proportional to the temperature and inversely proportional to the volume, according to the ideal gas law PV = nRT.
-- llama3.2:3b, finish: stop, prompt 94 tokens, output 60 tokens
ana@lab:~/pe$ python3 -c "print(2 / 8)"
0.25
```

O modelo respondeu certo à pergunta de recuo: a lei dos gases ideais. Com a lei na frente dele, a
resposta específica foi **a mesma resposta errada de sem ela**, um fator de 16. A pressão é
proporcional à temperatura dividida pelo volume, então dobrar uma e multiplicar o outro por oito dá
2 / 8, um quarto: a última linha, de um programa de verdade. **O princípio transformou uma pergunta
que parecia pedir intuição numa que pedia uma fórmula**, e foi a fórmula que tornou a resposta
errada conferível, pelo Python e não pela palavra do modelo.
