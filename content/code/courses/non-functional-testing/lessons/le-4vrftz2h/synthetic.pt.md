---
title: Monitoramento sintético e de usuários reais
version: 1
---

As métricas da aula 22 vêm de dentro do servidor. Elas contam o que o servidor respondeu e
cronometram o que o servidor fez, e dividem com o próprio servidor um ponto cego: **uma requisição
que nunca chegou até ele não deixa rastro ali.** Um registro de DNS apontando para o endereço
errado, um certificado que venceu à meia-noite, um balanceador de carga mandando todo mundo para uma
máquina desligada. Para o servidor é uma noite tranquila, e a taxa de requisições caindo parece
gente indo dormir.

Então a produção é vigiada de fora também, e há duas maneiras de ficar do lado de fora.

**Monitoramento sintético** é um programa fingindo ser um cliente, num horário fixo. A cada minuto
ele faz o que um cliente faria — abrir a lista de espetáculos, escolher um, reservar um assento — e
confere que cada passo respondeu, respondeu certo e respondeu a tempo. Ninguém precisa estar usando
o sistema para ele funcionar, então ele acha a queda das 04:00 antes do primeiro cliente real das
07:00. É um teste funcional, um teste de carga de um usuário só e um monitor ao mesmo tempo, rodando
contra a produção enquanto a produção existir.

**Monitoramento de usuários reais**, RUM na sigla em inglês, mede as pessoas que estão lá de
verdade. Um pequeno script na página informa quanto cada visita levou para carregar, quais erros o
navegador lançou, de que país e de que tipo de celular. As Core Web Vitals da aula 10 são lidas
assim quando vêm do campo e não do Lighthouse. Ele vê tudo o que os usuários reais fazem e nada do
que eles não fazem: às 04:00 não tem nada a dizer.

| | sintético | usuários reais |
|---|---|---|
| quem gera o tráfego | o seu script, num horário fixo | os seus clientes, quando têm vontade |
| vê uma queda sem ninguém usando o sistema | sim | não |
| vê o caminho que ninguém roteirizou | não | sim |
| resultados comparáveis de um dia para o outro | sim, a mesma jornada toda vez | só no agregado, a mistura de usuários muda |
| custo | o tráfego da própria sonda, e os dados de teste dela | um script em cada página, e o que ele coleta sobre as pessoas |

**Eles respondem a perguntas diferentes, então uma equipe precisa dos dois.** A verificação
sintética diz *a jornada que eu escrevi ainda funciona*; o monitoramento de usuários reais diz *é
isto que as pessoas estão passando*. O resto desta aula constrói a primeira, porque ela pode ser
construída do zero na máquina que você tem.

## O Runscope, e para onde ele foi

Os produtos de monitoramento sintético de APIs são mais velhos que a maioria das equipes que os
usam. O **Runscope** é o que o título desta aula cita, um serviço hospedado dos anos 2010. Você
escrevia uma sequência de requisições a uma API com asserções em cada uma — status, um campo no
corpo JSON, um limite de tempo — e ele as rodava num horário fixo a partir de locais pelo mundo e
avisava quando uma falhava. É exatamente o formato da sonda da próxima seção.

A história dele é uma pequena lição sobre o que acontece com uma ferramenta SaaS. Segundo a
imprensa da época e o artigo da Wikipédia sobre ele, **a CA Technologies comprou o Runscope em
setembro de 2017**, um ano depois de comprar o BlazeMeter, o serviço de teste de carga, e pôs os
dois lado a lado. A Broadcom comprou a CA em 2018. Em 2019 o monitoramento do Runscope foi fundido
na plataforma BlazeMeter, onde virou o recurso de monitoramento de APIs dela, e em 2021 a Broadcom
vendeu o BlazeMeter para a Perforce. Essas datas vêm de fontes secundárias — notícias e a
Wikipédia — e não foram conferidas com os anúncios originais, e não foi verificado de forma alguma
se o antigo serviço runscope.com ainda aceita contas novas. Nada nesta aula executou qualquer um dos
dois produtos.

O que sobrevive a toda aquisição é a ideia, e a ideia é portátil. Os testes que você escreve num
produto hospedado ficam no formato desse produto, e mudá-los quando o produto troca de dono é o mesmo
aprisionamento que a aula 22 descreveu para os painéis. Uma sonda que é um arquivo no seu próprio
repositório vai junto com você.

Datadog, New Relic e Grafana Cloud vendem verificações sintéticas hoje, assim como Checkly, Uptime
Robot e muitos outros; de certo modo, o k6 também, que pode rodar um script com `checks` e
`thresholds` num horário fixo a partir dos locais da própria Grafana.
