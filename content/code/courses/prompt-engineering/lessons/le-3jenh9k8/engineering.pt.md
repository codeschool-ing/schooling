---
title: O que faz disso engenharia
version: 2
---

"Engenharia de prompt" costuma ser entendida como uma coleção de frases mágicas: a redação que
destrava uma resposta melhor, passada de pessoa para pessoa. Algumas redações funcionam mesmo melhor
que outras, e uma lista delas não é engenharia. **Engenharia é um objetivo declarado, um teste que diz
se o objetivo foi atingido, e mudanças medidas contra esse teste.** A redação é o que você muda; o
teste é o que diz se a mudança ajudou.

Cinco hábitos fazem a diferença, e todas as lições seguintes deste curso se apoiam neles:

| hábito | o que ele significa para um prompt |
|---|---|
| um objetivo declarado | uma frase dizendo o que é uma boa resposta, escrita antes do prompt |
| casos de teste | entradas que você envia toda vez, cada uma com o que uma resposta aceitável precisa conter |
| iteração | uma mudança por vez, cada uma rodada contra os mesmos testes |
| versionamento | cada versão guardada e nomeada, para que uma regressão possa ser ligada à mudança que a causou |
| medição | uma contagem de acertos ao longo de muitas execuções, não a sua impressão de uma resposta |

## Três versões de um prompt, medidas

Aqui está o ciclo inteiro no `toylm`, pequeno o bastante para acompanhar. O objetivo: **um cliente
pergunta quando o café abre, e a resposta tem de ser o horário dos dias de semana, `seven`.** As
três versões ficam em arquivos, um por versão:

```
ana@lab:~/pe$ cat prompts/v1.txt prompts/v2.txt prompts/v3.txt
question : when does the café open ? answer :
question : when does the café open ? answer : at
the café opens at
```

A `v1` é a pergunta como um cliente a faria, e a seção anterior mostrou o que ela recebe: `yes.` A
`v2` acrescenta a primeira palavra da resposta, `at` ("às"), para que a única continuação provável
seja um horário. Quatro sorteios a partir dela parecem promissores:

```
ana@lab:~/pe$ toylm generate "$(cat prompts/v2.txt)" --samples 4
[seed 1] seven. question: is the coffee is hot.
[seed 2] six.
[seed 3] seven.
[seed 4] seven.
```

Três em quatro, e um `six`, que é o horário de fechar. Quatro respostas são uma impressão, não uma
medição. O teste roda cada versão vinte vezes e conta as respostas que contêm `seven`:

```
ana@lab:~/pe$ for v in v1 v2 v3; do echo "$v $(toylm generate "$(cat prompts/$v.txt)" --samples 20 | grep -c seven)/20"; done
v1 1/20
v2 12/20
v3 16/20
```

**Os números resolvem o que ler algumas respostas não resolvia.** A `v2` é uma melhora de verdade em
relação à `v1` e ainda erra oito vezes em vinte, porque depois de `: at` o modelo não consegue ver se
a pergunta era sobre abrir ou fechar. A `v3` põe a palavra `opens` exatamente onde o modelo olha, e
passa dezesseis vezes em vinte. Sem os arquivos, a forma corrigida da `v2` se perderia no momento em
que alguém a "melhorasse", e sem a contagem a `v2` teria parecido pronta depois de quatro sorteios.

Um modelo grande não é testado com `grep` procurando uma palavra, e o teste é mais difícil de
escrever. O ciclo é o mesmo.

::: track ai prompt
A lição 19 confere a estrutura de uma resposta com um schema, e o curso `prompt-reliability`, o
próximo da sua trilha, constrói direito a avaliação de prompts.
:::

::: track *
A lição 19 confere a estrutura de uma resposta com um schema, e a lição 31 pontua modelos de prompt
inteiros contra um conjunto de testes rotulados.
:::

## Um prompt vago e um específico

O primeiro rascunho de um prompt costuma ser o pedido como você o diria a um colega que já conhece o
contexto. O modelo não conhece nada dele. Dois prompts para o mesmo trabalho:

```
ana@lab:~/pe$ cat prompts/vague.txt
Write something about our opening hours.
ana@lab:~/pe$ ask - --temperature 0 < prompts/vague.txt
**Our Opening Hours**

We are committed to providing our customers with convenient and accessible shopping experiences. Our opening hours are as follows:

Monday to Saturday: 9:00 AM - 6:00 PM
Sunday: 10:00 AM - 5:00 PM

Please note that these hours may be subject to change, especially on public holidays or during special events. We recommend checking our website or social media channels for any updates before visiting us.

We are also open on the following public holidays:

* New Year's Day: 12:00 PM - 5:00 PM
* Good Friday: 9:00 AM - 5:00 PM
* Easter Monday: 10:00 AM - 5:00 PM
* Christmas Day: 12:00 PM - 4:00 PM
* Boxing Day: 10:00 AM - 5:00 PM

We look forward to welcoming you to our store during our opening hours. If you have any questions or concerns, please don't hesitate to contact us.
-- llama3.2:3b, finish: stop, prompt 32 tokens, output 215 tokens
```

```
ana@lab:~/pe$ cat prompts/specific.txt
You are writing the notice for the door of Café Aurora.
Opening hours: Monday to Saturday 07:00 to 18:00; Sunday 08:00 to 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
Write the notice in English, at most four lines, one line per rule.
Do not add any information that is not in these hours.
ana@lab:~/pe$ ask - --temperature 0 < prompts/specific.txt
Here is the notice:

Café Aurora is open from Monday to Saturday from 07:00 to 18:00 and on Sunday from 08:00 to 12:00.

Please note that our kitchen stops taking hot food orders 30 minutes before closing.
-- llama3.2:3b, finish: stop, prompt 105 tokens, output 56 tokens
```

**O vago recebeu uma página confiante de horários, e nenhum deles é o do café.** Nada no prompt dizia
qual era o horário, então o modelo escreveu horários típicos, com domingo e feriados, e um aviso de
loja, não de café. Nada no prompt dizia o que é uma boa resposta, tampouco, então nada nela está
errado pelo próprio critério. O específico acertou o horário e a regra da cozinha, e ainda assim
deixou de cumprir duas instruções: começou com `Here is the notice:` e pôs duas regras numa linha só.
Um prompt mais longo resolveu o que ele dizia, e é o teste que acha o que ele não resolveu.

**O específico é mais longo porque carrega as quatro partes que um prompt pode ter**, e cada uma
fecha um caminho pelo qual a resposta poderia dar errado:

| parte | no exemplo | o que dá errado sem ela |
|---|---|---|
| instrução | escrever o aviso para a porta | o modelo adivinha a tarefa: um anúncio, um post, uma redação |
| contexto | o Café Aurora, a regra da cozinha | o modelo preenche a lacuna com o que é típico, que pode ser falso (lição 5) |
| dados de entrada | o próprio horário | não há nada em que acertar |
| formato de saída | português, quatro linhas, uma por regra | uma resposta correta que não pode ser usada onde vai ficar |

Nem todo prompt precisa das quatro, e mais longo não é melhor por si só: cada palavra é algo a partir
do qual o modelo continua. A pergunta a fazer a cada linha é a que o teste responde. **A resposta
melhora quando ela está lá, e piora quando não está?**
