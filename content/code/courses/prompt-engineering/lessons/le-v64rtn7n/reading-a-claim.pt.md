---
title: Lendo uma afirmação sobre um modelo
version: 1
---

Um anúncio diz que um modelo tira nota quase perfeita num teste conhecido, e um vídeo mostra o
modelo resolvendo um problema difícil de primeira. A leitura natural é que o modelo agora resolve
esse tipo de problema. **Uma nota diz como o modelo foi num conjunto de perguntas, e uma demonstração
diz que ele acertou pelo menos uma vez.** Nenhuma das duas diz o que ele vai fazer com o seu
problema, e é nessa distância que mora a maior parte das decepções.

Cinco perguntas desmontam uma afirmação. As duas primeiras são sobre o teste, as duas seguintes sobre
a demonstração, e a última sobre quem está falando.

## O que foi medido, e em quê

Um *benchmark* é um conjunto fixo de perguntas com respostas conhecidas, e a nota é a fração
respondida corretamente. **A nota só vale o que valem as perguntas**: um teste que recompensa a
coisa errada pode ser passado sem a habilidade que diz medir.

O `toylm` deixa isso concreto. O `bench.txt` é um teste de três perguntas sobre se ele conhece o
café:

```
is the coffee hot
is the bread fresh
is there cake
```

```
ana@lab:~/pe$ grep -c "question : is the bread fresh" corpus.txt
2
ana@lab:~/pe$ while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < bench.txt
is the coffee hot -> yes.
is the bread fresh -> yes.
is there cake -> yes.
```

Três de três. Agora três perguntas que ele nunca viu, do `new.txt`:

```
is the café open at midnight
is the soup free
is the cat a dog
```

```
ana@lab:~/pe$ while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < new.txt
is the café open at midnight -> yes.
is the soup free -> yes.
is the cat a dog -> yes.
```

Ele responde `yes` a tudo, porque depois de `answer :` a palavra `yes` é a que o corpus dele mais
diz. Duas coisas deram errado no primeiro teste, e as duas acontecem com benchmarks de verdade:

- todas as respostas eram iguais, e um teste cujas respostas são todas `yes` mede se o modelo diz
  `yes`. Os benchmarks de verdade são montados com mais cuidado que este, e mesmo assim um modelo
  pode aprender um padrão no jeito como as perguntas são escritas que não tem nada a ver com a
  habilidade;
- as perguntas estavam nos dados de treinamento: o `grep` achou a pergunta do pão duas vezes no
  corpus. Isso se chama **contaminação**: quando as perguntas de um teste são publicadas, elas podem
  acabar no texto com que o próximo modelo é treinado, e uma nota alta passa a medir memória, não
  capacidade.

Então as perguntas a fazer são o que o benchmark mede, se as perguntas dele podem ter estado nos
dados de treinamento, e como o modelo se saiu em perguntas escritas depois de ele ser treinado.

## Uma demonstração é um exemplo escolhido

A mesma pergunta, feita dez vezes com amostragem, a partir de dez sementes:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 10
[seed 1] yes. question: is the coffee is hot.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
[seed 9] yes.
[seed 10] at seven.
```

A semente 10 acerta: o corpus diz que o café abre às sete. **Uma gravação só da semente 10 daria uma
demonstração convincente**, e ela seria honesta sobre aquela execução e calada sobre as outras nove.
Toda demonstração é escolhida por alguém, entre execuções que essa pessoa viu, e ninguém grava a
execução que falhou para um vídeo de lançamento. Isso não faz das demonstrações mentiras. Faz delas
prova de que algo *pode* acontecer.

## "Consegue" e "faz com confiabilidade"

Essa distinção é a que importa para qualquer coisa que você construa. **"Consegue" quer dizer que
aconteceu pelo menos uma vez. "Faz com confiabilidade" quer dizer que acontece na maior parte das
tentativas, com entradas parecidas com as suas**, e o único jeito de descobrir é tentar muitas
entradas e contar. O `toylm` *consegue* responder à pergunta do horário; com confiabilidade, não, uma
execução em dez. Um modelo grande é muito melhor que isso, e a pergunta é a mesma: com que
frequência, com o quê. A lição 27 é uma técnica que transforma a variação entre execuções numa
votação, e o curso `prompt-reliability` trata de medir isso direito.

## Quem mediu

Uma nota no anúncio de um fornecedor foi escolhida pelo fornecedor, em testes que ele escolheu, com
configurações que ele ajustou. Isso não a torna falsa, e também não a torna prova independente. Uma
comparação feita por alguém sem interesse no resultado, com o método publicado para que outros
repitam, vale mais. Uma medição que você mesmo faz, na sua tarefa, também.

As cinco perguntas, numa lista para guardar:

| pergunte | porque |
|---|---|
| o que exatamente foi medido? | um teste pode recompensar outra coisa que não a habilidade que ele nomeia |
| as perguntas podem ter estado nos dados de treinamento? | a contaminação transforma um teste de capacidade num teste de memória |
| é uma execução, ou muitas? | uma demonstração mostra a execução que alguém escolheu |
| diz "consegue" ou "com confiabilidade"? | uma vez não é a maior parte das vezes |
| quem mediu, e dá para repetir? | o número de um fornecedor é uma afirmação até outra pessoa chegar nele |
