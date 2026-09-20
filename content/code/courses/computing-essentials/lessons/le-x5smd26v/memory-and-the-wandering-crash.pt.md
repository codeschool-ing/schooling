---
title: Memória, e o travamento que não fica parado
version: 1
---

Um pente de memória com defeito é a falha de hardware que menos parece uma. Nada está lento, nada
faz barulho, nada esquenta. As coisas simplesmente dão errado, em lugares diferentes, por motivo
nenhum que alguém consiga ligar.

## A assinatura é a própria aleatoriedade

Um bug de software é reproduzível: o mesmo arquivo, o mesmo botão, o mesmo passo. **Uma falha de
memória se move.** Ontem foi o navegador, hoje é o editor de fotos, amanhã é a máquina reiniciando
sem ninguém nela.

Então o sinal não é um travamento qualquer. É o padrão:

- travamentos em **programas diferentes**, com mensagens diferentes;
- uma máquina que **reinicia sozinha**, sem padrão que alguém consiga nomear;
- um arquivo que estava bom ontem e está corrompido hoje, **sem sintoma nenhum de disco**;
- um sistema que falha ao instalar ou atualizar, repetidamente, num ponto diferente a cada vez.

Esse último vale saber sozinho: **uma instalação que falha num lugar diferente a cada vez é memória
até que se prove o contrário.** Instalar lê e escreve uma quantidade enorme, então acerta uma
posição ruim que o uso comum poderia não tocar por semanas.

## Testar é de graça, e não é um palpite

Todo sistema consegue iniciar um **teste de memória** — um programa que roda antes do sistema,
escreve padrões em cada posição e os lê de volta. É um dos poucos testes deste curso que dá uma
resposta sem ambiguidade.

Duas notas práticas. Ele leva horas, e quer essas horas: uma passada acha as piores falhas, e as
limítrofes aparecem na terceira ou na quarta. E ele roda de um pendrive, então não se importa se o
sistema instalado ainda inicia.

## E se ele acusar

Memória quase sempre vem em dois ou mais pentes, o que faz do próximo passo uma troca exatamente no
sentido da aula anterior: **tire um e rode com o outro.** A falha segue o pente defeituoso, e dois
testes resolvem qual é.

Esse é um dos reparos mais fáceis que existem num desktop, e em muitos notebooks: uma trava de cada
lado, e o pente sai na diagonal. É também uma das peças mais baratas de trocar.

## A que não é defeito nenhum

**Ficar sem memória** é outra coisa e não é um defeito. Uma máquina com pouca memória para o que
está sendo pedido dela fica muito lenta, porque o sistema começa a usar o disco como transbordo — e
o disco é milhares de vezes mais lento.

A assinatura é o oposto da falha de cima: **inteiramente previsível.** Acontece quando há muita
coisa aberta, melhora quando se fecha, e não corrompe nada. Essa é uma máquina para acrescentar
memória, não uma máquina para consertar.
