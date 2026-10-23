---
title: Do que é feita uma suíte de BPM
version: 1
---

A imagem comum de uma ferramenta de gestão de processos de negócio é a de um programa de desenho.
Alguém desenha caixas e setas, aperta um botão, e o desenho vira software. O desenho é o que a
demonstração de vendas mostra, e é a menor parte do produto. **Uma suíte de BPM é um motor que
acompanha trabalho que dura dias, com um programa de desenho preso a ele.** O motor é aquilo de que a
Serra Alta depende todo dia, e é a parte difícil de substituir.

Esta aula é ensinada a partir de documentação e descrição, como as aulas 2 a 5. A IBM vende o produto
a empresas, por contrato, e não a uma pessoa com um cartão. Se você quiser ver as ideias rodando, os
motores de código aberto citados na próxima seção, como as edições comunitárias do Camunda e do
Flowable, podem ser baixados e iniciados num notebook. Nada na aula depende deles.

A Serra Alta roda três processos no IBM BPM 8.5 desde 2014:

- cadastro de fazenda, da primeira visita de um técnico de campo à primeira coleta da fazenda,
  cerca de 30 dias e 220 vezes por ano;
- aprovação de crédito de cliente, quando um cliente pede para pagar a prazo em vez de
  antecipado, cerca de 4 dias e 1.400 vezes por ano;
- cadastro de fornecedor, do pedido de um comprador até um registro de fornecedor no SAP, cerca
  de 12 dias e 600 vezes por ano.

O escritório de processos de Denise Okada é dono dos três processos como regras de negócio. Um
desenvolvedor, Vinícius Souza, é dono deles como software. Ele entrou no time de integração em 2014
para construí-los com dois colegas, e os dois saíram há anos.

