---
title: Híbrida, a forma que as redes reais têm
version: 2
---

Pergunte qual é a topologia da rede de uma empresa e a resposta honesta é **todas, cada uma no seu
lugar**. Uma rede real é **híbrida**: formas emendadas, cada uma escolhida onde a sua troca compensa.
As seções anteriores dão as trocas:

| forma | uma falha derruba | cabos | onde compensa |
|---|---|---|---|
| estrela | uma máquina, ou todas se for o centro | um por máquina | muitos aparelhos baratos |
| anel | nada, até um segundo corte | um por aparelho | uma volta de fibra em torno de uma cidade |
| malha completa | nada, até vários cortes | n × (n − 1) / 2 | poucos aparelhos dos quais todos dependem |

Leia essa tabela das mesas para dentro e a rede típica de uma empresa se desenha sozinha.

- **Os andares são estrelas.** Cada PC, impressora e telefone tem um cabo até um switch de acesso no
  armário do andar. São centenas deles, cada um importa para uma pessoa, e a estrela é a forma mais
  barata que faz de um cabo quebrado o problema de uma pessoa só.
- **O prédio é uma estrela de estrelas**, às vezes chamada de *estrela estendida* ou de *árvore*: o
  switch de cada andar tem um cabo subindo até um switch ou roteador que junta os andares.
- **O núcleo é em malha.** Os dois ou três aparelhos do meio carregam o tráfego de todo mundo, então
  cada um é ligado a cada um dos outros, ou pelo menos a dois deles. Uma malha completa de três custa
  três cabos, e qualquer cabo pode falhar sem isolar um roteador.
- **Entre cidades, é o que a operadora vende**, e muitas vezes um anel de fibra na rede
  metropolitana, com as sedes da empresa penduradas nele como estrelas.

## O laboratório já é híbrido

O cenário `office` deste curso parece uma estrela, e o switch sw1 é uma. Mas siga o desenho no alto do
`office.sh`, da aula 1, para fora do escritório: o sw1 está pendurado no r1, o r1 está ligado à operadora `isp`, a
`isp` a um balanceador de carga `lb`, e o `lb` é o centro de uma segunda estrela, pequena, com os dois
servidores web `web1` e `web2`.

```
pc1 pc2 pc3 srv --- sw1 --- r1 === isp --- lb --- web1, web2
```

Uma estrela, uma corrente de links únicos, e outra estrela. **Cada link único dessa corrente é um ponto
único de falha** para o escritório chegar aos servidores web: perca o cabo r1–isp e o escritório
inteiro fica isolado de uma vez, exatamente como o centro desligado no experimento da estrela.

## Escolher, antes que a aula 6 faça disso um método

O padrão em tudo isso é uma pergunta feita aparelho por aparelho: **se isto falhar, quantas pessoas
percebem?** Um PC de mesa falha para uma pessoa, e um cabo basta. Um switch de andar falha para o
andar, e muitas empresas guardam um reserva no armário em vez de um segundo cabo até cada mesa. Um
roteador de núcleo falha para todos, e é aí que um segundo roteador e uma malha de cabos saem baratos
perto da alternativa.

A aula 6 transforma essa pergunta no vocabulário de projeto de redes — hierarquia, redundância, pontos
únicos de falha — e monta um campus cujas camadas são exatamente a híbrida acima: estrelas embaixo, uma
malha em cima.
