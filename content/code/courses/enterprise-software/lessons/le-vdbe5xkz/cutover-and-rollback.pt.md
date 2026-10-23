---
title: Cutover e rollback, e o ponto sem volta
version: 1
---

Cutover é o momento em que o novo sistema vira o dono dos dados e o antigo deixa de ser. Num sistema
que vai para produção várias vezes por dia, esse momento é uma release, e uma release que dá errado
é revertida publicando a versão anterior. **Uma migração de dados não se reverte publicando nada**,
porque a partir do momento em que o novo sistema recebe a primeira leitura de verdade, os dois
sistemas guardam fatos diferentes. Tudo nesta seção sai disso.

## O primeiro plano de Joana

Na fintech de onde Joana veio, uma mudança nos dados era um script de migração que rodava durante o
deploy, e se ele falhava o deploy falhava e nada tinha mudado. O primeiro plano de cutover dela para
os dados do Coleta tinha o mesmo formato: congelar o Coleta, rodar a migração, mudar os caminhões de
sistema, tudo num job só.

Sebastião fez uma pergunta na revisão: se o job falhar às três da manhã, por qual sistema as
fazendas recebem no dia 10? O plano não tinha resposta, porque um job não é um plano. **Um plano de
cutover é um runbook com horários, com um dono para cada passo, com os critérios para seguir em
frente escritos antes da noite, e com um caminho de volta que já rodou.**

## A janela

O cutover tinha de caber em algum tempo que o negócio pudesse dar, e o calendário da Serra Alta
deixava pouca escolha. Os caminhões coletam todos os dias do ano, então não há dia tranquilo, só uma
noite mais tranquila. O financeiro fecha o mês nos primeiros cinco dias úteis e o time do SAP congela
mudanças nessa semana (aula 1), então a primeira semana do mês estava fora. E as fazendas recebem no
dia 10, então quanto mais longe do próximo dia 10 o cutover ficasse, mais tempo o novo sistema teria
para se provar antes de pagar alguém.

A janela escolhida foi **de sábado 20:00 a domingo 10:00, no sábado seguinte ao pagamento de
setembro**: catorze horas, logo depois de um pagamento e o mais longe do próximo que o calendário
permitia.
Durante essas horas os caminhões continuam coletando. Os coletores guardam as leituras e as enviam
assim que um sistema estiver pronto para recebê-las, o comportamento de armazenar e reenviar que a
aula 12 descreve.

## O runbook

O runbook é uma tabela que uma pessoa cansada consegue seguir sem pensar: um horário, um passo, quem
faz, e como essa pessoa sabe que terminou.

| horário | passo | quem | pronto quando |
|---|---|---|---|
| sáb 19:45 | o Coleta escreve o último arquivo noturno para o SAP | Sebastião | o arquivo está na pasta de transferência |
| 20:00 | congelamento: o Coleta fica somente leitura, os coletores guardam as leituras | Sebastião, time do Rota | uma leitura de teste é recusada pelo Coleta |
| 20:15 | extração final: o cadastro de fazendas e as coletas do mês corrente | Sebastião | contagens da extração escritas no log |
| 20:45 | carga do delta no novo sistema | time de migração | carga terminada, rejeitos contados |
| 23:30 | reconciliação nos três níveis | Joana | cada diferença explicada por uma regra |
| 00:30 | amostras: 40 fazendas para qualidade, 40 vínculos de fornecedor | equipe de Cláudia, financeiro | as duas assinadas |
| 02:00 | integrações trocadas: coletores, Rota, o arquivo para o SAP | Rui | cada uma aponta para o novo sistema |
| 03:00 | teste de fumaça: o coletor de um caminhão envia uma leitura de teste | time do Rota | a leitura aparece no novo sistema |
| **05:00** | **go/no-go** | Regina, com Marcos | os critérios abaixo, lidos um por um |
| 05:30 | o último arquivo do Coleta entra no SAP, depois da manutenção de domingo do SAP | Edson | entradas de mercadoria lançadas |
| 06:00 | os coletores liberam as leituras guardadas | time do Rota | a contagem de guardadas chega a zero |
| 10:00 | a janela fecha | Joana | começa o hypercare |

Duas linhas ali só existem por causa do resto do parque de sistemas. O último arquivo do Coleta é
escrito antes do congelamento, porque o Coleta não vai escrever outro. E ele entra no SAP às 05:30, e
não às 02:00 de costume, porque o SAP fica em manutenção das 01:00 às 05:00 todo domingo. **Um
cutover é uma mudança em toda integração que toca o sistema**, e um runbook que lista só os passos de
dados esquece justamente os que quebram primeiro.

## Go/no-go, escrito antes da noite

A reunião de go/no-go das 05:00 é curta porque os critérios foram escritos e combinados semanas
antes, quando ninguém estava cansado e ninguém tinha passado a noite naquilo:

1. a reconciliação está limpa em todos os níveis, e toda diferença é esperada: 1.951 fazendas, as 7
   fusões, nenhum rejeito;
2. Cláudia e o financeiro assinaram as amostras;
3. a leitura do teste de fumaça chegou;
4. não passa das 08:00.

**Critério escrito na noite é critério entortado na noite.** Às cinco da manhã, depois de nove horas
de trabalho, todo mundo na sala quer que a resposta seja sim, e "a reconciliação está quase limpa"
soa como um motivo. Escrito antes, a pergunta é só se cada linha é verdadeira. Um não não é uma falha
da noite; é o plano funcionando.

