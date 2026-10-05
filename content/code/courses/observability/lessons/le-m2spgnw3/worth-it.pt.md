---
title: Quando um mesh vale a pena
version: 1
---

Um mesh muitas vezes é adotado pelo motivo errado: é o que plataformas sérias rodam. Os custos dele são
concretos, e a pergunta da aula 13 vale de novo: **quem o opera, e quanto custa na unidade que cresce?**

O Envoy do laboratório, medido depois da seção de novas tentativas, ao lado de dois serviços da loja:

```
ana@obs:~/shop$ docker stats --no-stream --format '{{.Name}}  {{.CPUPerc}}  {{.MemUsage}}' shop-envoy-1 shop-storefront-1 shop-orders-1
shop-envoy-1  0.47%  16.93MiB / 15.72GiB
shop-storefront-1  3.61%  35.69MiB / 15.72GiB
shop-orders-1  65.35%  48.06MiB / 15.72GiB
```

Dezessete megabytes e menos de meio por cento de uma CPU, contra 36 megabytes da storefront que ele atende. Um proxy é barato. A versão do mesh é um por pod.

Os custos vêm de quatro tipos:

- **Recursos.** Um proxy por pod, então a sobrecarga cresce com o número de pods, e não com o tráfego.
  Algumas dezenas de megabytes cada é pouco para um serviço e muito para mil.
- **Latência.** Toda chamada atravessa mais dois proxies. Um milissegundo ou menos cada, o que importa
  numa cadeia de vinte chamadas e não num checkout de quatro.
- **Operação.** O plano de controle é um sistema crítico próprio: certificados giram, atualizações
  trocam todo sidecar, e um erro numa regra de roteamento derruba o tráfego de todos os serviços de uma
  vez.
- **Uma segunda fonte de verdade sobre falhas.** Como a seção de novas tentativas mostrou, o proxy e a
  aplicação podem discordar sobre se uma requisição falhou, e a equipe precisa saber qual ler.

Em compensação, um mesh se paga quando várias destas são verdade ao mesmo tempo:

- **Muitos serviços, escritos por muitas equipes, em várias linguagens.** Um proxy dá a todos a mesma
  telemetria e as mesmas regras de nova tentativa e timeout, sem biblioteca para combinar.
- **Criptografia entre serviços é exigida**, por um regulador ou um cliente. TLS mútuo num mesh é uma
  política; sem um, é uma configuração de certificados em cada serviço.
- **Controle de tráfego é necessário**: canaries por porcentagem, espelhamento, troca de região em
  falha.

Para um punhado de serviços numa linguagem, a situação da loja, a resposta honesta costuma ser não. O
OpenTelemetry no código dá sinais mais ricos que um proxy. Timeouts e novas tentativas são poucas
linhas cada, e ficam ao lado da lógica que sabe se uma chamada pode ser repetida com segurança. Uma
equipe que cresce além disso vai saber: é o dia em que o mesmo bug de nova tentativa é corrigido na
quinta linguagem.

**O modo ambient** muda parte da troca. O plano de dados mais novo do Istio troca o sidecar por um proxy
por nó, para criptografia e identidade, mais proxies opcionais por serviço para os recursos de HTTP.
Assim o custo deixa de crescer a cada pod. É um desenho mais novo, com as próprias perguntas de
operação, e merece uma avaliação própria em vez de ser um padrão.
