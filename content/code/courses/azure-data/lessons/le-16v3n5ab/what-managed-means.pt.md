---
title: O que o serviço de banco de dados assume, e o que ele deixa
version: 1
---

**O Azure SQL Database roda a máquina, o motor e a manutenção dele. Ele não roda o seu banco de
dados.** A crença que mete uma empresa em apuros é a de que ir para um banco gerenciado significa que
ninguém mais precisa entender de banco de dados. O que passa para a Microsoft é tudo o que está
debaixo do motor e uma lista fixa de tarefas em volta dele. Tudo o que acontece dentro do motor fica
onde estava: com quem escreveu o esquema e as consultas.

**Esta seção é ensinada a partir da documentação da Microsoft para o Azure SQL Database, e nada nela
foi rodado**, porque o serviço é uma parte do Azure a que nenhum emulador responde. A próxima seção
roda o motor que está por baixo dele.

O banco de pedidos da Quitanda hoje é um SQL Server num servidor dentro de um armário do escritório.
Alguém aplica as atualizações do sistema operacional quando lembra, um job despeja o banco num disco
ao lado toda noite, e se o disco do servidor morre a loja fica fechada até que se compre um novo e se
restaure o despejo. Esse é o trabalho que o serviço assume, e é um trabalho de verdade:

| o Azure SQL Database assume | continua sendo seu |
|---|---|
| o hardware, e trocá-lo quando falha | o esquema: tabelas, chaves, tipos, restrições |
| o sistema operacional e o motor, com patches e atualizações | as consultas, e as lentas |
| os backups, e restaurar a qualquer ponto do período de retenção | os índices, e os que faltam |
| a alta disponibilidade e o failover, dentro do preço | quanta computação comprar, e em que modelo |
| métricas e alertas de CPU, IO e armazenamento | o número de conexões, e o que as abre |

**A coluna da esquerda é o trabalho que é igual para todo banco de dados**, e é por isso que um
provedor pode fazê-lo uma vez para um milhão de clientes. A da direita é particular do seu, e é por
isso que nenhum provedor pode. O serviço vai mostrar, nas métricas, que o banco está no limite desde
segunda-feira. Não vai dizer que um relatório que alguém criou na segunda lê a tabela `orders` inteira
a cada minuto, e não vai criar o índice. As lições 9 e 10 de `sql-databases` são esse trabalho, e é o
mesmo trabalho aqui e no armário.

## Um servidor que não é um servidor

**O que o Azure chama de servidor lógico é um nome e um conjunto de configurações, não uma máquina.**
Ele responde em `<name>.database.windows.net`, guarda o login de administrador, as regras de firewall
e a auditoria, e agrupa bancos que podem rodar cada um num hardware diferente na mesma região. Você
nunca entra nele, e nada nele é compartilhado entre os bancos além dessas configurações. Cada banco é
comprado sozinho, num dos modelos de compra desta lição, ou divide um pool com outros, e é isso que o
Azure cobra.

**O motor é sempre o mais novo.** O Azure SQL Database não tem versão para escolher nem atualização
para agendar: a Microsoft o leva adiante, e os recursos chegam a ele antes de chegarem ao SQL Server
de caixa. Os patches são aplicados pelo serviço, numa janela que você pode influenciar e não evitar, e
uma aplicação bem escrita vê uma reconexão e nada mais, e é por isso que a documentação insiste em
lógica de nova tentativa em todo cliente.

**Os backups são automáticos e a restauração é a um ponto no tempo**, qualquer segundo dentro de um
período de retenção de 1 a 35 dias, sete por padrão. Uma restauração cria um banco novo ao lado do
antigo, em vez de sobrescrevê-lo. Retenção mais longa, cópias semanais ou mensais guardadas por anos, é
uma política à parte.

## O que você abre mão em troca

**Não há instância.** Um banco é tudo o que você aluga, então tudo o que pertence a uma instância do
SQL Server falta ou é substituído: o SQL Agent que roda jobs numa agenda, consultas que nomeiam um
segundo banco no mesmo servidor, os arquivos no disco da máquina. A maioria das aplicações nunca
percebe. Uma empresa cujos jobs noturnos rodam no SQL Agent e cujos relatórios juntam dois bancos
percebe no primeiro dia, e a lição 9 é o serviço feito para essa empresa.

**Gerenciado muda o risco de operação de lugar, não o risco de desenho.** Um disco que falha, um patch
que ninguém aplicou, um backup que ninguém testou: esses eram riscos da Quitanda e passam a ser da
Microsoft. Uma consulta que lê cem mil linhas para devolver quinze continua sendo da Quitanda, e a
próxima seção mostra uma.
