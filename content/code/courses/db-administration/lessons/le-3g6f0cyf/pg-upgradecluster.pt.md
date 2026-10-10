---
title: O pg_upgrade, pelo pg_upgradecluster
version: 1
---

## Obtendo o PostgreSQL 17

O arquivo do Ubuntu 24.04 para no 16, então o 17 vem do repositório apt do próprio projeto
PostgreSQL, **apt.postgresql.org**, que publica toda versão maior com suporte para todo Ubuntu atual.
O postgresql-common traz um script que o adiciona, com a chave de assinatura:

@@1@@

**A máquina da gravação não conseguiu alcançar esse repositório**, e o servidor dentro dela não tem
rede nenhuma. O 17 dela foi compilado a partir do código-fonte da mesma versão, 17.10, e instalado
nos mesmos lugares que o pacote usa — `/usr/lib/postgresql/17` para os programas,
`/usr/share/postgresql/17` para o resto —, onde o postgresql-common o encontra exatamente como
encontra o pacote. A única diferença visível é a string de versão: a sua traz o empacotamento do
repositório entre parênteses depois de `17.10`, e a da gravação não tem nada depois.

@@2@@

**Instalar o pacote criou um cluster.** Na primeira vez que uma versão maior é instalada, o
postgresql-common cria um cluster `main` para ela e o sobe, na próxima porta livre — aqui a 5434,
porque o ensaio ocupa a 5433. O `17/main` está vazio, e a próxima seção o põe para trabalhar.

A outra mudança é mais discreta: o `psql` agora diz 17.10, embora o `main` continue no 16. O comando
`psql` é um wrapper do postgresql-common, e para o `psql` ele sempre roda a versão mais nova
instalada, porque um `psql` mais novo conversa com servidores mais antigos. A maioria das outras
ferramentas, o `pg_dump` entre elas, segue a versão do cluster para onde aponta, e isso importa na
próxima seção.

## Por que o servidor novo não pode simplesmente subir

O próprio servidor do 17, recebendo o diretório de dados do ensaio, se recusa antes de tocar em
qualquer coisa:

@@3@@

É por isso que upgrades maiores são um projeto. O resto desta seção é o `pg_upgrade`, o mais rápido
dos três caminhos.

## O pg_upgrade, e o wrapper em volta dele

O `pg_upgrade` é a ferramenta do próprio PostgreSQL. Ele tira o esquema do cluster antigo com o
`pg_dump`, cria esse esquema num cluster novo da versão nova e então **leva os arquivos de dados sem
lê-los**: o formato das páginas de uma tabela não mudou entre o 16 e o 17, só o catálogo que as
descreve. No Ubuntu você raramente o chama direto. O **`pg_upgradecluster`** do postgresql-common
cria o cluster novo, copia a configuração, roda o `pg_upgrade` com os caminhos certos, troca as
portas e roda depois um passo que a seção 08 explica.

Duas das opções dele decidem tudo. **`-m upgrade` escolhe o pg_upgrade**; sem ela, o
`pg_upgradecluster` volta ao padrão dele, um dump e restore, que é correto mas demora tanto quanto
os dados são grandes. **`--link`** faz o pg_upgrade criar hard links dos arquivos de dados no cluster
novo em vez de copiá-los, e essa escolha tem um preço que o fim desta seção mostra.

## A primeira tentativa, recusada

@@4@@

Leia na ordem. O cluster antigo foi **parado** — um upgrade de verdade começa a parada na primeira
linha. O cluster novo `17/rehearsal` foi criado e recebeu a configuração antiga. O `pg_upgrade` fez
as verificações de consistência, gerou o dump dos esquemas e falhou em **`Checking for presence of
required libraries`**. Então o `pg_upgradecluster` removeu o cluster feito pela metade e subiu o
antigo de novo.

Nada se perdeu, porque nada tinha sido movido: toda verificação roda antes de qualquer arquivo de
dados ser tocado. O arquivo que ele cita, guardado no diretório de log, diz o que está faltando:

@@5@@

