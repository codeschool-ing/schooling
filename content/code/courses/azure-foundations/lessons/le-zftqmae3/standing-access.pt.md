---
title: Acesso permanente, e a alternativa
version: 1
---

**As atribuições da lição 9 são acesso permanente: a partir do momento em que uma é feita, a
entidade tem o papel em todo segundo de todo dia, até alguém removê-la.** Para Reader numa assinatura
de testes, tudo bem. Para Owner em produção, quer dizer que a credencial mais poderosa da empresa está
ligada às três da manhã de um domingo, enquanto quem a tem dorme, num navegador com uma dúzia de
outras abas abertas. Uma sessão roubada, uma página de phishing ou um comando digitado no terminal
errado encontram esse poder à espera.

O conserto errado é o primeiro a que as pessoas recorrem: tirar o papel, e devolvê-lo à mão quando
alguém precisar. Funciona por uma semana. Depois a pessoa que devolve papéis está de férias, o
incidente é agora, o papel é devolvido "só por hoje" e nunca removido, e a empresa tem acesso
permanente de novo, sem registro de por quê.

O **Privileged Identity Management**, PIM, é o recurso do Microsoft Entra ID que torna a alternativa
rotina. Ele é descrito aqui a partir da documentação da Microsoft, e **nada nesta seção foi
executado**: o PIM é um serviço de um tenant real, e precisa de licença, Microsoft Entra ID P2 ou
Microsoft Entra ID Governance, para as pessoas que cobre.

## Elegível e ativa

O PIM acrescenta uma palavra a uma atribuição de papel: o **tipo**. A documentação da Microsoft
define dois:

- **uma atribuição ativa** dá o papel agora, sem nada a fazer antes. É a atribuição da lição 9, com
  nome;
- **uma atribuição elegível** não dá nada ainda. Ela dá o direito de **ativar** o papel: pedi-lo,
  provar quem você é, dizer por quê, e então tê-lo por um tempo limitado.

**Não há diferença no que o papel permite depois de ativo.** Um Owner que ativou uma atribuição
elegível é exatamente tão poderoso, naquelas horas, quanto um com atribuição permanente. O que muda é
o número de horas, e o fato de cada uma delas ter sido pedida, com nome, com motivo, e registrada.

## Permanente e com prazo

Cada tipo tem também uma **duração**, que é uma pergunta diferente de quanto tempo dura uma ativação:

| | permanente | com prazo |
|---|---|---|
| **elegível** | pode ativar a qualquer momento, enquanto a atribuição existir | só pode ativar entre uma data de início e uma de fim |
| **ativa** | tem o papel sempre: acesso permanente | tem o papel entre uma data de início e uma de fim |

**A elegibilidade com prazo é o formato a buscar.** `ana` é elegível a Owner no `rg-shop-prod` por
seis meses, e nesses seis meses o ativa por algumas horas quando o trabalho pede. Quando os seis
meses acabam, a elegibilidade acaba com eles, e renová-la é uma decisão que alguém toma de novo, em
vez de um papel que ninguém lembra de ter concedido. Uma atribuição ativa permanente é a exceção,
guardada para as identidades que não conseguem pedir: as contas de emergência da lição 11, e as
identidades de carga de trabalho, que não têm pessoa para responder a um aviso.

## O que o PIM cobre

O PIM gerencia três tipos de papel, e vale mantê-los separados porque os dois primeiros moram em
lugares diferentes:

- papéis de recursos do Azure: os papéis da lição 9, Owner, Contributor e os demais, no escopo de
  um grupo de gerenciamento, uma assinatura, um grupo de recursos ou um recurso. Eles são julgados
  pelo Resource Manager;
- papéis do Microsoft Entra: os papéis do próprio diretório, como Global Administrator, User
  Administrator e Privileged Role Administrator. Eles governam o tenant, não os recursos do Azure, e
  a lição 6 os apresentou;
- grupos: a participação num grupo, ou a propriedade dele, tornada elegível. Um grupo que tem
  vários papéis vira uma coisa só a ativar.

**Um papel do Entra alcança o Azure por conta própria, e vale conhecê-lo pelo nome.** Um Global
Administrator pode ligar *Access management for Azure resources* nas propriedades do tenant, e daí
em diante tem User Access Administrator no escopo raiz, `/`: toda assinatura em todo grupo de
gerenciamento, com o poder de se dar qualquer papel ali. A Microsoft documenta isso como o caminho de
volta quando ninguém mais consegue administrar uma assinatura. É também uma porta, então é desligado
de novo assim que o trabalho termina, e uma ativação de Global Administrator pelo PIM é o momento
natural de perceber que ele foi usado.
