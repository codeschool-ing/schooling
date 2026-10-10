---
title: SOA e microsserviços, lado a lado
version: 1
---

Microsserviços costumam ser descritos como "SOA bem feito", o que é perto o bastante para enganar. Os
dois constroem um sistema com serviços que têm contratos. **Eles diferem em onde mora a inteligência,
quem é dono do quê, e o tamanho das peças que se mexem**, e cada diferença é uma reação a algo que
doeu.

| | SOA como era praticado | microsserviços |
| --- | --- | --- |
| alcance | integrar aplicações existentes numa empresa inteira | construir um sistema com partes implantáveis de forma independente |
| onde está a lógica | muitas vezes no barramento: roteamento, transformação, orquestração | nos serviços; o cano só carrega |
| dados | os serviços muitas vezes ficavam na frente de um banco corporativo compartilhado | cada serviço é dono dos seus dados |
| contratos | WSDL e SOAP, pesados e fortemente tipados | em geral HTTP com JSON, ou um protocolo binário como gRPC, ou eventos |
| governança | central: uma equipe de integração e um registro de serviços | por equipe, com convenções de plataforma compartilhadas |
| implantação | serviços lançados no calendário da empresa | cada serviço no calendário da sua equipe |

Duas dessas linhas são a lição do SOA para quem constrói serviços hoje.

**Mantenha o cano burro.** Uma fila, um balanceador de carga e um gateway estão bem; a aula 19 tem um
gateway. No momento em que um middleware começa a guardar regras de negócio, toda equipe passa a
depender da equipe dona dele, e o middleware vira o trem de releases que a aula 1 descreveu.

**Seja dono do dado.** Um serviço que é uma casca fina sobre uma tabela que todo mundo também lê não é
uma fronteira; é um salto a mais na frente do mesmo acoplamento.

## Orquestração e coreografia

O hábito do ESB de rodar um processo como um fluxo central tem um nome, **orquestração**: um
componente conhece os passos e diz a cada serviço o que fazer, em ordem. A alternativa é a
**coreografia**: cada serviço reage aos eventos dos outros e ninguém guarda o fluxo inteiro. As duas
são legítimas num sistema de microsserviços, e a aula 14 constrói uma saga de cada jeito. A diferença
para o ESB não é que orquestrar seja proibido. É que **o orquestrador é um serviço da equipe dona do
processo**, não um produto compartilhado de outra pessoa.