A biblioteca da pg_repack existe para o 16 e não para o 17. Um servidor real tem duas saídas.
Instalar a versão da extensão para a versão nova — o repositório do PostgreSQL tem o
`postgresql-17-repack`, e numa máquina que o alcança, `sudo apt install postgresql-17-repack` é a
correção. Ou, quando a extensão não é necessária, removê-la antes do upgrade. A pg_repack é uma
ferramenta e não um lugar onde moram dados, então removê-la não perde nada, e foi o que a máquina da
gravação fez:

@@6@@

**Essa recusa é o ensaio se pagando.** No `main`, na noite marcada, teria sido a mesma saída com
gente esperando.

## A segunda tentativa

@@7@@

Vale conhecer as etapas, porque uma execução real demora mais e você vai assistir a ela:

- `Performing Consistency Checks` é a parte que falhou antes, e agora passou.
- `If pg_upgrade fails after this point, you must re-initdb the new cluster` é a linha em que
  verificar acaba e fazer começa.
- `Restoring database schemas` monta o catálogo do `17/rehearsal` a partir do dump do catálogo do 16.
- `Adding ".old" suffix to old global/pg_control` desativa o cluster antigo de propósito, por um
  motivo que a próxima parte mostra.
- `Linking user relation files` são os dados, todos eles, numa linha só.
- `Checking for extension updates` e `Optimizer statistics are not transferred` são dois
  trabalhos deixados para você, e a última seção de leitura desta lição cuida deles.

Depois do `pg_upgrade`, o `pg_upgradecluster` marcou o cluster antigo para ficar parado no boot,
**deu ao cluster novo a porta antiga**, subiu-o e rodou o passo de análise: as linhas do `vacuumdb`.

@@8@@

O `17/rehearsal` atende na 5433, onde o ensaio sempre esteve, então tudo o que conectava ao cluster
antigo agora chega ao novo sem mudar nada. O cluster antigo foi para a 5435 e está parado.

## O que o --link fez

@@FIGLINK@@

Um hard link é um segundo nome para o mesmo arquivo. Peça o número de inode do arquivo da tabela
`orders` nos dois diretórios de dados:

@@10@@

O mesmo número de inode nas duas linhas, e uma contagem de links **2**: um arquivo de 68.747.264
bytes com dois nomes. Nenhum byte da tabela foi copiado, e é por isso que ligar leva mais ou menos o
mesmo tempo para um banco do tamanho do `shop` e para um de 2 TB. O `du` também vê isso, porque conta
cada arquivo uma vez só por execução:

@@11@@

O diretório de dados novo acrescenta só 55 MB próprios: um catálogo novo e o WAL de um cluster novo.
Agora tente subir o cluster antigo:

@@12@@

**O cluster antigo não pode mais subir**, e isso é de propósito. Os arquivos dele são os arquivos do
cluster novo, e o 17 já está escrevendo neles; um 16 subindo sobre os mesmos arquivos leria páginas
que o 17 mudou e corromperia os dois. Por isso o `pg_upgrade` renomeou o `pg_control`, e o servidor
antigo não o encontra.

O que deixa a escolha de que o `--link` trata:

- Com `--link`, o upgrade leva mais ou menos o mesmo tempo qualquer que seja o tamanho dos dados, e
  quase não precisa de disco a mais. O caminho de volta é um **backup feito antes de começar**,
  restaurado num servidor 16.
- Sem ele, cada arquivo de dados é copiado. O upgrade leva o tempo de copiar os dados uma vez,
  precisa de espaço para uma segunda cópia e deixa o cluster antigo completo: se o 17 se comportar
  mal, você o para e sobe o 16 de novo.

Num banco do tamanho do `shop` a diferença quase não importa. Num grande, ela decide quanto dura a
noite, e esse é mais um motivo para ensaiar numa cópia do tamanho da produção: os tempos que você
mede ali são os que você vai ter.

## Quando vier o upgrade de verdade

O mesmo comando faz o upgrade do `main` — `sudo pg_upgradecluster -m upgrade --link 16 main` — com
um passo antes. Ele cria o `17/main`, e **se recusa quando já existe um cluster com esse nome**, como
o vazio que o pacote criou. Então a execução real começa com `sudo pg_dropcluster --stop 17 main`,
depois de conferir que não há nada nele. Não rode nenhum dos dois no seu servidor agora: esta lição
termina com o `main` ainda no 16.
