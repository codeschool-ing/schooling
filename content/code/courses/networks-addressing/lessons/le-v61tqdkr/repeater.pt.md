---
title: "O repetidor: distância, e mais nada"
version: 1
---

Um sinal num cabo fica mais fraco e mais distorcido quanto mais longe vai. Passado um certo
comprimento, a placa da outra ponta não distingue mais um 1 de um 0. **Um repetidor recebe o sinal
antes desse ponto, o regenera como um sinal limpo com o tempo refeito, e o manda adiante.** É todo
o trabalho dele. Ele não lê endereço, não guarda tabela e não decide nada, o que o põe na camada 1
junto com o cabo que estende. **Este laboratório não tem repetidor**: os cabos dele são software e
nunca enfraquecem, então esta seção não mostra saída.

O limite contra o qual ele trabalha está escrito em cada padrão Ethernet. Para o cobre de par
trançado, o cabo de toda parede de escritório, **um trecho entre dois equipamentos pode ter 100
metros**, e é esse número que decide onde ficam os switches de um prédio: cada mesa tem de estar a
menos de 100 metros de cabo de um deles. A fibra vai muito mais longe, e por isso os enlaces entre
prédios são de fibra.

A ideia errada que vale nomear é que um repetidor deixa a rede maior. Ele deixa um **cabo** mais
comprido. Tudo dos dois lados continua dividindo um só sinal: um quadro enviado de um lado é
repetido do outro, precise alguém dele ou não, e duas máquinas transmitindo ao mesmo tempo em lados
opostos continuam colidindo. **Um repetidor estende um domínio de colisão**, que a aula 18 define;
ele nunca o divide.

É também por isso que o hub da aula 1 é descrito como um **repetidor com várias portas**. Ele
regenera o que chega por uma porta e o manda por todas as outras, que é o mesmo trabalho feito em
várias direções de uma vez, com as mesmas consequências.

## Onde você encontra um hoje

Quase ninguém instala numa rede Ethernet uma caixa chamada repetidor, porque um switch faz o
trabalho melhor: ele também regenera o sinal, já que recebe cada quadro e o envia de novo, e não
repassa o que o outro lado não precisa. A ideia sobrevive em três lugares:

- **Conversores de mídia e enlaces de fibra.** Quando 100 metros não bastam, a resposta é um
  switch em cada ponta de uma fibra, e não uma corrente de repetidores no cobre.
- **Regeneração de sinal dentro de outros equipamentos.** A fibra de longa distância e as linhas do
  provedor têm amplificadores e regeneradores pelo caminho, fora da vista das redes que carregam.
- **"Repetidores" de Wi-Fi vendidos para casas.** Apesar do nome, eles recebem quadros inteiros e
  os mandam de novo, então trabalham na camada 2, e cada quadro que retransmitem cruza o ar duas
  vezes, o que divide o tempo de ar do canal entre os dois saltos.

O hábito útil desta seção é uma pergunta a fazer sobre qualquer aparelho vendido como extensor de
rede: ele só leva o sinal mais longe, ou lê os quadros? Um repetidor só leva; o switch da aula 1
lê, e a bridge da próxima seção é onde essa diferença começou.
