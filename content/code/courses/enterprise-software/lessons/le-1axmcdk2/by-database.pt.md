---
title: Por banco de dados, e o que custa dividir tabelas
version: 1
---

A integração mais tentadora de qualquer empresa é a que não precisa da permissão de ninguém. Os
dados já estão num banco, o banco aceita conexões, e uma consulta leva dez minutos para escrever.
Nenhum leiaute de arquivo para combinar, nenhum serviço para pedir, nenhum fluxo de ESB para esperar.
**Ler as tabelas de outro sistema parece a integração mais simples que existe, e é aquela cujo custo
chega por último e maior.**

Hohpe e Woolf descrevem o banco compartilhado como um desenho: várias aplicações combinam um esquema
e todas o usam, então nunca há dado para mover. Essa versão é rara, porque combinar um esquema entre
um sistema financeiro, um CRM e um roteirizador é mais difícil do que mover dados entre eles. O que o
mapa da Joana encontrou foram 17 vínculos por banco em dois disfarces: 5 tabelas de integração, e 12
lugares onde um sistema simplesmente lê as tabelas de outro, 7 deles relatórios.

## A tabela de integração

O Rota usa uma tabela para dizer ao SAP quais viagens os caminhões contratados fizeram, para que o
SAP pague os donos deles. O Rota grava cada viagem encerrada como uma linha num pequeno banco SQL
Server, com status `N` de novo. A cada cinco minutos um job ABAP se conecta a esse banco, lê as
linhas `N`, registra cada viagem no SAP para pagamento, e muda o status para `P` de processado, ou
`E` com uma mensagem se o SAP recusou.

É um desenho razoável, e vale ver por quê: **uma tabela de integração é uma fila construída com uma
tabela**. O Rota não precisa do SAP no ar quando um caminhão volta; a viagem espera na tabela. O formato é uma tabela que os dois times desenharam juntos para isso, então o modelo interno
de nenhum dos lados vaza para ela. Está mais perto de um arquivo ou de uma mensagem do que de ler as
tabelas de alguém.

Também tem os problemas de uma fila sem as ferramentas de uma fila, e o mapa achou todos:

- **Ninguém olha as linhas com erro.** Na manhã em que a Joana olhou, 37 linhas estavam com status
  `E`, a mais velha com nove dias. Cada uma era uma viagem pela qual alguém esperava ser pago.
- **Consultar de tempos em tempos é latência e carga.** A cada cinco minutos, chegue algo ou não, o
  job consulta a tabela; e uma viagem encerrada às 10:01 espera até 10:05.
- **Dois escritores atualizam a mesma linha.** O Rota ainda pode corrigir uma viagem que o job está
  lendo, e a coluna de status é a única coisa entre eles. Um job que cai entre registrar a viagem no
  SAP e marcar `P` registra a mesma viagem de novo na execução seguinte, que é a carga dupla da seção anterior
  em outra forma.

Um broker dá filas de erro, alarmes de profundidade e entrega sem consulta periódica, e a aula 10
trata do que ele faz. Uma tabela de integração é o que se constrói quando não há broker, ou quando
ninguém pensou em usar o que existe.

## Só ler a tabela deles

O segundo disfarce não tem desenho nenhum. O Rota, o roteirizador, precisa conhecer todos os produtores: onde ficam e em que dias são
coletados. Esses dados vivem no Coleta,
em IBM i, então quando o Rota foi construído em 2022 o time se conectou ao banco do Coleta por ODBC e
passou a ler a tabela de produtores direto, toda noite às 21:00. Levou um dia para fazer.

Em 2023 o Sebastião acrescentou coordenadas de GPS ao cadastro de produtores e, para isso, dividiu o
campo de endereço em dois. **Nada avisou o Rota.** No domingo à noite depois da mudança, a consulta do
Rota falhou, o plano de rotas não saiu, e os despachantes montaram à mão as 140 rotas de caminhão da
segunda-feira, a partir da impressão da semana anterior.

Essa é a falha na forma barulhenta, e foi a de sorte. A forma silenciosa é uma mudança de
*significado* sem mudança de forma. Se o Coleta passasse a marcar um produtor suspenso com um valor
novo de status em vez de apagá-lo, a consulta do Rota continuaria rodando, devolvendo linhas e
mandando caminhões a uma fazenda que parou de fornecer. **Ler uma tabela acopla você a tudo o que o
dono quer dizer com ela, inclusive ao que ele decidir que ela significa no ano que vem**, e ele não
sabe que você está ali.

Três custos vêm com toda leitura direta:

1. **O esquema vira uma interface que ninguém combinou.** O dono não consegue mudar uma coluna sem
   quebrar alguém de quem nunca ouviu falar, então depois de alguns anos ninguém muda nada, e o
   desenho do sistema congela em volta de leitores que ele nunca escolheu.
