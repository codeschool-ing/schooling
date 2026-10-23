---
title: Estado que vive um mês
version: 1
---

Um engenheiro que já construiu serviços web pensa no trabalho como uma requisição: ela chega, é
tratada, uma resposta volta, e nada dela fica na memória. Joana chegou à Serra Alta pensando nos
processos desse jeito, como uma requisição que por acaso é lenta. **Uma instância de processo não é
uma requisição lenta. É um registro que sobrevive a deploys, reinícios, reorganizações e ao próprio
modelo a partir do qual foi iniciada.** Quase tudo o que dá errado com um motor de processos vem dessa
diferença.

## Uma fazenda leva um mês para entrar

O cadastro de fazenda na Serra Alta começa quando um técnico de campo visita um produtor que quer
vender leite. Depois a instância espera coisas que acontecem na velocidade de uma fazenda, não de um
computador:

1. o produtor manda os documentos: inscrição fiscal, dados bancários, os atestados sanitários do
   rebanho;
2. a equipe da qualidade visita a fazenda para inspecionar a ordenha e o tanque de resfriamento;
3. o laboratório analisa uma primeira amostra do leite;
4. o produtor assina o contrato de fornecimento;
5. a fazenda é criada como fornecedor no SAP, já que a Serra Alta paga a ela (aula 1), e digitada
   no Coleta para que os caminhões passem a coletar ali.

A instância mediana leva cerca de 30 dias. Algumas levam três meses, porque os atestados do produtor
tinham vencido ou o contrato foi e voltou. Durante esses dias o motor passa por deploys, os
servidores recebem patches e são reiniciados, as pessoas tiram férias, e o próprio processo pode
mudar. A instância precisa atravessar tudo isso com a posição e as variáveis intactas, e é por isso
que ela vive no banco de dados do motor e não na memória de algum programa.

## Quantas deveriam estar abertas

Existe uma verificação simples de que um motor está saudável, e vale fazê-la no primeiro dia em que
você responder por um. **O número de instâncias abertas num dado momento é o número iniciado por dia
multiplicado por quanto cada uma dura.** É a lei de Little, publicada por John Little em 1961, e ela
vale para qualquer sistema em que as coisas chegam, ficam um tempo e saem.

Para os três processos da Serra Alta:

| processo | iniciados por ano | dura | abertos esperados |
| --- | --- | --- | --- |
| cadastro de fazenda | 220 | 30 dias | 220 × 30 / 365 = 18 |
| aprovação de crédito | 1.400 | 4 dias | 1.400 × 4 / 365 = 15 |
| cadastro de fornecedor | 600 | 12 dias | 600 × 12 / 365 = 20 |
| os três | | | cerca de 53 |

Joana abriu o console de administração no segundo mês e perguntou quantas instâncias estavam
ativas. A resposta foi **1.986**. Ou a conta estava errada por um fator de mais de trinta, ou a
maioria dessas instâncias não estava viva em nenhum sentido que importasse. Era a segunda opção.
Vinícius passou dois dias separando-as:

- 61 eram trabalho real em andamento, perto o bastante das 53 que a tabela prevê;
- 1.610 eram instâncias de cadastro de fazenda cujas fazendas já entregavam leite havia anos;
- 315 eram cadastros de fornecedor que tinham parado num erro no último passo.

As duas próximas partes desta seção explicam as 1.610 e as 315. Foi a conta que as encontrou. Nada no
produto tinha reclamado.

## A tarefa que ninguém pega

As 1.610 vieram de um ramo paralelo. Quando uma fazenda é criada, o modelo de 2014 também manda uma
tarefa a um grupo chamado *Fomento leiteiro*, a equipe de desenvolvimento de campo, para marcar uma
visita de acompanhamento aos 90 dias. A instância só termina quando os dois ramos terminam. Em 2019
essa equipe foi incorporada à da qualidade, os membros foram para outros grupos, e a visita de
acompanhamento passou a ser agendada pelo Rota. Ninguém mudou o processo. **Desde 2019, todo cadastro
de fazenda termina o trabalho de verdade e depois espera, para sempre, por uma tarefa na lista de um
grupo sem membros.**

Ninguém percebeu porque não faltava nada. As fazendas eram coletadas e pagas. As visitas aconteciam,
marcadas em outro lugar. O único sintoma era um número que ninguém olhava.

