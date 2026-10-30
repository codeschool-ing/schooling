---
title: O que é este curso, e o que ele supõe
version: 1
---

**Este curso é sobre onde os dados chegam no Azure, onde moram e onde respondem a perguntas**, e sobre
a conta que cada uma dessas escolhas escreve. Ele acompanha os dados de uma empresa, a Quitanda, um
serviço de entrega de mercado em São Paulo: os arquivos que a loja exporta toda noite, o banco onde
moram os pedidos, os cliques que o aplicativo manda a cada segundo, e o warehouse que os analistas
consultam.

Ele corre em sete partes:

| lições | o quê | a pergunta que cada parte responde |
|---|---|---|
| 1 a 7 | contas de armazenamento, Blob Storage, ADLS Gen2 | onde um arquivo mora, por quanto tempo, quem pode lê-lo, e quanto custa ler |
| 8 a 10 | Azure SQL, Managed Instance, servidores flexíveis | o que "gerenciado" tira das suas mãos num banco relacional, e o que não tira |
| 11 a 15 | Cosmos DB e Azure Cache for Redis | um banco desenhado em torno das consultas, e o cache na frente de tudo |
| 16 a 18 | Synapse, Fabric, Delta Lake | o warehouse e o lake, e o layout de arquivos que define quanto custa uma consulta |
| 19 a 21 | Data Factory, data flows, Databricks | os jobs que precisam rodar às três da manhã |
| 22 a 24 | Event Hubs e Stream Analytics | dados que nunca param de chegar, e o que quer dizer "entregue" |
| 25 a 26 | Purview, e a escolha | saber o que você guarda, e como escolher onde guardar |

**Ele supõe dois cursos.** Do `azure-foundations`, o modelo de contas: tenant, assinaturas, grupos de
recursos, regiões e zonas, o Entra ID e o controle de acesso por papéis, e a própria linha de comando.
Do `sql-databases`, o vocabulário relacional: tabela, chave primária, índice, transação. Uma lição que
se apoia num deles diz qual lição de qual curso, e nenhuma explica uma atribuição de papel ou um
`JOIN` desde o começo.

## O que se pratica, e o que se lê

**Toda lição que pode ser praticada no seu computador é praticada**, contra os emuladores que a
terceira seção depois desta descreve: Blob Storage, Cosmos DB, Event Hubs e os próprios motores de
banco de dados. Os serviços de análise, Synapse, Fabric, Data Factory, Databricks, Stream Analytics e
Purview, não têm emulador nenhum, e um curso que fingisse o contrário ensinaria uma imitação. Essas
lições são ensinadas a partir da documentação da Microsoft e dizem isso logo no começo. Onde a ideia
por baixo roda num notebook, um arquivo Parquet, uma tabela Delta, uma janela sobre um stream, a lição
roda essa parte com uma ferramenta aberta e diz o nome da ferramenta.

## A conta, sem conta

**Toda lição que faz uma escolha põe preço nela**, porque no Azure um projeto e a sua fatura são a
mesma decisão. Um contêiner do Cosmos DB particionado pelo campo errado custa muitas vezes o que
deveria, e um lake particionado pela coluna errada é um lake que toda consulta lê inteiro. Custo é a
única coisa deste assunto que se aprende sentindo, e este curso não consegue fazer você sentir, porque
nada nele toca uma assinatura de verdade.

Ele faz a segunda melhor coisa: deixa toda soma explícita. Os medidores, o que o Azure conta e cobra,
vêm da documentação da Microsoft. Os preços são lidos por um programa que você roda, mostrado na seção
sobre a tabela de preços desta lição, e as lições fazem as contas com números redondos que dizem ser
ilustrativos. Se depois você praticar numa assinatura de verdade, a lição 13 do `azure-foundations`
cria um orçamento com alerta antes de criar qualquer coisa, e essa ordem de passos é a coisa mais
valiosa que uma conta de verdade pode ensinar.
