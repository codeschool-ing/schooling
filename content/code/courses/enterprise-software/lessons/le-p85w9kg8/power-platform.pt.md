---
title: A Power Platform e as integrações que ninguém desenhou
version: 1
---

O mapa de integrações da Serra Alta feito pelo Rui Andrade mostra uns 70 fluxos no ESB, o arquivo
noturno do Coleta e o provedor de EDI. Ele está correto e está incompleto, porque a plataforma de
integração mais movimentada da empresa não está nele. **A Power Platform é uma plataforma de
integração que o pessoal da empresa usa sem a TI**, e na Serra Alta ela tem mais conexões com o SAP
do que alguns fluxos do próprio Rui.

Power Platform é o nome que a Microsoft dá a três produtos e às peças que eles compartilham:

- o Power Apps constrói formulários e aplicações pequenas, que guardam os dados no Dataverse, em
  listas do SharePoint ou numa planilha;
- o Power Automate constrói fluxos: um gatilho, como um horário, um e-mail novo ou uma linha nova,
  seguido de passos que leem e escrevem em outros sistemas. Ele se chamava Microsoft Flow até 2019;
- o Power BI constrói relatórios e painéis sobre dados que importa ou consulta.

O que eles compartilham é a parte que um arquiteto deve olhar. Há centenas de **conectores**, cada um
um cliente pronto para um serviço: Outlook, SharePoint, Excel, Salesforce, SQL Server, SAP. E há o
gateway de dados local, um serviço pequeno da Microsoft que a empresa instala dentro da própria rede
para que fluxos e relatórios na nuvem alcancem sistemas que não estão na internet. A maioria dos
planos empresariais do Microsoft 365 inclui o Power Automate com os conectores padrão; outros, entre
eles o do SAP, são premium e licenciados à parte.

Quem constrói com essas ferramentas é chamado de desenvolvedor cidadão: um analista de crédito, um
planejador numa fábrica, um controller nas finanças, construindo o que precisam sem esperar a TI. Não
há nada de ilegítimo nisso. Eles conhecem o próprio trabalho melhor do que a TI, e constroem rápido.

## O que a Joana encontrou

A Joana pediu um inventário aos administradores do Microsoft 365. O centro de administração da Power
Platform lista todo ambiente, app e fluxo, e a Microsoft publica um conjunto gratuito de ferramentas
de governança, o Center of Excellence starter kit, que transforma essas listas em relatórios. Duas
semanas depois ela tinha os números.

| o quê | quantos |
|---|---|
| fluxos construídos por funcionários e ativos | 230 |
| pessoas que são donas de pelo menos um fluxo | 61 |
| fluxos que chegam ao SAP | 38, todos por uma conexão só, como o usuário SAP `PA_FINANCEIRO` |
| destes, fluxos que escrevem no SAP | 7 |
| fluxos cujo único dono saiu da empresa | 14 |
| Power Apps | 19 |
| relatórios do Power BI atualizados pelo gateway | cerca de 140, a maioria lendo o SAP BW |

