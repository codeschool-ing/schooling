---
title: O que faz disso engenharia
version: 1
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
contexto. O modelo não conhece nada dele. Dois prompts para o mesmo trabalho, escritos pelo curso
como ilustração:

```localised
Vago:
  Escreva alguma coisa sobre o nosso horário de funcionamento.

Específico:
  Você está escrevendo o aviso para a porta do Café Aurora.
  Horário: de segunda a sábado, das 07:00 às 18:00; domingo, das 08:00 às 12:00.
  A cozinha para de aceitar pedidos de comida quente 30 minutos antes de fechar.
  Escreva o aviso em português, em no máximo quatro linhas, uma linha por regra.
  Não acrescente nenhuma informação que não esteja neste horário.
```

O vago pode ser respondido de mil maneiras e todas passam, porque nada diz o que é uma boa resposta.
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