Essa é a falha mais comum de um motor de processos, e tem a mesma raiz toda vez. As tarefas vão para
papéis e grupos para que o trabalho sobreviva à saída de uma pessoa. Isso quer dizer que o processo
depende do organograma, e o organograma muda sem que ninguém abra o designer de processos. As
defesas são baratas:

- acompanhe a idade da tarefa aberta mais antiga de cada grupo, e alerte quando ela passar do que o
  processo permite;
- trate um grupo com tarefas e sem membros como um erro, não como um estado silencioso;
- dê um prazo a toda tarefa humana, para que esperar demais seja um evento que o modelo trata. A
  aula 7 desenha esses timers; no modelo de 2014 da Serra Alta a visita da qualidade não tem nenhum,
  então uma visita que ninguém agenda espera indefinidamente.

## A chamada que falhou num domingo

Os 315 cadastros de fornecedor tinham falhado no último passo, a chamada que cria o registro de
fornecedor no SAP. A maioria das falhas tinha horário entre 01:00 e 05:00 de um domingo, que é a
janela semanal de manutenção do SAP (aula 1): um comprador terminava o cadastro no sábado à noite, o
motor chamava o SAP enquanto ele estava fora do ar, e a chamada falhava. A instância ia para um estado
de falha e esperava alguém repeti-la pelo console de administração. Ninguém repetia. Na segunda, o
comprador, sem ver o fornecedor no SAP, o criava à mão.

Então, para 315 fornecedores, o histórico do BPM diz "não cadastrado" e o SAP diz o contrário, e a
trilha de aprovação que o processo foi feito para guardar aponta para um registro de fornecedor que
ele nunca criou. A falha foi silenciosa no motor e invisível no SAP. **Um passo de integração dentro
de um processo precisa de uma política de nova tentativa que conheça o calendário do outro sistema**,
e de alguém cujo trabalho seja olhar as instâncias que esgotaram as tentativas. A aula 12 volta às
janelas de manutenção como parte de um contrato entre sistemas.

## Mudar o processo com instâncias rodando