O último critério é aritmética. A janela fecha às 10:00 e o rollback, medido no ensaio geral 2, leva
cerca de duas horas. Então **o último momento para decidir é 08:00**, e uma decisão não tomada até
lá é tomada assim mesmo, a favor do rollback. O runbook mira as 05:00, o que deixa três horas de
folga. Na noite, o último critério foi cumprido às 03:10, e a resposta às 05:00 foi go.

## O ponto sem volta

Voltar atrás não custa o mesmo em todo momento depois do congelamento. O custo cresce, e num certo
momento voltar deixa de ser possível em qualquer sentido útil.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l14-cutover\" aria-label=\"Uma linha do tempo do cutover com o custo de voltar atrás desenhado acima dela. A parte esquerda do eixo é a noite, do congelamento no sábado às 20:00, passando pelo go/no-go planejado às 05:00 e pela decisão mais tardia às 08:00, até o fim da janela às 10:00. Depois de um corte, a parte direita são as semanas seguintes, até o dia 9, quando sai o arquivo do banco do primeiro pagamento feito pelo novo sistema: o ponto sem volta. Acima do eixo, o custo de voltar sobe em degraus: antes do go, um rollback ensaiado de duas horas sem perder nada; depois do go, levar cada dia de leituras de volta ao Coleta, crescendo a cada dia; depois do arquivo do banco, estornar pagamentos de cerca de 1.900 fazendas, o que ninguém faria.\"><defs><marker id=\"l14-cutover-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M48.0 214.0 L334.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 207.0 L334.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M350.0 207.0 L342.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M348.0 214.0 L712.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-cutover-es-ah-paper-dim)\"></path><rect x=\"48.0\" y=\"180.0\" width=\"180.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rollback: 2 h, ensaiado</text><path d=\"M228.0 214.0 L228.0 154.0 L596.0 94.0 L596.0 214.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"470.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">levar as leituras de volta ao Coleta:</text><text x=\"470.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cerca de 4 h por dia de leituras</text><rect x=\"596.0\" y=\"42.0\" width=\"116.0\" height=\"172.0\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">estornar</text><text x=\"654.0\" y=\"77.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pagamentos</text><text x=\"654.0\" y=\"90.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">de ~1.900</text><text x=\"654.0\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fazendas</text><text x=\"24.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo de voltar atrás</text><path d=\"M48.0 210.0 L48.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sáb 20:00</text><text x=\"48.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">congelamento</text><path d=\"M228.0 210.0 L228.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">05:00</text><text x=\"228.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">go/no-go</text><path d=\"M288.0 210.0 L288.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><text x=\"288.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">decisão mais tardia</text><path d=\"M328.0 210.0 L328.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"328.0\" y=\"302.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"328.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fim da janela</text><path d=\"M596.0 210.0 L596.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"596.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia 9</text><text x=\"596.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">arquivo ao banco</text><text x=\"596.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">ponto sem volta</text><text x=\"470.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semanas de hypercare</text></svg>", "caption": "O custo de voltar cresce a cada passo do cutover. O rollback da noite é barato e ensaiado; depois que sai o primeiro pagamento do novo sistema, não há volta, só correção para a frente.", "same": ["go/no-go"]}
```

**Antes da decisão de go**, o rollback é o ensaiado: descongelar o Coleta, apontar os coletores de
volta para ele, liberar as leituras lá, e deixar a cópia do novo sistema para ser jogada fora. Duas
horas, e nada se perde.

**Depois do go, até o pagamento**, o novo sistema recebe cada leitura que os caminhões enviam. Voltar
agora significa levar essas leituras de volta ao Coleta, o que é uma migração no sentido contrário. A
Serra Alta escreveu esse procedimento e o rodou uma vez no ensaio geral 2, com um dia de leituras;
levou quatro horas. Cada dia depois do cutover acrescenta um dia de leituras para levar de volta,
então o custo cresce dia a dia, mas voltar ainda é possível.

**O primeiro pagamento do novo sistema é o ponto sem volta.** As fazendas são fornecedores no SAP
(aula 1): o novo sistema calcula quanto cada uma ganhou em setembro, os valores são lançados no SAP, e a
rodada de pagamento do SAP gera o arquivo do banco que o financeiro envia no dia 9. Depois que esse
arquivo sai, voltar ao Coleta significaria que o registro do que foi pago mora num sistema que não o
calcula mais, e desfazer isso significaria pedir a cerca de 1.900 fazendas que devolvessem o dinheiro.
Ninguém faria isso, então não é um rollback; é uma correção para a frente.

**O ponto sem volta existe quer alguém lhe dê nome ou não.** Dar nome a ele muda duas coisas. Fixa a
última data para a decisão de voltar, com as pessoas e os critérios para tomá-la: na Serra Alta, o dia
8, depois de a rodada de pagamento ter sido calculada e conferida e antes de o arquivo sair. E avisa a
todos que, dali em diante, todo problema é corrigido para a frente, então o esforço que ia para manter
o caminho de volta aberto vai para a correção.

## Um rollback é ensaiado, não escrito

Cada rollback desta seção tinha rodado antes da noite, com tempo medido: o primeiro nos dois ensaios
gerais, o segundo uma vez, com um dia de leituras. **Um rollback que só foi escrito é uma esperança
com títulos**, e a noite em que ele é necessário é a pior noite para descobrir que faltava um passo. O
rollback do ensaio geral 1 achou exatamente isso: ninguém tinha escrito como mandar as leituras
guardadas nos coletores de volta ao Coleta.
