---
title: Escolher a temperatura para a tarefa
version: 1
---

Uma temperatura baixa não é a escolha segura, e uma alta não é a escolha criativa. **A temperatura
certa depende de a tarefa ter uma resposta certa ou muitas boas.** Duas rodadas de seis amostras
mostram a troca.

Em 0,3, `seven` fica com quase toda a fração depois de `opens at`:

```
ana@lab:~/pe$ toylm dist "the café opens at" --temperature 0.3
context: trigram after 'opens at'
  seven     97.5%  #######################################
  eight      2.5%  #
```

Seis sorteios, seis vezes a mesma resposta:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 0.3 --samples 6
[seed 1] seven.
[seed 2] seven.
[seed 3] seven.
[seed 4] seven.
[seed 5] seven.
[seed 6] seven.
```

Em 1,5 as mesmas seis sementes dão isto:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 1.5 --samples 6
[seed 1] seven. question: when does the café opens at eight on sunday.
[seed 2] eight on sunday.
[seed 3] seven.
[seed 4] seven.
[seed 5] seven. question: when does it close? answer: yes.
[seed 6] eight on sunday.
```

**A variedade veio com disparate no mesmo lote.** Duas das seis dizem `eight on sunday`, que é
verdade aos domingos e não é o horário em que o café abre nos outros seis dias. A semente 1 se
perde numa pergunta com um erro de gramática, e a semente 5 responde `yes` a uma pergunta sobre o
horário. Cada palavra veio depois das duas anteriores em algum lugar do arquivo, que é tudo o que um
modelo de trigramas confere, e em 1,5 as continuações improváveis saíram com frequência suficiente
para aparecer.

O `toylm` só consegue recombinar pares que já viu. Um modelo grande numa temperatura alta tem o
vocabulário inteiro para sortear, então o desvio vai mais longe: um nome errado, um detalhe
inventado, uma frase que muda de assunto no meio.

## Um ponto de partida por tarefa

| a tarefa | por onde começar | por quê |
|---|---|---|
| extrair campos, classificar, converter um formato | 0, ou perto disso | há uma saída certa, e variação é só erro |
| responder a partir de documentos que você forneceu | baixa | a resposta está no texto; sortear um token improvável só se afasta dela |
| redação comum, explicação, conversa | o padrão do provedor | os padrões são escolhidos para esse tipo de uso |
| brainstorming, nomes, alternativas para escolher | mais alta | você quer candidatos diferentes a cada execução, e vai descartar a maioria |

Comece por aí e **mude enquanto olha a saída**, um passo por vez. A tabela não dá números para
"baixa" e "mais alta" porque a escala não é a mesma em todo lugar: cada API documenta a própria
faixa e o próprio padrão, e o mesmo número não quer dizer a mesma coisa em dois modelos. Leia a
faixa na documentação da API que você chama.

## O que a temperatura não faz

**A temperatura não torna uma resposta mais verdadeira.** Ela só decide até onde, na lista de
continuações prováveis, um sorteio pode chegar. Uma temperatura baixa dá a resposta mais provável
do modelo, e a lição 5 mostrou que provável e verdadeiro não são a mesma coisa. Uma temperatura
alta dá mais das improváveis, que erram mais, e não são mais sábias.

Ela também não conserta um prompt vago. Se o prompt deixa três leituras em aberto, a temperatura 0
escolhe a leitura mais provável todas as vezes e as outras nunca aparecem, então a ambiguidade fica
escondida, não resolvida. O conserto disso está no prompt, que é do que trata a maior parte deste
curso.

A temperatura é um de vários controles sobre o mesmo sorteio. A lição 14 mostra mais dois, top-k e
top-p, que cortam palavras da lista antes do sorteio em vez de remodelá-la.
