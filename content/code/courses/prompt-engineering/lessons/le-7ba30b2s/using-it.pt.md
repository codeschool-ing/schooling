---
title: Tirando a resposta, e quanto a cadeia custa
version: 1
---

Uma cadeia de pensamento é escrita em proveito do modelo, e **um programa que usa a resposta só
precisa da resposta no fim dela**. Tirar essa resposta com segurança, pagar pelos passos e não se
deixar levar por eles são as três coisas de que esta seção trata.

## Uma linha de resposta combinada

Se o prompt não diz nada sobre o fim da resposta, a resposta aparece onde o modelo a puser: "então
eles pagam R$ 54", "o total dá 54", "54 reais ao todo". Um programa que lê isso tem de adivinhar
qual número do parágrafo é o resultado, e a própria cadeia está cheia de números. Por isso a
instrução fixa a última linha: "then write the result on a last line that starts with Answer:". A
ana salvou a cadeia ilustrada da seção anterior como `chain.txt`, e um comando acha a resposta
nela:

```
ana@lab:~/pe$ grep "^Answer:" chain.txt
Answer: 54
```

**Um marcador fixo transforma um parágrafo em algo que um programa consegue interpretar.** Se a
linha faltar, trate a resposta como falha em vez de pescar um número no texto; a regra da lição 19
sobre validar a saída vale aqui também. Os formatos estruturados da lição 18 vão além, com o
raciocínio num campo e a resposta em outro.

## Os passos são saída, e saída é paga

As duas respostas ilustradas são o mesmo pedido com e sem os passos. O `tok` as conta:

```
ana@lab:~/pe$ tok count direct.txt chain.txt
tokens  words  chars  file
     5      2      6  direct.txt
    94     63    263  chain.txt
```

A resposta certa custou 94 tokens de saída contra 5 da errada: quase dezenove vezes mais. **Tokens
de saída costumam ter preço mais alto que os de entrada**, e também são a parte lenta, já que cada
um é um passo do laço da lição 1. Uma cadeia em cada chamada de um serviço movimentado multiplica
a conta e a espera. O limite de tokens máximos da lição 15 também pesa mais aqui: um limite
pensado para respostas curtas pode cortar a cadeia antes de ela chegar à linha `Answer:`, e a
saída fica sem resposta nenhuma.

## Modelos que raciocinam antes de responder

No momento em que este curso é escrito (2026), vários provedores vendem modelos treinados para
produzir sozinhos uma cadeia de raciocínio antes da resposta visível, muitas vezes chamados de
modelos de raciocínio (*reasoning* ou *thinking*). Com eles, "pense passo a passo" acrescenta
pouco, porque os passos acontecem de qualquer jeito. Duas coisas valem conferir na documentação do
provedor do modelo que você usa: **se os tokens de raciocínio são cobrados como saída mesmo
quando você não os vê**, e se há um ajuste de quanto raciocínio permitir. A fonte é a documentação
e a data dela; uma lista num curso ficaria desatualizada em poucos meses.

## Uma cadeia pode soar bem e estar errada

Os passos parecem uma explicação, e isso os torna convincentes. Eles são gerados do mesmo jeito que
todo o resto, e nada os confere. O curso escreveu esta cadeia como ilustração de uma errada e
plausível:

```localised
Três flat whites a R$ 12 cada.
O cartão tem 9 carimbos, então o próximo café é o décimo e sai de graça,
e o seguinte começa um cartão novo, que também sai de graça.
Sobra 1 café para pagar: R$ 12.
Duas fatias de bolo: 2 x 15 = R$ 30.
Total: 12 + 30 = R$ 42.
Answer: 42
```

Todas as frases são fluentes, a conta de cada linha está certa, e a segunda linha inventa uma regra
que o manual não tem. Quem passa os olhos vê um trabalho cuidadoso. **Confira a resposta, e os
fatos em que os passos se apoiam, não a confiança da prosa.** Onde a resposta puder ser conferida
por um programa, como a linha de Python da seção anterior fez, confira assim.

Uma cadeia também não é um registro fiel de como se chegou à resposta. Um modelo pode escrever
passos arrumados que levam a uma resposta que ele daria de qualquer forma. Trate a cadeia como
texto que ajuda a resposta e ajuda você a notar um desvio no caminho, não como prova. A lição 27 usa
isso: se uma cadeia pode errar, várias cadeias podem ser comparadas.
