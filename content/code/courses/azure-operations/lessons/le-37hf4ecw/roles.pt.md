---
title: Declarar, os papéis, e as mensagens que saem
version: 1
---

**Um incidente começa quando alguém o declara**, e não quando acontece o primeiro erro. Declarar é um ato pequeno com
efeitos grandes: abre um canal, atribui papéis e inicia um relógio, e diz a todo mundo para parar de mudar coisas naquele
sistema. A loja declara a cada chamada que uma pessoa confirma, e dá a todo incidente uma **severidade**:

| severidade | o que significa para a loja |
|---|---|
| SEV1 | a loja não consegue receber pedidos |
| SEV2 | alguns clientes não conseguem concluir um checkout |
| SEV3 | degradado, com contorno; sem venda perdida |

A quinta foi um SEV2. Três papéis vão para três pessoas diferentes assim que houver três pessoas:

- **o comandante do incidente** coordena e decide. Não a pessoa que digita os comandos: quem mantém a lista do que foi
  tentado, do que está sendo tentado e de quem está fazendo;
- **operações**, uma ou mais pessoas investigando e mudando coisas, cada mudança anunciada no canal antes de ser feita;
- **comunicação**, quem escreve para os clientes e para o resto da empresa, num horário fixo, para operações nunca ser
  interrompida com pedido de atualização.

Na quinta, Carla, de plantão, foi comandante e operações, e Dani ficou com comunicação. Com duas pessoas essa é a divisão
certa: quem fala com o cliente não deveria ser quem lê resultados de consulta.

## A mensagem

Uma atualização de status tem quatro partes e nenhum palpite: **o que os clientes veem, desde quando, o que está sendo feito
e quando vem a próxima atualização.** A primeira de Dani, sete minutos depois da declaração:

> Alguns clientes não conseguem concluir o checkout. Desde as 14:05. Estamos investigando. Próxima atualização até as 14:45.

Ela não diz nada de SQL, nada de causa, e não promete nada além da próxima atualização, porque às 14:29 ninguém sabia a causa,
e um palpite publicado para os clientes é um palpite que precisa ser desmentido em público. A atualização interna diz mais, a
externa diz menos, e as duas dizem quando vem a próxima.
