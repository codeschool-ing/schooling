---
title: Mantendo a busca honesta
version: 1
---

Uma busca que testa muitos prompts e fica com a nota mais alta sempre vai achar uma nota mais alta.
**O que a nota sozinha não diz é se o vencedor é bom, ou só o que por acaso se encaixou nestes
poucos exemplos.** Quatro hábitos mantêm o método honesto, e a bancada mostra três deles.

## Dê nota ao vencedor em exemplos que não o escolheram

O vencedor foi escolhido porque se saiu melhor em `tests.tsv`. Isso faz do 4/4 dele um número
otimista: a própria escolha gastou esses quatro exemplos. A medida honesta é um segundo conjunto,
guardado desde o início e nunca usado para escolher nada, um **conjunto reservado** (*held-out*):

```
ana@lab:~/pe$ cat held.tsv
café	full
soup	tomato
cake	gone
ana@lab:~/pe$ ape best.txt held.tsv
1/3  the {x} is
        soup    wanted tomato  got hot
        cake    wanted gone    got sweet
best: the {x} is
```

Quatro de quatro viraram um de três. Nada mudou no modelo de prompt nem no modelo; só os exemplos
mudaram. **A nota no conjunto reservado é a que se informa**, e é a que um usuário encontra, porque
usuários trazem entradas que ninguém usou para escolher o prompt.

A regra tem uma armadilha. Olhe o erro em `soup`, edite o modelo de prompt para corrigi-lo e dê nota
de novo em `held.tsv`, e o conjunto reservado virou um segundo conjunto de escolha. A nota dele passa
a ser otimista, exatamente como a primeira era. Um conjunto reservado mede com honestidade uma vez
por decisão; depois disso você precisa de exemplos novos.

## Poucos exemplos, muitos candidatos

Sobreajuste (*overfitting*) é o nome geral de uma escolha que se encaixa nos exemplos em que foi
feita melhor do que na tarefa. Duas coisas o pioram, e o APE tem as duas por construção. **Quanto
menos exemplos, mais um candidato sortudo vence por acaso**, e quatro exemplos é muito pouco. E
quanto mais candidatos você pontua, mais chances um deles tem de ter sorte. Uma busca com cem
propostas e uma dúzia de exemplos vai achar algo que parece excelente nesses doze.

O remédio é sem graça e funciona: mais exemplos rotulados do que parece necessário, tirados das
entradas que o prompt vai receber de verdade, com a parte reservada grande o bastante para querer
dizer alguma coisa.

## A métrica decide o que é "melhor"

O `ape` só dá ponto quando a primeira palavra bate exatamente. Leia de novo o segundo erro. O
arquivo com que o `toylm` aprendeu diz `the cake is sweet` três vezes e `the cake is gone by noon`
duas, então `sweet` é uma resposta verdadeira que o rótulo não listou. **A métrica deu como errada
uma resposta correta**, e uma busca guiada por essa métrica empurraria para prompts que dizem
`gone`, quer você quisesse isso ou não.

Toda métrica tem uma versão disso. A correspondência exata pune uma resposta certa dita com outras
palavras; uma métrica que premia tamanho acha prompts prolixos; um modelo a quem se pede para dar
nota às respostas tem preferências próprias. Escolher a métrica é escolher o que a busca vai
otimizar, então escreva-a e confira-a em algumas respostas à mão antes de confiar numa classificação
construída sobre ela.

## Mantenha uma pessoa lendo o vencedor

A busca informou `best: it is a cold day and the {x} is`. Ele empatou com `the {x} is` em 4/4, e o
`ape` fica com a primeira nota mais alta do arquivo. **Uma pessoa que lê os dois vê na hora que as
palavras a mais não fazem nada**: o `toylm` só olha as duas últimas, então o dia frio nunca chega
até ele. A execução no conjunto reservado, acima, usou o curto por esse motivo.

Num modelo grande os motivos são menos óbvios, e ler importa mais. Um prompt vencedor pode trazer
uma suposição que você não assinaria, como "sempre responda sim na dúvida", que pontuou bem porque a
maioria dos rótulos era sim. Pode conter uma frase copiada de um dos exemplos, que funciona naquele
exemplo e em nenhum outro. Ninguém pega isso por uma nota. O programa propõe e mede; **uma pessoa
aprova o que vai para produção**, a mesma divisão de trabalho do laço da lição 29, que segura um
e-mail até alguém confirmar.

## Onde o curso termina

Esta é a última técnica deste curso. Desde a lição 2, toda lição disse que um prompt é algo que você
escreve, testa e muda, e esta entrega parte da escrita a um programa enquanto o teste continua sendo
seu.

::: track ai prompt
O próximo curso da sua trilha, `prompt-reliability`, parte desse teste: conjuntos de teste, métricas
de avaliação e prompts versionados, com cada mudança medida. O `ai-security`, mais adiante na
trilha, volta à lição 7 e trata a injeção de prompt como o problema de segurança que ela é.
:::

::: track *
Dois cursos se apoiam diretamente neste. O `prompt-reliability` transforma o teste desta lição numa
prática: conjuntos de teste, métricas de avaliação e prompts versionados. O `ai-security` volta à
lição 7 e trata a injeção de prompt como o problema de segurança que ela é, e ele está em todas as
trilhas que têm este curso.
:::