Em 2023 a Serra Alta decidiu que uma fazenda nova precisa apresentar a inscrição no CAR, o Cadastro
Ambiental Rural, antes da primeira coleta. O escritório da Denise pediu um passo novo no cadastro de
fazenda. A mudança em si era pequena. A pergunta que ela levantou não era: o que acontece com as 18
fazendas que já estão no meio do caminho?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-versions\" aria-label=\"Instâncias de cadastro de fazenda desenhadas como barras ao longo de seis meses, de janeiro a junho. A versão 1 do processo, o modelo de 2014, executa toda instância iniciada antes de 1º de março. Em 1º de março a versão 2 é implantada, e toda instância iniciada depois disso roda nela. Três instâncias da versão 1, iniciadas em janeiro e fevereiro, simplesmente terminam na versão 1, lado a lado com as da versão 2. Uma quarta é migrada para a versão 2 em 1º de março, e a pergunta na migração é onde fica o passo em que ela está no modelo novo; se a versão 2 apagou o passo em que ela esperava, a instância fica sem onde pisar.\"><defs><marker id=\"l06-versions-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M150.0 268.0 L702.0 268.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 264.0 L150.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"196.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">jan</text><path d=\"M242.0 264.0 L242.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fev</text><path d=\"M334.0 264.0 L334.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mar</text><path d=\"M426.0 264.0 L426.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"472.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abr</text><path d=\"M518.0 264.0 L518.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"564.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mai</text><path d=\"M610.0 264.0 L610.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"656.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">jun</text><text x=\"70.0\" y=\"97.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão 1</text><text x=\"70.0\" y=\"112.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">(modelo de 2014)</text><text x=\"70.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão 2</text><path d=\"M334.0 30.0 L334.0 74.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 96.0 L334.0 99.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 121.0 L334.0 189.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 211.0 L334.0 264.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"334.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1º de março: versão 2 implantada</text><rect x=\"177.6\" y=\"52.0\" width=\"101.2\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"251.2\" y=\"77.0\" width=\"105.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"301.8\" y=\"102.0\" width=\"105.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"320.2\" y=\"132.0\" width=\"13.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"415.6\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">começaram na versão 1,</text><text x=\"415.6\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">terminam na versão 1</text><rect x=\"334.0\" y=\"192.0\" width=\"87.4\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><path d=\"M336.0 148.0 L336.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-versions-es-ah-amber)\"></path><text x=\"344.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">migrada: em que passo da versão 2 ela está agora?</text><rect x=\"347.8\" y=\"217.0\" width=\"96.6\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"462.8\" y=\"217.0\" width=\"101.2\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"554.8\" y=\"237.0\" width=\"110.4\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">as duas versões rodam juntas enquanto a instância mais antiga viver</text></svg>", "caption": "Implantar uma versão nova não move as instâncias que já estão rodando. Elas terminam no modelo em que começaram, a não ser que alguém as migre e responda à pergunta da seta."}
```

Os motores de processos respondem a ela do mesmo jeito, em princípio. Uma versão nova do modelo é
implantada ao lado da antiga, e **cada instância continua rodando na versão em que começou**, a não
ser que alguém a mova de propósito. A versão 1 e a versão 2 rodam lado a lado até a última instância
da versão 1 terminar. No cadastro de fazenda isso leva cerca de um mês. Num processo cujas instâncias
duram um ano, há sempre duas ou três versões vivas ao mesmo tempo.

Há dois jeitos de lidar com as instâncias em andamento.

**Deixar escoar.** As 18 fazendas terminam na versão 1, sem o passo do CAR, e alguém junta as 18
inscrições à mão. É o padrão seguro quando a versão antiga ainda está correta o bastante e as
instâncias são poucas.

**Migrar.** O motor move cada instância para a versão 2. Isso significa responder, para cada passo em
que uma instância poderia estar esperando, onde ela fica no modelo novo. Se a versão 2 ainda tem o
passo, a resposta é fácil. Se a versão 2 apagou ou fundiu o passo, a instância fica sem onde pisar. A
documentação da IBM chama o marcador da posição de uma instância de *token*, e um token deixado num
passo que não existe mais de *orphaned token* (token órfão). A ferramenta de migração deixa você mover
esses tokens para outro passo ou apagá-los, e alguém precisa decidir qual, passo a passo. As
variáveis levantam a mesma pergunta: a versão 2 espera um número de CAR, e uma instância migrada não
tem um.

**Toda mudança num processo em execução tem duas populações, as instâncias que virão e as que estão
em andamento, e a mudança não está desenhada enquanto as duas não tiverem resposta.** A Serra Alta
deixou escoar, e foi a decisão certa. Ela também deixou passar algo que a contagem acima torna óbvio agora. A versão 2 manteve o ramo que manda uma tarefa ao *Fomento leiteiro*, quatro anos depois de o
grupo ter sido esvaziado. Quem mudou o processo olhou para o passo que estava acrescentando e
não para os que já estavam lá.

## O segundo banco de dados de que ninguém tira relatório

O banco de dados do motor guarda mais que posições. Cada instância carrega as suas variáveis, e cada
passo concluído deixa um histórico: quem o pegou, quando, o que o formulário dizia quando a pessoa
apertou o botão. Na aprovação de crédito, esse é o único registro de quem decidiu cada limite, que é o
que os auditores pedem. No cadastro de fazenda, é a data em que o atestado sanitário de cada fazenda
foi conferido, e por quem.

Isso faz do motor **um segundo banco de dados de fatos de negócio, e ninguém o trata como tal**. Os
dados do SAP são copiados toda noite para o data warehouse, e o financeiro tira relatórios deles. Os
dados do motor não são copiados para lugar nenhum. As tabelas dele são o funcionamento interno do
produto, e não uma interface que o fornecedor promete manter, então ninguém construiu relatórios
sobre elas, e o único jeito de responder à pergunta de um auditor é pedir ao Vinícius que procure.

Daí vêm três consequências. Relatórios sobre os próprios processos (quanto tempo leva uma aprovação de
crédito, qual passo do cadastro é o mais lento) precisam de uma exportação que a empresa construa de
propósito, e a Serra Alta não tem nenhuma. O histórico é evidência, então cai nas regras de retenção
que a aula 5 descreveu para registros. E, quando a suíte for aposentada, o histórico precisa ser
levado para algum lugar onde uma pessoa ainda consiga lê-lo, o que é uma migração por si só (aula 14).