## Sete partes vendidas como uma

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l06-suite\" aria-label=\"As partes de uma suíte de BPM, com o nome que cada parte tem no IBM BPM. À esquerda, o modelador (Process Designer), onde o processo é desenhado, salvando num repositório de versões (Process Center). Uma versão é implantada como snapshot no motor, ao centro (Process Server), que executa as instâncias, espera, chama outros sistemas e distribui o trabalho. Abaixo dele, o banco de dados próprio do motor guarda o estado, as variáveis e o histórico de cada instância. À direita, o motor entrega tarefas às pessoas por uma lista de tarefas e formulários (Process Portal e Coaches), chama o SAP, o Salesforce e o ESB por serviços de integração, e é acompanhado pelo monitoramento e pela administração (Process Admin Console).\"><defs><marker id=\"l06-suite-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-suite-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12.0\" y=\"43.0\" width=\"188.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"106.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">modelador: o processo desenhado</text><text x=\"106.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Designer</text><rect x=\"12.0\" y=\"148.0\" width=\"188.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"106.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">repositório de versões</text><text x=\"106.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Center</text><rect x=\"267.0\" y=\"133.0\" width=\"190.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">motor: executa instâncias,</text><text x=\"362.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espera, chama, distribui</text><text x=\"362.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Server</text><rect x=\"255.0\" y=\"268.0\" width=\"210.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"284.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banco próprio: estado,</text><text x=\"360.0\" y=\"299.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">variáveis, histórico</text><rect x=\"508.0\" y=\"43.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lista de tarefas e formulários</text><text x=\"608.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Portal, Coaches</text><rect x=\"508.0\" y=\"148.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">serviços de integração:</text><text x=\"608.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP, Salesforce, o ESB</text><text x=\"608.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\"></text><rect x=\"508.0\" y=\"265.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">monitoramento e administração</text><text x=\"608.0\" y=\"299.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Admin Console</text><text x=\"608.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pessoas pegam e concluem tarefas</text><path d=\"M608.0 42.0 L608.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M106.0 97.0 L106.0 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M202.0 175.0 L265.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-phosphor)\"></path><text x=\"232.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">implanta</text><text x=\"232.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snapshot</text><path d=\"M440.0 135.0 L506.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><text x=\"458.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tarefas</text><path d=\"M458.0 175.0 L506.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\"></path><text x=\"482.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chama</text><path d=\"M360.0 217.0 L360.0 266.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M440.0 215.0 L506.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path></svg>", "caption": "Uma suíte de BPM são vários produtos vendidos como um. O motor fica no meio, e o banco de dados embaixo dele guarda cada instância que já rodou.", "same": ["Process Admin Console", "Process Center", "Process Designer", "Process Portal, Coaches", "Process Server"]}
```

Desmonte a suíte e cada peça é algo que um time teria de construir de outro modo. Os nomes no produto
da IBM aparecem ao lado dos genéricos, porque são as palavras da documentação e dos runbooks da Serra
Alta.

| parte | o que faz | no IBM BPM |
| --- | --- | --- |
| modelador | onde analistas e desenvolvedores desenham o processo e ligam comportamento a cada passo | Process Designer |
| repositório | guarda cada aplicação de processo e suas versões; uma versão congelada é um *snapshot* | Process Center |
| motor | inicia instâncias, move cada uma de passo em passo, espera, distribui o trabalho, registra tudo | Process Server |
| variáveis de processo | os dados que cada instância carrega: o cliente, o valor, os documentos recebidos | declaradas no modelo, guardadas pelo motor |
| lista de tarefas | a caixa de entrada onde a pessoa encontra o trabalho que espera por ela | Process Portal |
| formulários | a tela que uma tarefa abre | Coaches |
| serviços de integração | os passos que chamam outro sistema | serviços na aplicação de processo |
| monitoramento e administração | o que está rodando, onde parou, e o conserto de uma instância quebrada | Process Admin Console |

O desenho usa BPMN, a notação que a aula 7 ensina direito. Aqui basta saber que cada caixa do desenho
é um passo. Um passo é de um de três tipos: um que uma pessoa faz (uma tarefa na lista de
alguém), um que o motor faz chamando outro sistema, ou um em que o motor decide por qual caminho
seguir.

**O motor é a parte a entender, porque todo o resto é um jeito de entrar nele ou de sair dele.**
Quando um processo começa, o motor cria uma *instância*: um pedido de crédito, uma fazenda, um
fornecedor. A instância tem uma posição no modelo e um conjunto de variáveis, e vive no banco de
dados do motor. Nada está rodando enquanto ela espera. Nenhuma thread fica bloqueada por três dias. O
motor anota o estado e acorda a instância quando algo acontece com ela: uma pessoa conclui uma
tarefa, uma chamada retorna, um timer vence.

Esse desenho tem uma consequência que o resto da aula encontra várias vezes. **Tudo o que uma
instância já fez é uma linha num banco de dados que pertence ao produto.** É assim que o motor
sobrevive a um reinício, e é também a trilha de auditoria, a evidência para os relatórios e aquilo
que você precisa levar junto se um dia for embora.

## A linhagem da IBM, e por que os nomes mudam

O produto da IBM tem dois ancestrais, e a documentação ainda mostra os dois.

| ano | o que aconteceu |
| --- | --- |
| 2009 | a IBM anuncia a compra da Lombardi Software, de Austin, no Texas, cujo produto foi feito para analistas de negócio desenharem e rodarem processos rápido |
| 2011 | a IBM lança o IBM Business Process Manager, que junta o produto da Lombardi ao seu próprio WebSphere Process Server, um runtime construído em torno de serviços SOAP e de BPEL |
| 2014 | a Serra Alta instala o IBM BPM 8.5 |
| 2018 | a IBM renomeia o produto para IBM Business Automation Workflow |

As duas metades vêm de tradições diferentes. O lado da Lombardi é o que as pessoas encontram: um
processo desenhado em BPMN, tarefas humanas, formulários e um ciclo curto entre desenhar e rodar. O
lado do Process Server veio do mundo do barramento de serviços e do BPEL, que as aulas 7 e 8
descrevem. A IBM vendia o produto em edições, e o lado do Process Server estava nas maiores. A Serra
Alta comprou a menor, então os seus três processos usam só o lado da Lombardi.

A mudança de nome importa de um jeito prático. O pessoal da Serra Alta diz "IBM BPM", os runbooks
dizem "IBM BPM", e a versão instalada é anterior ao nome novo. A documentação atual da IBM está
arquivada como Business Automation Workflow, então é esse o nome a procurar. **Quando um produto muda
de nome, aprenda os dois, e anote qual deles a documentação da sua versão usa.** A aula 5 conta a
mesma história sobre o Documentum, em que quem mudou foi o dono, e não o nome.

## Uma aprovação de crédito, acompanhada pelo motor

Uma distribuidora de Ubá, a Distribuidora Rio Pomba, quer comprar com prazo de 28 dias e limite de
R$ 240.000. O vendedor dela abre o pedido no Salesforce. Tudo o que vem depois acontece dentro do
motor, e a figura desenha isso contra o relógio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l06-credit\" aria-label=\"Uma aprovação de crédito da Serra Alta desenhada contra o tempo, do dia 0 ao dia 4, em três raias: o motor, os analistas de crédito e o CFO. No dia 0 às 09:12 um pedido vindo do Salesforce inicia a instância, e o motor busca um score de birô e os títulos em aberto no SAP em três segundos. A tarefa dos analistas fica então esperando, sem dono, por um dia e seis horas; a análise leva 25 minutos. O limite pedido é de R$ 240.000, acima de R$ 150.000, então uma tarefa vai para o CFO e espera um dia e vinte horas; ele aprova em quatro minutos. O motor grava o limite no SAP pelo ESB e avisa o vendedor. A instância viveu três dias e três horas; pessoas trabalharam nela menos de meia hora.\"><defs><marker id=\"l06-credit-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"138.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">motor</text><path d=\"M150.0 70.0 L678.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"138.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">analistas de crédito</text><path d=\"M322.9 150.0 L678.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"138.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">CFO</text><path d=\"M150.0 230.0 L321.6 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M573.7 230.0 L678.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M150.0 268.0 L678.0 268.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 264.0 L150.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 0</text><path d=\"M282.0 264.0 L282.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"282.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 1</text><path d=\"M414.0 264.0 L414.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 2</text><path d=\"M546.0 264.0 L546.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"546.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 3</text><path d=\"M678.0 264.0 L678.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 4</text><circle cx=\"150.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"162.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">09:12 pedido do Salesforce</text><text x=\"162.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">score de birô + títulos no SAP, 3 s</text><rect x=\"150.0\" y=\"140.0\" width=\"165.0\" height=\"20.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"232.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem dono: 1 dia 6 h</text><rect x=\"315.0\" y=\"136.0\" width=\"6.0\" height=\"28.0\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">análise, 25 min</text><path d=\"M321.0 164.0 L324.2 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-credit-es-ah-paper-dim)\"></path><text x=\"330.2\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 240.000 &gt; R$ 150.000</text><rect x=\"324.2\" y=\"220.0\" width=\"241.6\" height=\"20.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem dono: 1 dia 20 h</text><rect x=\"565.8\" y=\"216.0\" width=\"6.0\" height=\"28.0\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"561.8\" y=\"252.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aprova, 4 min</text><path d=\"M571.8 216.0 L572.4 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-credit-es-ah-paper-dim)\"></path><circle cx=\"572.4\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"562.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limite no SAP pelo ESB;</text><text x=\"562.4\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vendedor avisado. Fim: 3 dias 3 h</text><text x=\"360.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">pessoas trabalharam nela menos de meia hora; o motor a guardou por três dias</text></svg>", "caption": "Uma aprovação de crédito contra o relógio. Quase toda a vida dela é espera na lista de tarefas de alguém, e acompanhar a espera é o trabalho do motor.", "same": ["CFO"]}
```

