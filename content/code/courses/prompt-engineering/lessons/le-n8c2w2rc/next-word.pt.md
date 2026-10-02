---
title: Uma nota para cada próxima palavra possível
version: 1
---

A imagem comum de um assistente de chat é a de um programa que procura a resposta em algum lugar,
ou a de um que entende a pergunta como uma pessoa entenderia e depois explica. Nenhuma das duas é o
que acontece. **Um modelo de linguagem faz uma coisa: dado um trecho de texto, ele dá a cada
próxima palavra possível uma probabilidade.** Tudo o que ele parece fazer, de responder a traduzir
a escrever código, é esse passo, repetido.

A bancada em que este curso roda tem um modelo de linguagem pequeno o bastante para ser lido. Ele se
chama `toylm`, aprendeu com um arquivo de 761 palavras sobre um café, e você pode perguntar a ele o
que vem depois:

```
ana@lab:~/pe$ toylm next "the coffee is"
context: trigram after 'coffee is'
  hot       59.3%  ########################
  strong    18.5%  #######
  ready     11.1%  ####
  cold       7.4%  ###
  bitter     3.7%  #
```

Ele não respondeu a uma pergunta, porque nenhuma foi feita. Ele disse quais palavras vieram depois
de `coffee is` no texto com que aprendeu, e com que frequência: `hot` em 59,3% das vezes, `bitter`
em 3,7%. Essas cinco palavras somam 100%, e **todas as outras palavras que ele conhece ficaram com
zero**, porque ele nunca as viu ali.

Mude o texto e as notas mudam junto:

```
ana@lab:~/pe$ toylm next "the café opens at"
context: trigram after 'opens at'
  seven     75.0%  ##############################
  eight     25.0%  ##########
```

**O texto que você dá a um modelo é a única coisa que ele tem para trabalhar.** Aqui isso é tudo o
que um prompt é, e a lição 2 começa daí.

## Como este faz, e como os grandes fazem

O `toylm` é um **modelo de trigramas**: ele contou, para cada par de palavras do arquivo, qual
palavra veio depois, e transforma essas contagens em porcentagens. A primeira linha de cada resposta
diz qual par ele olhou. É rudimentar, e é um modelo de linguagem de verdade no sentido que importa
aqui: entra texto, sai uma probabilidade para cada próxima palavra.

Os modelos por trás dos assistentes de chat fazem o mesmo trabalho com três diferenças, e cada uma
ganha uma lição própria:

| | `toylm` | um grande modelo de linguagem |
|---|---|---|
| o que ele prevê | a próxima **palavra** | o próximo **token**, um pedaço de palavra (lição 3) |
| o que ele olha | as últimas **duas** palavras | até centenas de milhares de tokens de uma vez (lição 4) |
| de onde vêm as notas | uma tabela de **contagens** | bilhões de números chamados **pesos**, aprendidos no treinamento (lição 8) |

A terceira linha é de onde vem a diferença de qualidade. Uma tabela de contagens só consegue repetir
um par que já viu. Uma rede treinada aprendeu padrões que valem também para texto que ela nunca viu:
gramática, fatos que eram comuns no que ela leu, o formato de um argumento, a estrutura de um
programa. **Ela continua produzindo a mesma coisa que o `toylm` produz: uma nota para cada próximo
pedaço possível.**

É por isso que vale ter cuidado ao dizer "o modelo sabe" e "o modelo pensa". O que ele tem é um
senso muito bom de **que texto costuma vir em seguida**. Na maior parte das vezes o texto provável e
o texto verdadeiro são o mesmo, e é por isso que esses modelos são úteis. A lição 5 trata das vezes
em que não são.
