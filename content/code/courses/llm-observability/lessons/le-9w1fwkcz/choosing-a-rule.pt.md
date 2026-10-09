---
title: O que faz um alerta valer a pena
version: 2
---

As quatro regras têm uma estrutura comum, e a estrutura é o que uma equipe escreve para todo alerta que
mantém:

1. **Um sinal com definição.** Aqui a parcela de respostas que são a recusa combinada, contada pelo texto
   exato. Um sinal cujo sentido se desloca faz todo limiar sobre ele se deslocar também.
2. **Uma janela e uma amostra mínima.** Longa o bastante para ter respostas suficientes, curta o bastante
   para perceber em horas. A aritmética da aula 9 diz quantas bastam; a regra de Wilson põe isso dentro do
   teste.
3. **Uma comparação com o normal.** Uma linha de base do passado recente do próprio assistente, não um
   número redondo.
4. **Um histórico medido.** Quantos alarmes falsos teria dado, quanto demora para disparar, e se fica
   ligado enquanto o problema dura, medido no histórico antes de ser ligado, como o `alerts.py` faz. A
   precisão e a revocação da aula 11, aplicadas ao próprio alerta.

## Para onde ele manda

A aula 11 disse que um alerta que acorda alguém precisa de precisão acima de tudo. A regra de Wilson não
deu alarme falso em dois dias e meio, o que serve para uma mensagem no canal da equipe e diz pouco demais
para um chamado às três da manhã: uns poucos dias de histórico não prometem o mês seguinte. A maioria dos alertas de qualidade pertence ao primeiro lugar: uma alta nas recusas é problema para
a manhã, não uma pane. O que chama alguém no meio da noite é o assistente falhando de vez, os erros e
timeouts da aula 4, que não têm problema de definição nenhum.

**Todo alerta leva o que a pessoa precisa para começar.** A versão em produção, a janela e os números que
o dispararam, e um link para os traces por trás dele, filtrados para as recusas daquela janela. Quem o
abre deveria estar a um clique da árvore de trace da aula 1.

## Além das recusas

A mesma estrutura vale para todo sinal que o curso montou:

- **Polegares para baixo e reformulações**, os da aula 5, com uma janela mais longa, porque são menos.
- **Custo por requisição**, o da aula 3, contra a sua própria linha de base: a versão que de repente fica
  cara é uma regressão tanto quanto a que de repente fica ruim, como a aula 14 viu.
- **Latência**, a da aula 4, nos percentis lentos e não na mediana.
- **A nota amostrada do juiz**, a da aula 9, sempre com o seu n, e só num critério que a aula 10 mostrou
  que o juiz consegue ver.
- **Nenhum tráfego.** Uma hora de movimento sem nenhuma resposta não é uma hora boa: é um pipeline
  quebrado, e um alerta sobre taxas nunca vai disparar nela, porque não há o que dividir.