2. **A carga e os bloqueios são problema do dono.** Um relatório que varre um ano de dados de coleta
   roda no mesmo banco em que os técnicos de laboratório digitam resultados de análise. Na Serra Alta
   um relatório assim, atualizado toda manhã às 07:00, deixou as telas do Coleta lentas por vinte
   minutos por dia durante um ano antes que alguém ligasse uma coisa à outra.
3. **As regras são puladas.** Ler pula a visão que a aplicação tem dos dados: o que ela filtra,
   corrige ou combina antes de mostrar. Gravar pula toda a validação, e é por isso que nenhum sistema
   deveria jamais gravar nas tabelas de outro.

## Por que as tabelas do SAP estão fora de alcance

Cada um desses custos é maior com um ERP. As tabelas do SAP são feitas para os programas do próprio
SAP, com significados espalhados pela configuração: se uma linha de uma tabela conta como partida em
aberto pode depender de parâmetros em três outras tabelas. A aula 1 contou a história do acesso
indireto e da disputa de licenciamento por trás dela, e a aula 2 mostra os caminhos de entrada
suportados. Aqui o ponto é o de arquitetura.

**O fornecedor muda as tabelas quando atualiza, e você não vota.** A Serra Alta precisa sair do ECC
até o fim de 2027. O S/4HANA levou os documentos de material, que o ECC guardava numa tabela de
cabeçalho e numa de itens, para uma única tabela nova, a `MATDOC`, e mantém os nomes antigos só como
views de compatibilidade. Um relatório que lia as tabelas antigas direto passa a ler views que a SAP
manteve para que programas antigos não quebrassem, e quanto tempo uma view de compatibilidade dura é
decisão da SAP. **Toda leitura direta das tabelas do SAP é uma linha no plano de migração**, e o mapa
da Joana achou sete: dois relatórios de Power BI, quatro programas ABAP em ambientes de outros
sistemas, e uma pasta de Excel com conexão ao banco que o financeiro atualiza toda segunda-feira.

A primeira proposta da Joana na Serra Alta, na aula 1, foi uma leitura direta exatamente desse tipo:
o Portal B2B lendo as tabelas de estoque do SAP a partir de uma réplica de leitura. Uma réplica
resolve o segundo custo, a carga, e deixa o primeiro e o terceiro onde estavam.

## Captura de dados de mudança

Existe uma variante moderna que mantém o que é bom em ler o banco e tira parte do que é ruim: a
**captura de dados de mudança**, CDC, de *change data capture*. Em vez de consultar as tabelas, uma
ferramenta de CDC lê o próprio registro de mudanças do banco, aquele que ele grava para se recuperar:
o write-ahead log no PostgreSQL, o binary log no MySQL, o journal no IBM i. Todo insert, update e
delete confirmado sai do registro na ordem de commit, e a ferramenta publica cada um como uma
mensagem.

O Debezium é o exemplo de código aberto que a maioria encontra. Ele lê o registro de um PostgreSQL,
MySQL, SQL Server ou de vários outros bancos e publica cada mudança de linha como um evento,
normalmente no Kafka.

O CDC tira dois dos três custos e reduz o terceiro:

- **Nenhuma carga nas tabelas.** O registro é gravado de qualquer jeito; lê-lo não varre nem bloqueia
  uma tabela que a aplicação está usando.
- **Nenhuma consulta periódica e nada perdido.** Toda mudança chega, em ordem, inclusive os deletes,
  que uma consulta procurando linhas novas nunca vê.
- **O esquema continua sendo o contrato.** Um evento de CDC é uma linha: as colunas da tabela, antes e
  depois. Quando o Sebastião divide o campo de endereço, os eventos mudam de forma exatamente como a
  tabela mudou. O CDC leva o acoplamento para um lugar melhor, não o elimina.

Esse último ponto é o motivo de o CDC costumar ser a primeira metade de alguma coisa. Os eventos de
linha vão para um pequeno tradutor que os transforma em eventos sobre o negócio, como *o produtor
017605 foi suspenso*, e o tradutor é o único código que conhece a tabela. A aula 13 usa exatamente
isso para manter o Coleta e seu substituto em sintonia enquanto os dois rodam, e a aula 11 dá nome ao
tradutor.

## Quando dividir um banco não tem problema

Dois sistemas que dividem um banco são um sistema disfarçado, para o bem ou para o mal. Dentro da
aplicação de um time, com um dono só, um banco usado por três programas desse time não é integração
nenhuma: é uma decisão de desenho dentro de uma fronteira, e o dono pode mudar o esquema porque
conhece todos os leitores. **O teste é a posse: um banco dividido entre donos diferentes é uma
interface que ninguém desenhou.** Se você precisar ler um, peça ao dono, anote o leitor no mapa, e
diga ao dono de quais colunas você depende, para que a próxima mudança nelas seja uma conversa e não
uma segunda-feira de rotas montadas à mão.
