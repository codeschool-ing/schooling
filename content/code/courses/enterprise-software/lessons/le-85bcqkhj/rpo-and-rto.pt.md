---
title: RPO e RTO: quanto se perde e quanto tempo leva
version: 1
---

Disponibilidade trata das falhas comuns, as medidas em minutos e horas. Recuperação trata da falha
ruim: o banco de dados corrompido, o armazenamento perdido, o data center alagado. Dois números
descrevem o que o negócio aceita para esse dia, e cada sistema ganha o seu par.

| | significa | a pergunta que responde |
|---|---|---|
| RPO | objetivo de ponto de recuperação | quantos dados, medidos em tempo, podem ser perdidos? |
| RTO | objetivo de tempo de recuperação | por quanto tempo o serviço pode ficar fora? |

**O RPO olha para trás a partir da falha, e o RTO olha para a frente.** Um RPO de 15 minutos quer
dizer que o sistema recuperado pode não ter até os últimos 15 minutos de trabalho antes da falha. Um
RTO de 8 horas quer dizer que ele está de volta, utilizável, até 8 horas depois da falha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-recovery\" aria-label=\"Uma linha do tempo de uma falha do SAP. À esquerda, o último backup de log; 15 minutos depois, a falha. O trecho entre os dois é o RPO, o trabalho que pode ser perdido. A partir da falha, o RTO de 8 horas corre para a direita, dividido nas etapas da recuperação: 20 minutos para detectar, 40 para decidir, 4 horas para restaurar o banco, 1 hora para aplicar os logs, 1,5 hora para conferir e reconectar. As etapas levam 7,5 horas, meia hora dentro do objetivo.\"><defs><marker id=\"l12-recovery-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 120.0 L170.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 94.0 L70.0 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"157.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">último backup</text><text x=\"70.0\" y=\"170.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">de log</text><path d=\"M170.0 80.0 L170.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"165.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">falha</text><path d=\"M166.0 90.0 L74.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-recovery-es-ah-paper-dim)\" marker-start=\"url(#l12-recovery-es-ah-paper-dim)\"></path><text x=\"120.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RPO 15 min: trabalho</text><text x=\"120.0\" y=\"74.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">que pode ser perdido</text><rect x=\"171.0\" y=\"106.0\" width=\"18.7\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M180.3 134.0 L180.3 162.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.3\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">detectar</text><rect x=\"191.7\" y=\"106.0\" width=\"39.3\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M211.3 134.0 L211.3 178.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"211.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">decidir</text><rect x=\"233.0\" y=\"106.0\" width=\"246.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">restaurar 2.400 GB</text><rect x=\"481.0\" y=\"106.0\" width=\"60.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"511.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logs</text><rect x=\"543.0\" y=\"106.0\" width=\"91.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">conferir, religar</text><path d=\"M635.0 120.0 L700.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M635.0 100.0 L635.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"635.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">de volta em 7,5 h</text><path d=\"M666.0 80.0 L666.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M174.0 90.0 L662.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-recovery-es-ah-paper-dim)\" marker-start=\"url(#l12-recovery-es-ah-paper-dim)\"></path><text x=\"418.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RTO 8 h: até o serviço voltar a ser usável</text><text x=\"666.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">objetivo</text></svg>", "caption": "O RPO olha para trás a partir da falha, o RTO para a frente. A restauração em si é metade das oito horas. (O RPO está desenhado mais largo do que a escala.)", "same": ["logs"]}
```

## Dois erros que parecem respostas

O primeiro é ler o RPO como uma descrição dos backups. "Fazemos backup toda noite" é um mecanismo; o
RPO é a meta que o mecanismo precisa cumprir, e um backup noturno cumpre um RPO de 24 horas e nada
melhor que isso. Perguntadas sobre o que a Serra Alta poderia perder, três equipes responderam com o
horário do seu backup. **O objetivo vem do negócio e o mecanismo vem do arquiteto**, e a primeira
conversa tem de ser sobre o que o negócio aguenta perder.

O segundo é ler o RTO como o tempo que uma restauração leva. A restauração é um passo. Joana montou
os passos para o SAP com Edson, a partir de uma falha num momento comum de um dia útil:

| passo | tempo |
|---|---|
| detectar a falha e pôr as pessoas certas numa chamada | 20 min |
| decidir restaurar em vez de consertar, e qual backup usar | 40 min |
| restaurar o banco de 2.400 GB a cerca de 600 GB por hora | 4 h |
| aplicar os backups de log para chegar ao ponto mais recente | 1 h |
| conferir os dados, subir os servidores de aplicação, reconectar as integrações | 1,5 h |

São 7,5 horas contra um RTO de 8. **A restauração é metade do RTO**, e a outra metade é gente,
decisões e conferências, e nada disso anda mais rápido sob pressão.

## Os objetivos, sistema por sistema

A razão de definir o par por sistema é que sistemas merecem pares diferentes. A primeira proposta de
Joana, acertada com os responsáveis:

| sistema | RPO | RTO | o que o cumpre hoje |
|---|---|---|---|
| SAP ECC | 15 min | 8 h | backups de log a cada 15 minutos, copiados para o segundo data center; um backup completo toda noite |
| Portal B2B | 5 min | 2 h | o write-ahead log do PostgreSQL arquivado pelo menos a cada 5 minutos |
| Coleta | 0 para as coletas | 12 h | um salvamento noturno, e os coletores de mão dos caminhões, que guardam sete dias |
| Documentum | 24 h | 24 h | backups noturnos do banco de dados e dos arquivos de conteúdo |

A linha do Coleta mostra que **um RPO pertence aos dados, não só à máquina que os guarda.** O backup
do próprio Coleta é um salvamento noturno, então sozinho ele poderia perder um dia. Mas cada coleta
começou num coletor de mão que ainda a guarda, e um Coleta restaurado pode pedir aos caminhões que
mandem de novo. As coletas podem ser perdidas pelo Coleta e recuperadas da borda, o que torna o RPO
efetivo delas zero. Os ajustes manuais que os usuários do Coleta digitam durante o dia não têm cópia
assim, e para eles o RPO é mesmo de um dia.

A linha do SAP também tem um número por trás. Na hora mais movimentada o SAP recebe cerca de 200
ordens de venda. Com backups de log a cada 15 minutos, uma falha logo antes do próximo backup pode
perder 15 minutos delas, o que dá cerca de 50 ordens. Alguém vai ter de digitar cada uma de novo a
partir das mensagens de EDI, dos registros do portal e dos e-mails dos representantes.

## Quanto custa um RPO menor

O custo sobe devagar no começo e de forma íngreme perto de zero:

| RPO | o mecanismo de costume | o que custa |
|---|---|---|
| um dia | um backup noturno | armazenamento, e uma restauração que é lenta |
| minutos | backups de log frequentes ou envio de logs para outro site | um segundo site com armazenamento, e disciplina para copiar os logs |
| segundos | replicação assíncrona contínua | um segundo site com uma cópia do sistema rodando |
| zero | replicação síncrona: uma escrita só termina quando os dois sites a têm | um segundo site perto o bastante para que toda escrita espere por ele, e um caminho de escrita mais lento para sempre |

Cada degrau abaixo nessa tabela é pago todo dia, venha o desastre ou não. É por isso que o RPO é uma
decisão de negócio: alguém tem de dizer que 50 ordens de venda valem o custo do segundo site, ou que
não valem.

## A restauração que nunca foi testada

Um backup não prova nada até ser restaurado. O Documentum tinha backup toda noite desde 2010, e
ninguém o tinha restaurado desde o ano em que foi instalado.

Joana pediu uma restauração de teste num ambiente vazio. A restauração terminou, o sistema subiu e os
documentos abriram. Aí a equipe de Cláudia fez as suas conferências e encontrou 37 certificados de
laboratório cujos registros existiam mas cujos arquivos não. Um sistema de gestão de documentos
guarda os metadados num banco de dados e o conteúdo em arquivos, e a Serra Alta fazia backup dos dois
em horários diferentes: os arquivos de conteúdo às 23:00, o banco às 02:00. Todo certificado gravado
entre 23:00 e 02:00, ou seja, os resultados de laboratório do turno da noite, tinha um registro no
banco restaurado e nenhum arquivo no conteúdo restaurado. **Dois backups de um sistema, tirados em
momentos diferentes, restauram um estado que nunca existiu.** Nada nos relatórios de backup mostrava
isso, porque cada backup tinha dado certo.

A correção foi tirar os dois de um mesmo momento consistente. A descoberta valeu mais do que a
correção: o RPO real do Documentum nunca tinha sido de 24 horas para o trabalho do turno da noite, e
ninguém saberia até o dia em que os certificados fossem necessários numa auditoria.

## O RPO de uma integração

Um sistema restaurado voltou no tempo, e os sistemas em volta dele não. Suponha que o SAP seja
restaurado para um ponto 15 minutos antes da falha. Nesses 15 minutos, o barramento entregou pedidos
de EDI ao SAP e mandou às redes de supermercado as confirmações de recebimento; o SAP mandou notas
para o Salesforce e entradas de mercadoria para os relatórios do financeiro. Depois da restauração,
as redes acreditam que foram recebidos pedidos que o SAP não tem, e o Salesforce mostra notas de
documentos que não existem mais.

Por isso **toda integração que toca um sistema restaurado tem um RPO próprio**, e ele é definido pela
capacidade do outro lado de mandar de novo. As perguntas para cada uma vão para o contrato dela:

- o produtor consegue reenviar a partir de um horário, e até quanto tempo atrás? Os fluxos do
  barramento que mantêm um repositório de mensagens conseguem reproduzir; um parceiro que mandou uma
  mensagem de EDI uma vez e esqueceu dela não consegue.
- o consumidor está protegido contra receber a mesma mensagem duas vezes, já que uma reprodução a
  partir de "15 minutos antes" vai reenviar algumas que chegaram? Esse é o consumidor idempotente da
  aula 10.
- o que estava em trânsito? O IBM MQ grava as mensagens persistentes no seu log, e elas sobrevivem ao
  reinício do gerenciador de filas; as mensagens não persistentes, não. Um fluxo que manda pagamentos
  como mensagens não persistentes decidiu o seu RPO sem ninguém perceber.

Depois de qualquer restauração, vale o roteiro da seção anterior: o sistema está em modo degradado
até as integrações dele terem sido reproduzidas e conciliadas. A aula 14 leva a mesma disciplina de
conciliação para uma movimentação planejada de dados, em que há tempo para ensaiar.