O fluxo que deu concretude aos números é da Priscila Rocha, uma analista de crédito. Todo dia útil às
sete ele chama o SAP pelo conector e lê os títulos a receber vencidos há mais de dez dias. Agrupa-os
por vendedor, posta um resumo no canal do Teams do time de crédito e acrescenta uma linha por cliente
numa pasta de trabalho do Excel no SharePoint, que o comitê de crédito lê às quintas. Ele roda toda
manhã desde 2023. **É uma integração em todos os sentidos que a aula 9 vai usar**: uma extração
agendada do ERP, uma transformação e dois destinos. Não tem dono na TI, não tem monitoramento e não
tem lugar no mapa do Rui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-shadow\" aria-label=\"As integrações da Serra Alta em dois tipos de linha. Contínuas, as que estão no mapa do Rui: Salesforce, o Portal B2B e o provedor de EDI ligados ao ESB (IIB e MQ, uns 70 fluxos), o ESB ligado ao SAP ECC, o Coleta mandando ao SAP um arquivo noturno, e o SAP extraindo para o SAP BW. Tracejadas e em âmbar, as que o inventário achou: 230 fluxos de funcionários no Power Automate, 38 deles chegando ao SAP como o usuário único PA_FINANCEIRO, outros escrevendo no Teams, no SharePoint e no Excel; e cerca de 140 relatórios do Power BI lendo o SAP BW pelo gateway.\"><defs><marker id=\"l03-shadow-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-shadow-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20.0 26.0 L50.0 26.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"58.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no mapa do Rui</text><path d=\"M20.0 48.0 L50.0 48.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"58.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">achadas no inventário</text><rect x=\"220.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce</text><path d=\"M280.0 52.0 L364.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"360.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M420.0 52.0 L420.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor de EDI</text><path d=\"M560.0 52.0 L476.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"335.0\" y=\"94.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ESB: IIB + MQ, ~70 fluxos</text><path d=\"M420.0 130.0 L420.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"350.0\" y=\"186.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"90.0\" y=\"186.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><path d=\"M210.0 205.0 L348.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-shadow-es-ah-paper-dim)\"></path><text x=\"279.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivo noturno</text><rect x=\"575.0\" y=\"186.0\" width=\"110.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP BW</text><path d=\"M490.0 205.0 L573.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-shadow-es-ah-paper-dim)\"></path><rect x=\"90.0\" y=\"308.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Power Automate</text><text x=\"170.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">230 fluxos de funcionários</text><rect x=\"335.0\" y=\"308.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Teams, SharePoint,</text><text x=\"420.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Excel</text><rect x=\"570.0\" y=\"308.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Power BI</text><text x=\"630.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~140 relatórios</text><path d=\"M210.0 307.0 L380.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><text x=\"205.0\" y=\"262.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">38 fluxos, um usuário:</text><text x=\"205.0\" y=\"277.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PA_FINANCEIRO</text><path d=\"M251.0 330.0 L333.0 330.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><path d=\"M630.0 307.0 L630.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><text x=\"638.0\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pelo gateway</text></svg>", "caption": "O mapa oficial, e o que o inventário desenhou por cima. As linhas tracejadas carregam dados da empresa todo dia, e nenhuma tinha dono na TI.", "same": ["Coleta", "Excel", "Portal B2B", "Power Automate", "Power BI", "SAP BW", "SAP ECC", "Salesforce", "Teams, SharePoint,"]}
```

## O primeiro movimento errado

O primeiro rascunho da Joana era uma política: bloquear o conector do SAP e mandar tudo o que tocasse
no SAP pelo ESB, onde pudesse ser visto. Era arrumado, e era o que a fintech dela teria feito.

A Regina fez uma pergunta antes de assinar: o que para na manhã em que a política entrar em vigor? A
resposta era 38 fluxos. Entre eles estavam a lista matinal da Priscila, um fluxo que manda a cada
gerente de fábrica a captação de leite do dia anterior até as 6h30, e os sete que escrevem. Um destes
atualiza limites de crédito de clientes a partir das decisões que o comitê de crédito registra na
pasta de trabalho, e ninguém na TI sabia que ele existia. Bloqueado, ele teria congelado cada limite
onde estava, e os pedidos começariam a parar na checagem de crédito sem que ninguém soubesse dizer
por quê.

A Joana retirou o rascunho. **Bloquear o que as pessoas construíram não é governança; é quebrar um
trabalho que você ainda não entendeu.** Quem tivesse o trabalho quebrado o reconstruiria na semana
seguinte em macros do Excel, que não têm inventário nenhum.

## As ferramentas de que a governança é feita

A Power Platform dá a seus administradores quatro ferramentas, e o projeto de um arquiteto aqui é
sobretudo uma decisão sobre como usá-las.

A primeira são os ambientes. Um ambiente é um contêiner de apps, fluxos, conexões e dados do
Dataverse, com a própria lista de quem pode construir nele. Todo tenant tem um ambiente padrão, e por
padrão todo mundo com licença pode construir nele, que é onde estavam todos os 230 fluxos da Serra
Alta. Dá para criar outros ambientes com uma lista restrita de criadores, para que um fluxo de que o
negócio depende rode num lugar onde ninguém o edite por acidente.

A segunda são as políticas de prevenção de perda de dados. Uma política de DLP separa os conectores
em três grupos: Business, Non-business e Blocked. Um app ou um fluxo pode usar conectores do grupo
Business ou do grupo Non-business, mas não dos dois, e não pode usar um bloqueado. A política vale
para ambientes escolhidos ou para o tenant inteiro. Ponha SAP, SharePoint e Salesforce em Business e
um conector pessoal de Dropbox ou Gmail em Non-business, e **um fluxo deixa de conseguir copiar títulos
do SAP para o armazenamento pessoal de alguém, sem que ninguém bloqueie o SAP.**

A terceira é a propriedade. Um fluxo pertence a quem o fez, e as conexões dele agem com as
credenciais de quem as criou. Desative a conta dessa pessoa e essas conexões param de funcionar, e o
fluxo falha na próxima execução. Fluxos podem ter coproprietários, e conexões podem ser criadas com
contas que pertencem a um time em vez de a uma pessoa. Dos 14 fluxos cujo dono tinha saído, nove já
tinham parado sem que ninguém percebesse quais; cinco ainda rodavam, porque as conexões deles tinham
sido feitas com contas compartilhadas, e não com a do próprio dono.

A quarta é o próprio inventário. O centro de administração e o starter kit respondem o que existe e
de quem é. Rodado todo mês, o mesmo relatório mostra cada fluxo novo que chega ao SAP antes que alguém
passe a depender dele.

## Três níveis, decididos pela consequência

O que a Joana propôs no lugar, e a Regina aprovou, separa os fluxos pelo que acontece quando falham,
e não por quem os escreveu.

| nível | o que põe um fluxo ali | o que ele recebe |
|---|---|---|
| pessoal | serve a quem o fez: o e-mail, a agenda, os arquivos dessa pessoa | o ambiente padrão, sem revisão |
| de time | um time depende dele, ou ele lê dados do negócio | um coproprietário, só conectores Business, uma entrada no inventário |
| crítico para o negócio | escreve no ERP, ou o trabalho de alguém para quando ele falha | um ambiente gerenciado, um time dono, uma identidade de conexão própria, alertas de falha que chegam ao time do Rui; ou uma reconstrução como integração oficial |

A linha que faz a maior parte do trabalho é a primeira condição da última linha. **Um fluxo que
escreve no ERP é uma integração, seja quem for que o construiu**, e recebe o que toda integração
recebe: um dono que não é uma pessoa só, monitoramento e um lugar no mapa. Os sete fluxos que
escrevem foram para um ambiente gerenciado naquele trimestre. O fluxo da Priscila continuou dela, no
nível de time, com a gestora dela como coproprietária.

## Um usuário para 38 fluxos

A conexão única com o SAP é o tipo de atalho que parece inofensivo. Cada um dos 38 fluxos age no SAP como `PA_FINANCEIRO`. O SAP registra quem criou e quem
alterou cada documento, e para tudo o que esses fluxos fizeram ele registra esse usuário. Quando um
limite de crédito mudou em maio, o SAP sabia dizer que foi `PA_FINANCEIRO`; não sabia dizer qual dos
sete fluxos que escrevem fez a mudança, nem por decisão de quem. **Uma conta de serviço compartilhada
transforma uma trilha de auditoria numa lista de coisas que aconteceram.**

A senha era conhecida por quatro pessoas, duas das quais tinham mudado de departamento. A correção é
sem graça e específica: um usuário SAP por time dono, somente leitura para os 31 fluxos que só leem, e
os sete que escrevem levados para identidades próprias no ambiente gerenciado. Como o SAP licencia o
acesso de outros sistemas por uma conta assim é a questão do acesso indireto da aula 1, e a aula 2
diz como o SAP cobra isso hoje.

## O Power BI e o número na pauta do conselho

O Power BI é o mais quieto dos três, porque um relatório não escreve em lugar nenhum. Mesmo assim ele
depende de uma cadeia: o SAP BW, o gateway, uma atualização agendada, um dataset e um painel. Em março
o servidor do gateway foi reiniciado para aplicar patches e o serviço do gateway não subiu de novo.
Por onze dias, o painel financeiro da pauta do conselho mostrou os números de fevereiro. O horário da
última atualização estava impresso num canto da página, e ninguém olhou.

As falhas de atualização vinham sendo mandadas por e-mail, o tempo todo, ao analista que construiu o
relatório em 2022, que tinha mudado de função dentro da empresa. Agora elas vão para o time do Rui, e
o gateway está na lista de servidores que esse time monitora.