1. O Salesforce chama um fluxo no barramento de integração, e o fluxo inicia uma instância do
   processo de aprovação de crédito. As variáveis da instância recebem o cliente, o prazo e o limite
   pedido.
2. O motor roda dois passos de sistema. Busca um score num birô de crédito e os títulos em aberto do
   cliente no SAP. Os dois levam três segundos.
3. O motor cria uma tarefa, "analisar pedido de crédito", e a coloca na lista de um **grupo**, os três
   analistas de crédito do financeiro, em vez de na de um deles. Ela fica ali sem dono por um dia e
   seis horas. Então um analista a pega, o que a tira das listas dos outros dois, revisa os números
   num formulário e aprova em 25 minutos.
4. O motor chega a uma decisão: limites acima de R$ 150.000 precisam do CFO. Marcos Teles recebe uma
   tarefa na própria lista. Ela espera um dia e vinte horas, e ele aprova em quatro minutos pelo
   celular.
5. O motor chama o barramento de novo, que grava o limite novo no controle de crédito do SAP, e o
   vendedor é avisado no Salesforce.

A instância viveu três dias e três horas. Pessoas trabalharam nela menos de meia hora. **Quase toda
a vida de um processo é espera, e acompanhar a espera é para isso que o motor existe.** Quem está com
a tarefa, desde quando, o que acontece se ninguém pegar: essas perguntas são o produto.

O exemplo também mostra por que o motor precisa de uma lista de tarefas em vez de uma simples
notificação. Um e-mail dizendo "favor aprovar" vai para uma pessoa e some. Uma tarefa vai para um
papel, pode ser pega e devolvida, mostra há quanto tempo espera e sobrevive às férias do Marcos,
porque o financeiro pode pôr um substituto no grupo. A lista de tarefas é o lugar onde o processo e o
organograma se encontram, e duas seções adiante esta aula mostra o que acontece quando os dois se
afastam.

## Para que serve o histórico

Quando os auditores externos da Serra Alta fazem amostragem de limites de crédito, perguntam quem
aprovou o limite de um certo cliente, quando e com base em quê. O SAP sabe dizer que o limite mudou e
por qual usuário. Esse usuário é a conta técnica do barramento de integração, que não aprovou nada.
**A resposta para "quem decidiu" vive só no histórico do motor de BPM**: o analista que pegou a
tarefa, o CFO que aprovou, o score que estava na tela quando eles aprovaram.

É por isso que um motor de processos é mais que encanamento entre o Salesforce e o SAP. Ele é o
sistema de registro das decisões tomadas por pessoas. Para o Marcos, o SAP são os livros. Para as
decisões de crédito, o motor é o livro de quem disse sim.

Duas coisas que ele não é, porque os nomes convidam à confusão. Não é um agendador de jobs: um
agendador roda um programa às 02:00, enquanto um motor mantém um caso aberto por um mês e pede coisas
a pessoas. E não é uma fila de mensagens. Uma fila leva uma mensagem de um sistema a outro e a
esquece (aula 10). Um motor lembra de cada instância até alguém apagá-la.
