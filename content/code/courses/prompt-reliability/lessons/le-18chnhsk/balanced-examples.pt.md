---
title: Equilibrando os exemplos
version: 1
---

A aula 1 disse que todo exemplo puxa as respostas para o próprio rótulo, diga o que disser. Aquela
seção prometeu uma medição, e é esta. **Os rótulos dos exemplos de um prompt são um voto dado antes
de a mensagem ser lida.**

```
ana@lab:~/triage$ grep -n "^EXAMPLE_PULL" promptlab/standin.py
86:EXAMPLE_PULL = 0.4      # what one example adds to its own label, whatever it says
ana@lab:~/triage$ grep -o '"category": "[a-z]*"' prompts/v18-skewed.txt
"category": "billing"
"category": "billing"
"category": "billing"
"category": "billing"
"category": "delivery"
ana@lab:~/triage$ grep -o '"category": "[a-z]*"' prompts/v18-balanced.txt
"category": "billing"
"category": "returns"
"category": "account"
"category": "other"
"category": "delivery"
```

O `v18-skewed` tem cinco exemplos: quatro de billing e um de delivery. É o que sai quando alguém
copia exemplos da fila em que estava trabalhando naquela tarde. O `v18-balanced` tem um exemplo de
cada categoria. No substituto, cada exemplo soma 0,4 ao próprio rótulo em toda mensagem, e mais
quando a mensagem tem palavras em comum com ele, então o prompt desequilibrado começa cada mensagem
com 1,6 para billing antes de ler uma palavra dela.

## Vinte e três respostas

```
ana@lab:~/triage$ pl run prompts/v18-skewed.txt cases/all.jsonl --out runs/skewed.jsonl
70 calls, prompt fa582afd, written to runs/skewed.jsonl
ana@lab:~/triage$ pl run prompts/v18-balanced.txt cases/all.jsonl --out runs/balanced.jsonl
70 calls, prompt f44acd73, written to runs/balanced.jsonl
ana@lab:~/triage$ pl compare runs/skewed.jsonl runs/balanced.jsonl --answers
70 cases, same answer 47, different answer 23
  t05  billing -> other
  t10  billing -> other
  t13  billing -> returns
  t21  billing -> returns
  t23  billing -> returns
  t29  billing -> account
  t33  billing -> returns
  t34  billing -> account
  t37  billing -> delivery
  h01  billing -> returns
  h06  billing -> delivery
  h07  billing -> account
  h09  billing -> account
  h10  billing -> account
  h13  billing -> other
  h15  billing -> delivery
  h16  billing -> delivery
  h18  billing -> returns
  h20  billing -> other
  h23  billing -> returns
  h26  billing -> delivery
  h28  billing -> delivery
  h30  billing -> other
```

Vinte e três das setenta respostas diferem, e **em todas elas o prompt desequilibrado disse
billing**. Nenhuma mudou no sentido contrário. É assim que um viés aparece numa comparação de
respostas: toda mudança aponta para o mesmo lado.

```
ana@lab:~/triage$ pl check runs/skewed.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     45    25
urgency      39    31
all          39    31
ana@lab:~/triage$ pl check runs/balanced.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     57    13
urgency      47    23
all          47    23
```

A verificação de categoria vai de 45 para 57. Os dois prompts têm as setenta respostas analisáveis,
então toda essa diferença está nos rótulos.

Cuidado com o que isso prova. Os dois prompts diferem em mais do que a contagem de cada rótulo:
as mensagens também são outras, e um exemplo também puxa por semelhança. A comparação mede um
conjunto de exemplos contra outro, que é a decisão que você de fato enfrenta. Para medir só a
contagem, você manteria as mensagens e mudaria só os rótulos, e isso seria um teste
contrafactual, o assunto da próxima seção.

## Modelos reais

A atração do substituto é uma constante. Para modelos reais, o mesmo artigo de Zhao e outros da
primeira seção, *Calibrate Before Use* (2021), deu a isso o nome de **viés do rótulo majoritário**:
o GPT-3 favorecia o rótulo que aparecia mais vezes entre os exemplos do prompt. O remédio do artigo,
que os autores chamaram de calibração contextual, era perguntar ao modelo sobre uma entrada sem
conteúdo, como `N/A`, ver quanto a resposta pendia para cada rótulo e corrigir essa inclinação. Vale
saber que a ideia existe. A versão do dia a dia é mais simples: **conte os rótulos dos seus
exemplos** antes de contar qualquer outra coisa, com o mesmo `grep` de cima.

## Equilibrado também é uma escolha

Um exemplo por rótulo também não é neutro. Ele diz ao modelo que todas as categorias são igualmente
prováveis, o que é falso na maioria das caixas de entrada. Se a mistura real é metade delivery, um
conjunto que a reproduz pende para delivery de propósito. Os dois podem estar certos. Errada é uma
mistura que ninguém escolheu, porque aí o viés do prompt é o que a última pessoa que o editou
calhou de colar.
