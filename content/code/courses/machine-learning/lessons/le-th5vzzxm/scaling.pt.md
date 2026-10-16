---
title: Escala, a penalidade de fábrica e colunas correlacionadas
version: 1
---

Três coisas sobre modelos lineares que ficam invisíveis até causarem uma conclusão errada.

## Pesos sem escala não se comparam

No `linear.py`, o peso da distância é 2,60 e o dos itens 0,37, e a leitura tentadora é que a
distância importa sete vezes mais. Não quer dizer nada disso. A distância vai de menos de um
quilômetro a uns trinta, os itens de 4 a 30, e um peso é *por unidade*: troque a unidade da distância
para metros e o peso vira 0,0026, com exatamente o mesmo modelo.

O `StandardScaler` subtrai a média de cada coluna e divide pelo desvio-padrão, então toda coluna passa
a ser medida em *desvios-padrão a partir do típico*. Depois disso os pesos se comparam: cada um diz
quanto uma mudança de tamanho típico naquela coluna move a previsão. O `logistic.py` padronizou por
isso, e é por isso que a ordem dele quer dizer algo.

## A LogisticRegression vem regularizada de fábrica

A `LogisticRegression` do scikit-learn aplica uma **penalidade ridge a menos que se diga o
contrário**, com a força dada por `C`, que é o inverso do `alpha` da seção 04: `C` menor, penalidade
mais forte. O padrão é `C=1`. Daí saem duas consequências:

- **padronizar muda o modelo**, não só a leitura dele. A penalidade trata todo peso igual, então uma
  coluna numa escala grande, que precisa só de um peso pequeno, quase não é penalizada, e uma numa
  escala pequena é penalizada com força. Sem padronizar, a penalidade favorece colunas pelas unidades,
  em silêncio;
- **os pesos vêm encolhidos**, um pouco quando há muitas linhas, como aqui. Quem os relata como "o
  efeito da avaliação" está relatando um número um pouco encolhido. Para desligar a penalidade, passe
  `C=np.inf`, e espere que o resolvedor precise de mais passos.

A `LinearRegression` não tem penalidade nenhuma; `Ridge` e `Lasso` são as versões penalizadas dela.

## Colunas correlacionadas dividem o peso

Quando duas colunas carregam a mesma informação, um modelo linear pode pôr o peso em qualquer uma, ou
dividi-lo entre as duas, e as previsões quase não mudam. `orders_90d` e `skips_90d` são dois lados de
um mesmo hábito: um assinante semanal que pula mais pede menos. Os pesos individuais delas ficam então
instáveis, e uma pequena mudança nas linhas de treino pode passar peso de uma para outra, ou até
inverter um sinal.

Esse é o principal motivo para **não ler um peso como a importância de uma coluna**. Uma coluna cuja
informação é compartilhada com outra pode ganhar um peso pequeno e ainda assim ser útil; tire a
parceira e o peso dela salta. O ridge reduz a instabilidade espalhando o peso entre colunas
correlacionadas; o lasso tende a ficar com uma e zerar a outra, e qual ele mantém pode depender de
sorte. A aula 19 mede importância de um jeito que não depende de pesos.
