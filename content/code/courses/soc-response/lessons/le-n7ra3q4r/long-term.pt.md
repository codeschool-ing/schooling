---
title: Contenção de longo prazo
version: 1
---

A contenção de curto prazo é um torniquete: segura, e ninguém quer viver com ele. A **contenção de longo
prazo** é o conjunto de medidas temporárias que deixa o negócio funcionar normalmente de novo enquanto a
erradicação e a recuperação são preparadas, o que pode levar dias. Os sistemas continuam em serviço, sob
condições.

Para o incidente da quinta, as condições poderiam ser estas:

| medida | por que pode ficar por um tempo |
|---|---|
| o `files` só alcança a internet pela regra de saída, com o backup liberado | o escritório só precisava do backup; a regra acaba sendo a política que sempre deveria ter existido |
| o bruno trabalha com **senha nova e chave nova**, e a chave antiga sumiu de todos os hosts do escopo | a conta volta ao serviço e as credenciais roubadas, não |
| o `gw` aceita **só chaves**, sem senhas, quando todo usuário tiver uma chave | a quinta começou com uma senha adivinhada; não ter o que adivinhar é o conserto disso |
| uma **regra Sigma** alerta qualquer conexão do `files` para um destino que não seja o backup | se a regra um dia for removida por engano, ou algo tentar mesmo assim, alguém fica sabendo |
| o `gw` é **vigiado mais de perto** por duas semanas: todo login revisto na manhã seguinte | a chave foi achada; se era a única coisa deixada para trás ainda não se sabe |
| uma **reconstrução do `gw`** fica marcada para a aula 14 | um host que um invasor controlou não pode mais ser totalmente confiável; a data é marcada agora para não escorregar |

Duas coisas sobre a lista. **Parte dela nunca deveria ser desfeita.** A regra de saída e o acesso só por chave
foram contenção na quinta e passam a ser simplesmente uma configuração melhor; a aula 15 é onde esse tipo de
achado vira mudança no padrão de instalação, para o próximo servidor já nascer assim. E **parte dela tem data
marcada**: uma vigilância reforçada que nunca termina é uma fila que ninguém lê depois do primeiro mês, que é
a fadiga de alertas da aula 7 chegando por outra porta.

A contenção de longo prazo também tem uma pré-condição fácil de pular: **os backups são conferidos antes de a
erradicação começar.** Reconstruir o `gw` supõe que existe uma cópia confiável da configuração dele de antes da
quinta. Se a única cópia é aquela que o invasor podia editar, a reconstrução restaura o trabalho dele.
