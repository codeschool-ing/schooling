---
title: Cinco tipos de lock-in, e onde cada opção de computação fica
version: 1
---

Lock-in costuma ser tratado como uma coisa só, uma armadilha que o provedor monta e que uma equipe
cuidadosa evita. **São cinco coisas diferentes, cada uma comprada com algo que você queria**, e uma
opção de computação carrega algumas delas e outras não. Falar delas separadamente é o que
transforma "estamos presos ao Azure" de um humor numa lista que alguém consegue pôr preço.

## A superfície de API: o que o seu código diz

Código escrito contra a interface de um provedor precisa ser reescrito para sair dele, e este curso
escreveu bastante código assim. As funções da aula 15 são decoradas com os nomes do próprio Azure:
um gatilho de fila, um binding de saída para blob, uma configuração `AzureWebJobsStorage`. O host lê
esses decoradores e cuida das novas tentativas, da fila de poison e da escala, e nenhuma outra
plataforma os lê. O orquestrador da aula 17 é escrito contra a biblioteca do Durable Functions e
guarda seu histórico em tabelas de uma conta de armazenamento, e as regras de replay dele são as
regras dessa biblioteca. Um workflow do Logic Apps (aula 19) é um documento JSON na linguagem de
definição de workflow da Microsoft, e os conectores dele, como a conexão com o Outlook em que
alguém precisou entrar, só existem dentro do Logic Apps.

A API menos óbvia é a que fica em volta de um contêiner. A imagem da aula 7 é portável, e os
arquivos que a executam não são: o YAML do grupo de contêineres, as regras de escala e as revisões
do Container App em Bicep (aula 8), o plano, o site e o slot do App Service (aula 18). Cada um é um
formato que um serviço do Azure lê.

O que você ganha com isso é real. **Lock-in de API é o preço de um recurso gerenciado**: o gatilho,
a nova tentativa e a fila de mensagens mortas que outra pessoa escreveu e opera. Quanto mais do
trabalho a plataforma faz, mais o seu código toma a forma dela, e a aula 15 fez essa troca de
propósito.

## Os dados, e o preço de movê-los

Dados são pesados em dois sentidos. Tirá-los do Azure é cobrado por gigabyte, e movê-los leva
tempo, durante o qual duas cópias precisam ser mantidas em sincronia. Os pedidos da loja, que a
aula 21 tirou da memória e pôs num banco de dados, e os arquivos de relatório num compartilhamento
do Azure Files ficam mais pesados a cada mês que ficam.

Esse tipo pertence ao armazenamento, não à computação: o banco pesa o mesmo seja o Container Apps,
seja o AKS que o lê. O que a computação decide é o quão perto o código precisa ficar dos dados. Um
Container App em `brazilsouth` lendo um banco em `brazilsouth` não cruza fronteira nenhuma; mova o
app para outro provedor e deixe o banco, e cada consulta vira uma requisição pela internet, mais
lenta e cobrada por gigabyte na saída.

## Identidade: quem o Entra diz que você é

O código da loja não guarda segredo nenhum para a conta de armazenamento, a fila ou o registro. A
aula 15 conectou o function app com uma identidade gerenciada, e a aula 13 deixou um pod no AKS
apresentar um token do Kubernetes e receber de volta um token do Entra ID. Por trás de cada uma
dessas conexões há uma atribuição de função, o RBAC da aula 9 de `azure-foundations`, que nomeia uma
identidade que só existe no Entra.

É o arranjo mais seguro que este curso ensina, e também é uma dependência. **Sair move todas as
conexões de uma vez**: cada uma que o Entra garantia precisa ser garantida por outra coisa, ou virar
o segredo estático que a aula 13 passou uma seção inteira tirando. A aula 13 mostra onde fica a
linha. O token projetado da service account é do próprio Kubernetes e viaja com o cluster; a
credencial federada e a troca são do Entra e ficam para trás.

## Operações: o que a equipe sabe e as ferramentas que usa

Uma equipe que passou dois anos com `az`, Bicep e Azure Monitor tem um conhecimento que não viaja
inteiro. Os conceitos viajam, e é por isso que este curso os ensina pelo nome: uma regra de escala,
uma revisão, um node pool e um slot têm equivalentes em outros lugares. Os detalhes, os modos de
falha e os reflexos às três da manhã não viajam. Nem as ferramentas: os arquivos Bicep que declaram
tudo, as consultas salvas num workspace do Log Analytics, os alertas que acordam alguém.

**Lock-in operacional é o que ninguém desenha num diagrama**, e para uma equipe pequena muitas vezes
é o maior, porque uma mudança custa semanas de três pessoas aprendendo em vez de construir. Ele
também corre nas duas direções. Uma equipe de especialistas em Kubernetes a quem pedem para rodar
tudo no Functions fica trancada fora da própria experiência tanto quanto uma equipe de Functions
fica trancada dentro.

## Contratos: o que você assinou

Uma reserva ou um savings plan compra uma tarifa menor em troca de um compromisso de um ou três
anos. Uma reserva é para um recurso, um tamanho e uma região determinados; um savings plan de
computação é um gasto fixo por hora que vale para máquinas virtuais, Container Instances, Container
Apps, App Service e o plano Premium do Functions, entre outros. **É o único tipo de lock-in com data
de fim escrita**, e o único puramente financeiro: nada no código muda.

Os dois não são igualmente firmes. A documentação da Microsoft, lida em 2026-10-30, diz que um
savings plan não pode ser cancelado, reembolsado nem trocado por uma reserva. Uma reserva pode ser
trocada, ou reembolsada até um total de 50.000 USD de compromisso cancelado em doze meses corridos.
Um savings plan de três anos assinado no primeiro mês de um serviço é uma aposta de que o serviço
ainda vai gastar esse tanto em computação do Azure no trigésimo sexto.

## Onde cada opção fica

```schooling-figure
FIGURE-KINDS
```

A figura é um julgamento, não uma medição, e cada linha pode ser contestada. Um cluster AKS que se
apoia no controlador do Application Gateway da aula 14 e na workload identity tem mais lock-in de
API do que a linha dele diz; uma frota de máquinas virtuais construída a partir de uma imagem da
galeria com as extensões do Azure dentro tem mais do que a linha dela diz. O que a figura mostra é
o padrão. **Quanto mais um serviço faz por você, mais o seu código toma a forma dele**, e o
conhecimento operacional acompanha o serviço, não o código. Contratos se leem igual em toda linha
que um savings plan cobre, porque se prendem à fatura e não à plataforma. Os planos Consumption do
Functions e do Logic Apps não estão na lista da Microsoft, então essas linhas não têm nada a assinar.

Duas consequências seguem pelo resto da aula. Lock-in é um custo a pesar contra o que ele compra, ao
lado do custo de operação e do esforço de migração que a aula 21 pôs na comparação dela. E o tipo de
API pode ser reduzido num lugar, nos arquivos e no código entre as suas regras e o provedor, que é a
próxima seção.
