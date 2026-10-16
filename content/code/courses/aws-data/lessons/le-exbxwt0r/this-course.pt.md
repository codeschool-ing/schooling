---
title: O que é este curso, e o que ele supõe
version: 1
---

**Este curso é sobre onde os dados chegam na AWS, onde moram e onde respondem a perguntas**, e sobre a
conta que cada uma dessas escolhas escreve. Ele acompanha os dados de uma empresa, a Quitanda, um
serviço de entrega de mercado em São Paulo: os arquivos que a loja exporta toda noite, o banco onde
moram os pedidos, os cliques que o aplicativo manda a cada segundo, e o warehouse que os analistas
consultam.

Ele corre em seis partes:

| lições | o quê | a pergunta que cada parte responde |
|---|---|---|
| 1 a 5 | S3 | onde um arquivo mora, por quanto tempo, quem pode lê-lo, e quanto custa ler |
| 6 a 8 | RDS e Aurora | o que "gerenciado" tira das suas mãos num banco relacional, e o que não tira |
| 9 a 13 | DynamoDB e ElastiCache | um banco desenhado em torno das consultas, e o cache na frente de tudo |
| 14 a 19 | Redshift, Athena, Glue, Lake Formation | o warehouse e o lake, e as duas decisões que definem quanto custa uma consulta |
| 20 a 23 | Kinesis, Firehose, MSK | dados que nunca param de chegar, e o que quer dizer "entregue" |
| 24 a 27 | EMR, MWAA, DMS e a escolha | os jobs que rodam de madrugada, o banco de onde se migra, e como escolher onde guardar |

**Ele supõe dois cursos.** Do `aws-foundations`, a conta, regiões e zonas, os principals e as
políticas do IAM, e a própria linha de comando. Do `sql-databases`, o vocabulário relacional: tabela,
chave primária, índice, transação. Uma lição que se apoia num deles diz qual lição de qual curso, e
nenhuma explica um documento de política ou um `JOIN` desde o começo.

## A conta, sem conta

**Toda lição que faz uma escolha põe preço nela**, porque na AWS um projeto e a sua fatura são a mesma
decisão. Uma tabela desenhada em torno da chave errada é uma tabela que custa dez vezes o que deveria,
e um lake particionado pela coluna errada é um lake que toda consulta lê inteiro. Custo é a única coisa
deste assunto que se aprende sentindo, e este curso não consegue fazer você sentir, porque nada nele
toca uma conta de verdade; ele faz a segunda melhor coisa: todo preço é lido da lista publicada pela
AWS por um programa que você roda, e toda lição que cita um mostra a conta, para que o número possa
ser conferido em vez de afirmado.

O dinheiro neste curso é sempre um cálculo e nunca uma fatura. Isso é mais seguro e honesto sobre o
que é, e não é o mesmo que ver um total de verdade subir durante a noite. Se depois você praticar numa
conta real, a seção da lição 1 do `aws-foundations` sobre uma conta de verdade cria um orçamento com
alerta antes de criar qualquer coisa, e a lição 13 daquele curso é sobre orçamentos. Essa ordem de
passos é a coisa mais valiosa que uma conta de verdade pode ensinar.
