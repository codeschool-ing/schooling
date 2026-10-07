---
title: Ferramentas de catálogo
version: 1
---

O dicionário de Ana é um arquivo SQL, um CSV e dois programas curtos, e para um warehouse isso basta. Uma empresa com
centenas de bancos, lakes e painéis precisa da mesma coisa como serviço, e esse serviço é um **catálogo de dados**. O
que os produtos fazem é, reconhecivelmente, esta lição em escala:

- **Colhem metadados** automaticamente de toda origem a que conseguem se conectar: tabelas, colunas, tipos,
  comentários, tamanhos, a última vez que cada uma foi gravada. Ninguém digita o inventário.
- **Busca** sobre tudo isso, para que "onde está a receita?" tenha uma resposta que não seja o nome de uma pessoa.
- **Propriedade**: quem responde por cada conjunto de dados, o dono do produto de dados da lição 11.
- **Um glossário de negócio**, ligado às colunas que implementam cada termo.
- **Linhagem**, colhida de consultas e pipelines, desenhada como grafo.
- **Classificação e acesso**: quais colunas são pessoais, e quem pode lê-las, às vezes imposto em vez de só
  registrado.

Catálogos de código aberto incluem o DataHub, que nasceu no LinkedIn, o OpenMetadata e o Amundsen, que nasceu na Lyft.
Cada nuvem tem o seu também: AWS Glue Data Catalog, o Dataplex do Google, Microsoft Purview e o Unity Catalog da
Databricks, que a Databricks abriu como código aberto em 2024.

Uma palavra, dois trabalhos, que vale manter separados. **Um catálogo no sentido desta lição é para pessoas**: busca,
significado, propriedade. **Um catálogo no sentido da lição 10 é para motores**: o serviço que guarda o ponteiro para
os metadados atuais de cada tabela Iceberg ou Delta, para que um commit seja atômico. Alguns produtos, Unity Catalog e
Glue entre eles, fazem as duas coisas, o que é conveniente e também é por que a palavra confunde.

Uma ferramenta não escreve descrições. **Um catálogo cheio de tabelas colhidas sem nenhum significado é um inventário,
não um dicionário**, e uma busca nele devolve os nomes de coluna que você mesmo poderia ter listado. O trabalho desta
lição, decidir e escrever o que cada coluna significa, é a parte que toda ferramenta supõe que alguém já fez.
