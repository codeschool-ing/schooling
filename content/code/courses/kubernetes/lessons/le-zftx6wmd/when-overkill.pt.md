---
title: Quando o Kubernetes é mais do que o problema
version: 1
---

**Um cluster é excesso quando as decisões que ele automatiza são decisões que ninguém precisava que
fossem tomadas.** O laço da lição 1 vale na proporção de quantas vezes o mundo se afasta do que foi
escrito: cópias caindo, máquinas falhando, deploys acontecendo, carga mudando. Onde nada disso
acontece com frequência, o laço tem pouco a fazer e ainda precisa ser alimentado.

## O que você assume junto com ele

A conta do Kubernetes chega em quatro partes, e só a primeira é dinheiro.

- **O plano de controle precisa ficar de pé.** Se ele para, as cópias que estão rodando continuam
  rodando, e nada pode mudar: nenhum deploy, nenhuma substituta para uma cópia que morre, nenhuma
  escala. A lição 4 para uma parte dele de propósito para mostrar exatamente isso.
- **Ele precisa ser atualizado.** O projeto Kubernetes lança três versões menores por ano e dá
  suporte a cada uma por cerca de catorze meses, então um cluster deixado de lado sai do suporte em
  menos de um ano e meio. Os provedores gerenciados cobram a mais para manter uma versão antiga
  rodando, como a lição 6 mostra.
- **Há um vocabulário para aprender.** Este curso tem 48 lições por um motivo, e cada pessoa que
  mexe no cluster precisa de uma parte dele.
- **As próprias máquinas.** Um plano de controle de alta disponibilidade são três máquinas antes de
  a primeira cópia da aplicação rodar, ou um serviço gerenciado com uma taxa por cluster por hora.

## Perguntas que decidem

Nenhuma decide sozinha, mas juntas costumam decidir.

| pergunta | aponta para uma ferramenta mais simples | aponta para o Kubernetes |
|---|---|---|
| quantos serviços? | de um a uns poucos | dezenas, de equipes diferentes |
| quantas máquinas? | uma ou duas | muitas, e elas vêm e vão |
| com que frequência há deploy? | toda semana ou menos | muitas vezes por dia |
| a carga muda muito? | é estável | oscila, e capacidade custa dinheiro |
| precisa mudar de provedor? | não, uma nuvem está bem | sim, ou também precisa rodar em máquinas próprias |
| quem vai operar? | ninguém em tempo integral | uma equipe, ou um provedor gerenciado e uma equipe |

**Uma regra útil é ficar com o mínimo de maquinário que responda às perguntas que você realmente
tem.** Um serviço numa máquina é o Compose, da lição 1. Uns poucos serviços numa nuvem, sem ninguém
para cuidar de um cluster, é em geral o executor da própria nuvem ou uma plataforma. O Kubernetes
paga o que custa quando muitas equipes publicam muitos serviços com frequência, quando os mesmos
arquivos precisam rodar em vários lugares, ou quando o software empacotado em volta dele (a lição 37
instala um pouco) economiza mais trabalho do que o cluster custa.

## E quando a decisão já foi tomada

Muitas vezes foi. Uma empresa que já roda Kubernetes vai pôr o próximo serviço nele, porque o custo
do cluster já está pago e mais um conjunto de objetos sai barato. É um bom motivo, e é a situação que
a maioria das pessoas que estudam este curso vai encontrar primeiro. O que esta seção pede é que
você saiba distingui-la da outra: uma equipe nova, com um serviço, escolhendo um cluster porque é o
que todo mundo usa.
