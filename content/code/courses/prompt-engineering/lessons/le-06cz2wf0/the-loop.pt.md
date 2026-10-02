---
title: Por que a decodificação gulosa anda em círculos
version: 1
---

A repetição parece um defeito do modelo, um bug que alguém deveria consertar. Está mais perto do
contrário. **Um modelo que sempre escolhe a próxima palavra mais provável vai se repetir sempre que
as palavras mais prováveis levarem de volta ao ponto de partida**, e nada nas notas sabe que o texto
já passou por ali.

A lição 15 usou esta execução para mostrar para que serve um limite de tokens:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

Agora veja por quê. Cada passo olha só as duas últimas palavras, e isto é o que cada par oferece:

```
ana@lab:~/pe$ toylm next "the cat"
context: trigram after 'the cat'
  sleeps    66.7%  ###########################
  wakes     20.0%  ########
  sat       13.3%  #####
ana@lab:~/pe$ toylm next "cat sleeps"
context: trigram after 'cat sleeps'
  and       60.0%  ########################
  on        40.0%  ################
ana@lab:~/pe$ toylm next "sleeps and"
context: trigram after 'sleeps and'
  the      100.0%  ########################################
ana@lab:~/pe$ toylm next "and the"
context: trigram after 'and the'
  cat       35.3%  ##############
  coffee    23.5%  #########
  bread     17.6%  #######
  café      11.8%  #####
  terrace   11.8%  #####
```

Siga a primeira linha de cada tabela: depois de `the cat`, `sleeps`; depois de `cat sleeps`, `and`;
depois de `sleeps and`, `the`; depois de `and the`, `cat`. **Os quatro passos mais prováveis formam
um círculo**, e na temperatura 0 o laço dá sempre o passo mais provável, então gira até o limite o
parar. Cada escolha é razoável sozinha. `and` ganha de `on` por 60% a 40%, e `cat` lidera depois de
`and the`. A frase só é absurda como um todo.

## A mesma coisa num modelo grande

Um modelo grande olha muito além de duas palavras, e os círculos dele são maiores: a mesma frase
repetida, uma lista que continua acrescentando o mesmo item, um parágrafo que reafirma o anterior. A
causa é a mesma. Um texto que acabou de aparecer torna provável um texto parecido, e **um modelo dá
nota ao próximo token sem nenhuma regra contra dizer a mesma coisa de novo**.

Amostrar numa temperatura acima de 0 quebra muitos círculos por acaso, já que um sorteio às vezes
pega a segunda escolha. É por isso que a repetição aparece mais em temperaturas baixas, exatamente
onde você as põe em busca de confiabilidade (lição 13). Os dois controles da próxima seção quebram o
círculo de propósito em vez de por sorte: eles baixam a nota das palavras que a saída já usou.
