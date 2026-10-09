---
title: Sendo chamado de volta
version: 2
---

A aula 4 inverteu o polling para a telemetria: o equipamento envia valores a um coletor que fez a
assinatura. **Um webhook inverte o mesmo para eventos**, e é mais simples ainda. Um sistema que
sabe que algo aconteceu faz uma requisição HTTP para um endereço que alguém lhe deu antes, com
uma descrição do evento no corpo. Nada fica conectado entre um e outro; cada evento é um POST.

O padrão está em todo lugar em volta de uma rede, e é por isso que a automação o encontra o tempo
todo:

| envia webhooks | quando |
|---|---|
| equipamentos e controladoras de rede | um link cai, uma configuração é salva, um limiar é ultrapassado |
| o NetBox, na aula 12 | um objeto é criado, alterado ou apagado |
| um servidor Git, na aula 14 | alguém faz push, ou um pull request é aberto |
| um sistema de monitoramento | um alerta dispara, ou é normalizado |

E o que os recebe costuma ser uma de duas coisas: **um sistema de chamados**, que transforma o
evento em trabalho para uma pessoa, ou **um pequeno programa seu**, que decide o que fazer e chama
outras APIs. Esta aula constrói o segundo, e faz ele acionar o primeiro.

Os roteadores do laboratório enviam webhooks pela sua API, a mesma que a aula 2 usou: uma
assinatura indica uma URL, uma lista de eventos e um segredo compartilhado, e daí em diante toda
mudança do estado operacional de uma interface é enviada por POST para essa URL. O sistema de
chamados é o `tickets`, a central de chamados que a seção anterior ligou; o ServiceNow,
o Jira Service Management e as centrais open source que o pessoal roda têm o mesmo formato,
chamados com números, status e comentários por trás de uma API JSON autenticada por token.

**Um receptor de webhooks é um servidor**, e isso muda quem precisa estar alcançável: o
equipamento precisa conseguir abrir uma conexão com o seu programa. No laboratório, o `ctl` escuta
em `192.0.2.10:8080`, na rede de gerência que os roteadores alcançam. Em produção isso significa
uma regra de firewall e um serviço que está sempre rodando, que é o preço de ser avisado em vez de
perguntar.
