---
title: Escolhendo, cliente por cliente
version: 1
---

A pergunta nunca é "gRPC ou REST" para uma empresa inteira. **É qual protocolo cada tipo de cliente deve
usar**, e as respostas desta aula cabem em quatro perguntas.

**1. O cliente é um navegador, ou o programa de um estranho?** Então REST e JSON, seção 05: navegadores não
falam gRPC sem um tradutor, e estranhos começam pelo `curl`.

**2. Você é dono das duas pontas, e elas vão durar anos?** Dois serviços seus, publicados pelas suas
próprias equipes, são onde um contrato obrigatório e clientes gerados mais compensam: um campo renomeado no
`.proto` quebra o build de cada cliente que o usa, em vez de quebrar a produção.

**3. A conversa é um stream?** Um leitor mandando uma fila de ingressos, uma tela acompanhando uma contagem,
um serviço empurrando um feed: os streams do gRPC vêm embutidos, com controle de fluxo e prazos. O REST os
imita, e a aula 13 mostra as imitações.

**4. O volume é extremo?** Milhares de mensagens pequenas por segundo entre serviços, onde cada byte e cada
microssegundo se multiplicam: aí o tamanho e a velocidade do protobuf, seção 03, começam a contar. Para uma
API comum, cujas respostas vão comprimidas e cujo tempo vai para o banco, não contam.

**Se a primeira resposta for sim, use REST. Se qualquer uma das outras três for sim, o gRPC vale as
ferramentas que pede.** Se nenhuma for, o REST é a coisa mais simples de construir, depurar e passar ao
próximo desenvolvedor, e simplicidade é o padrão que a aula 5 defendeu.

## Sinais de que você escolheu errado

**O gRPC foi a escolha errada** se todo cliente acaba passando por um gateway que o transforma de volta em
JSON, se a maioria das sessões de depuração começa com alguém instalando o `grpcurl`, ou se um cliente de
navegador é o usuário principal. **O REST foi a escolha errada** se o código cliente de um serviço interno é
uma pilha de structs escritas à mão que divergem das do servidor, se laços de consulta imitam streams por
toda parte, ou se um campo renomeado de um lado é descoberto por um cliente. Cada um desses é uma migração
que ninguém quer; ver os sinais cedo é o motivo desta aula.
