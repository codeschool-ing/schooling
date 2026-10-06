---
title: O que comparar, e contra o quê
version: 1
---

O canário acima foi julgado por um número de cada lado: a parte das requisições que falharam. Os
2,0% da green só significaram alguma coisa porque o blue, **no mesmo momento, com o mesmo mix de
requisições**, mostrou 0,0%. Um canário é uma comparação, nunca um limite sozinho.

## Contra a base, não contra uma meta

Suponha que a regra fosse "pare se a taxa de erro da green passar de 3%". Os 2,0% da green passariam,
e o release seguiria até 100% com o bug. Suponha agora que a loja tivesse um minuto ruim, com a
transportadora lenta e os dois lados falhando 4%: a regra pararia um release que estava perfeito.

Comparar com o blue tira os dois erros. Seja qual for o tráfego, a hora do dia ou o estado da
transportadora, os dois lados enfrentam juntos, e a pergunta passa a ser **a green está pior que o
blue?** É isso que o `ops/canary.py` do laboratório codifica: ele para quando a taxa de erro da green
passa a do blue em mais de um ponto percentual. A aula 11 roda ele.

## O que medir

- **Erros**: a parte das requisições respondidas com 5xx, ou sem resposta. A usada aqui.
- **Latência**: não a média, que esconde os poucos lentos, mas um percentil alto, como o 99. Um
  release que faz uma requisição em cem levar cinco segundos tem uma média que mal se mexe.
- **Saturação**: memória, CPU, conexões abertas. Um vazamento aparece aqui horas antes de aparecer em
  qualquer outro lugar.
- **O negócio**: cotações que viram pedidos, pagamentos que se completam. Um release pode responder
  toda requisição com 200 e um preço errado. Destas quatro, só esta perceberia.

## Armadilhas

- **Requisições não são clientes.** O roteador do laboratório escolhe o lado por id de requisição,
  então um cliente que faz cinco requisições pode encontrar as duas versões. Canários reais costumam
  escolher pelo cliente, o que mantém cada um num lado só e deixa a experiência dele coerente.
- **Tráfego diferente.** Se o canário recebe só usuários internos, ou só uma região, os números
  descrevem esse grupo. Um canário deveria receber uma fatia aleatória do mix real.
- **Cedo demais.** Os primeiros minutos depois de subir incluem o aquecimento: caches vazios,
  conexões sendo abertas. Julgar por eles culpa o release por ser novo.
