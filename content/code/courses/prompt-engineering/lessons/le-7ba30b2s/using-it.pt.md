---
title: Tirando a resposta, e quanto a cadeia custa
version: 2
---

Uma cadeia de pensamento é escrita em proveito do modelo, e **um programa que usa a resposta só
precisa da resposta no fim dela**. Tirar essa resposta com segurança, pagar pelos passos e não se
deixar levar por eles são as três coisas de que esta seção trata.

## Uma linha de resposta combinada

Se o prompt não diz nada sobre o fim da resposta, a resposta aparece onde o modelo a puser: "então
eles pagam R$ 54", "o total dá 54", "54 reais ao todo". Um programa que lê isso tem de adivinhar
qual número do parágrafo é o resultado, e a própria cadeia está cheia de números. Por isso a
instrução fixa a última linha: "then write the result on a last line that starts with Answer:". A
seção anterior guardou as duas cadeias, com `tee`, como `chain.txt` e `few.txt`. Um comando procura a
resposta em cada uma:

```
ana@lab:~/pe$ grep "^Answer:" chain.txt few.txt || echo "no Answer: line"
chain.txt:Answer: R$ 54
ana@lab:~/pe$ tok count direct.txt chain.txt few.txt
tokens  words  chars  file
     5      2      6  direct.txt
   173    117    538  chain.txt
   293    224   1090  few.txt
```

**Um marcador fixo transforma um parágrafo em algo que um programa consegue interpretar.** Ele
achou `R$ 54` na cadeia zero-shot, e nada na few-shot, cujo prompt só mostrava a linha. Se a linha
faltar, trate a resposta como falha em vez de pescar um número no texto: o último número do
`few.txt` é 62, e está errado; a regra da lição 19
sobre validar a saída vale aqui também. Os formatos estruturados da lição 18 vão além, com o
raciocínio num campo e a resposta em outro.

## Os passos são saída, e saída é paga

As três respostas são o mesmo pedido de três jeitos, e o último comando acima as contou: 5 tokens
para a resposta direta, 173 para a cadeia, 293 para a cadeia few-shot. **A resposta certa custou 173
tokens de saída contra 5 da errada**, quase trinta e cinco vezes mais, e a resposta mais longa estava
errada de todo jeito. Tokens de saída costumam custar mais que os de entrada, e também são a parte
lenta, já que cada um é um passo do laço da lição 1. Uma cadeia em todo pedido de um serviço
movimentado multiplica a conta e a espera. O limite de tokens máximos da lição 15 pesa mais aqui
também: um limite pensado para respostas curtas pode cortar uma cadeia antes que ela chegue à linha
`Answer:`, e aí a resposta não tem resposta nenhuma.

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
todo o resto, e nada os confere. A cadeia few-shot acima é uma conta de aparência cuidadosa que conta
bolos como cafés e chega a 62. Quem passa os olhos vê esforço. **Confira a resposta, e os fatos em que
os passos se apoiam, não a confiança da prosa.** Onde a resposta pode ser conferida por um programa,
como a linha de Python da seção anterior fez, confira assim.

Uma cadeia também não é um registro fiel de como se chegou à resposta. A cadeia zero-shot mostra
isso pelo outro lado: motivos errados, depois a subtração certa, depois a resposta certa. Um modelo
pode escrever passos que não levam à resposta dele, e passos arrumados que levam a uma resposta que
ele daria de qualquer forma. Trate a cadeia como
texto que ajuda a resposta e ajuda você a notar um desvio no caminho, não como prova. A lição 27 usa
isso: se uma cadeia pode errar, várias cadeias podem ser comparadas.
