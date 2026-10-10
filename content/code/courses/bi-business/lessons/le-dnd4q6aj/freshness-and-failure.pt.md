---
title: Dados em dia, e o painel que falha
version: 1
---

Um painel operacional vira ação poucos minutos depois de lido. Isso faz dele a tela mais útil da
empresa e também a mais perigosa, **porque um número errado nela vira uma ação errada antes que alguém
confira**. Duas propriedades o protegem: dados recentes o bastante para a decisão, e um painel que diz
com clareza quando os dados pararam de chegar.

## Recente o bastante é a decisão que define

O desejo comum é tempo real. Raramente é o que a decisão precisa. Marcos olha o painel e age a cada
quinze ou trinta minutos, então dados copiados do aplicativo dos motoristas a cada dez minutos bastam:
quando ele poderia agir sobre um retrato mais novo, a cópia seguinte já chegou. Copiar a cada poucos
segundos exigiria outro tipo de pipeline, custaria mais para construir e manter, e não mudaria nada do
que ele faz.

**O ritmo da decisão define o quão recente o dado precisa ser, e não o contrário.** É o argumento da
aula 2 sobre o valor da informação, aplicado ao tempo: dado que chega mais cedo só vale o que custa se
alguém agiria diferente por causa dele. A reunião mensal da aula 15 fica perfeitamente servida com os
dados de ontem, e um painel para a gestora de leitos de um hospital (aula 19), com dados de poucos
minutos.

## A hora dos dados, na tela

Todo painel operacional traz a hora que seus dados descrevem: "dados das 11:00 · há 2 min". A idade
importa mais que a hora, porque ninguém na doca de carga subtrai horários de cabeça. **E é a hora dos
dados, nunca a hora em que a página foi aberta.** Um navegador sempre mostra o presente, então uma
página carregada às 11:05 mostrando o retrato das 09:20 parece tão atual quanto uma que está certa.

## A manhã em que parou

Na terça, 3 de fevereiro de 2026, a empresa do aplicativo dos motoristas mudou o formato da exportação
durante a noite. O pipeline do Tiago, que copia as entregas para o banco de dados da Varanda a cada dez
minutos, não copiou nada a partir das 09:20 e não acusou erro, porque do lado dele simplesmente não
havia nada novo para copiar.

O painel continuou mostrando o retrato das 09:20. Às 09:20 ninguém estava atrasado ainda, então todas
as rotas apareciam perto do plano e a lista de exceções estava vazia. Por **105 minutos** a tela mais
olhada do CD disse que estava tudo bem, até que uma cliente de Betim ligou para a loja de Contagem às
11:05 perguntando pelo sofá. **Um painel congelado não parece quebrado. Parece calmo**, e calma é
justamente o que o Marcos não tinha motivo para questionar.

## Um painel que sabe a própria idade

A correção não foi um pipeline melhor; pipelines param. Foi uma regra no painel: **se nenhuma cópia
chegou em 20 minutos, os números saem e um aviso entra no lugar.** Vinte é o dobro do intervalo de
cópia: uma cópia perdida pode ser um soluço, duas seguidas são uma falha. O aviso diz o que se sabe e o
que fazer:

> Sem dados novos desde 09:20 (há 105 min). Os números abaixo estão ocultos. Ligue direto para os
> motoristas.

Esconder os números é de propósito. Um painel que mostra números velhos em cinza com um aviso pequeno no
canto continua sendo lido como atual da doca de carga. A mesma regra manda um segundo alerta, para o
Tiago, porque ele é o dono do pipeline e o Marcos não tem como consertá-lo. Um alerta que vai para quem
só pode assistir é a notificação da seção anterior, mais uma vez.

## As outras duas maneiras de um painel errar quieto

Uma cópia que para é a falha fácil, porque dá para medir o tempo. Outras duas dão números que parecem
normais:

- **Parte dos dados falta.** O celular de um motorista descarrega e a rota 9 para de enviar. As paradas
  dela somem de todas as contagens. Os blocos pequenos embaixo das exceções existem para isso: o painel
  espera catorze rotas e 286 pedidos, e mostra um aviso quando chegam menos.
- **Parte dos dados chega duas vezes.** Uma cópia que roda duas vezes depois de um reinício põe cada
  pedido duas vezes no banco, e o painel anuncia 572 pedidos no dia. A verificação é do mesmo tipo: um
  total que salta em relação ao plano do dia é problema de dados até prova em contrário.

Nenhuma dessas verificações precisa de estatístico. Cada uma compara o que chegou com o que se esperava,
e **diz isso na tela em vez de mostrar um número errado**. O lado da engenharia — novas tentativas,
alertas no próprio pipeline, o job que falhou às três da manhã — é a aula 10 de `pipelines-etl`, e quem
é dono da qualidade dos dados é a aula 9 de `data-governance`.

## O que as três seções somam

A pergunta decide o painel: a pergunta do Marcos deu uma lista de exceções, não um gráfico de meses. O
limiar decide o alerta, e se escolhe contando o que cada linha teria feito num dia de verdade. E o
painel precisa saber quando está errado, porque quem o usa age na hora. A aula 15 sobe um nível, para
uma gestora que lê a tela uma vez por mês e tem dias, não minutos, para agir.
