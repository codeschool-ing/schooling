---
title: Um armazenamento e uma cadeia no LangChain
version: 1
---

O armazenamento é o `PGVector`, do `langchain-postgres`, no mesmo PostgreSQL com pgvector em que
mora a tabela `chunks` da aula 5. O programa de carga lê o front matter por conta própria, divide no
tamanho que a seção anterior escolheu e entrega os pedaços:

```schooling-example
{
  "language": "python",
  "file": "lc_load.py",
  "parts": [
    {
      "code": "import glob\nimport hashlib\nimport sys\n\nfrom langchain_core.documents import Document\nfrom langchain_openai import OpenAIEmbeddings\nfrom langchain_postgres import PGVector\nfrom langchain_text_splitters import RecursiveCharacterTextSplitter",
      "note": "As peças do LangChain: um tipo de documento, o cliente de embeddings da OpenAI, o armazenamento do Postgres e um divisor."
    },
    {
      "code": "URL = \"postgresql+psycopg:///rag?host=/run/emb-pg\"\nembeddings = OpenAIEmbeddings(model=\"lab-minilm\", check_embedding_ctx_length=False)\nstore = PGVector(embeddings=embeddings, collection_name=\"docs\", connection=URL)",
      "note": "O armazenamento recebe o cliente de embeddings e a coleção a preencher. Ele cria as próprias tabelas no primeiro uso. `check_embedding_ctx_length=False` é a correção da seção anterior."
    },
    {
      "code": "def document(path):\n    \"\"\"The text after the front matter, with the front matter as metadata.\"\"\"\n    _, head, body = open(path).read().split(\"---\\n\", 2)\n    meta = dict(line.split(\": \", 1) for line in head.splitlines())\n    return Document(page_content=body, metadata=meta)",
      "note": "O front matter vira metadado em vez de texto. O divisor o deixaria no alto do primeiro pedaço; lê-lo é trabalho do programa."
    },
    {
      "code": "docs = [document(p) for p in sorted(glob.glob(\"data/docs/*.md\"))]\nchunks = RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50).split_documents(docs)\nids = None\nif \"--ids\" in sys.argv:\n    ids = [c.metadata[\"id\"] + \":\" + hashlib.sha256(c.page_content.encode()).hexdigest()[:12] for c in chunks]\nstore.add_documents(chunks, ids=ids)\nprint(len(chunks), \"chunks added\")",
      "note": "400 caracteres com 50 de sobreposição, mais ou menos as 60 palavras da aula 4. Com `--ids`, cada pedaço recebe o tipo de id da aula 5, o documento e um hash do texto; sem ele, `ids` fica `None` e o armazenamento inventa os seus."
    }
  ]
}
```

## Um armazenamento que carrega duas vezes

```
ana@lab:~/rag$ python lc_load.py
126 chunks added
ana@lab:~/rag$ psql -c "\dt"
                List of relations
 Schema |          Name           | Type  | Owner 
--------+-------------------------+-------+-------
 public | chunks                  | table | ana
 public | langchain_pg_collection | table | ana
 public | langchain_pg_embedding  | table | ana
(3 rows)
ana@lab:~/rag$ python lc_load.py
126 chunks added
ana@lab:~/rag$ psql -Atc "SELECT count(*) FROM langchain_pg_embedding"
252
```

O armazenamento criou **duas tabelas próprias** ao lado das da aula 5: `langchain_pg_collection`
dá nome às coleções, e `langchain_pg_embedding` guarda o texto, o vetor e os metadados de cada
pedaço, os metadados numa coluna JSON única em vez das colunas tipadas da aula 5. É um esquema que
outra pessoa desenhou, e o que for lê-lo depois (um relatório, uma exportação, um pedido de
exclusão) vai ter de aprendê-lo.

Rodar a carga uma segunda vez **dobrou a tabela, para 252 linhas**: cada chamada a `add_documents`
dá a cada pedaço um id aleatório novo, a não ser que receba ids, então o mesmo texto entrou duas
vezes. Toda busca passaria a achar duas cópias do melhor pedaço, com a mesma nota, e a ocupar dois
dos seus três lugares com elas. A aula 5 resolveu isso com ids feitos do documento e do texto, e o
armazenamento os aceita:

```
ana@lab:~/rag$ psql -qc "DELETE FROM langchain_pg_embedding"
ana@lab:~/rag$ python lc_load.py --ids
126 chunks added
ana@lab:~/rag$ python lc_load.py --ids
126 chunks added
ana@lab:~/rag$ psql -Atc "SELECT count(*) FROM langchain_pg_embedding"
126
```

Com ids, a segunda carga escreve por cima da primeira e a contagem fica em 126. O que ela ainda não
faz é perceber um pedaço que sumiu: um documento apagado do acervo mantém seus pedaços no
armazenamento até alguém apagá-los. O LangChain tem uma API de indexação para isso, `index()` com um
gerenciador de registros, que guarda uma tabela dos hashes que carregou e remove os que uma carga
nova não tem mais. É a comparação entre ids desejados e existentes da aula 5, com outro nome e outra
tabela.

## Uma nota que aponta para o outro lado

```
ana@lab:~/rag$ python lc_search.py "How long is a gift card valid?"
0.253  gift-cards             '## Validity\n\nA gift card is valid for tw'
0.287  payments-and-invoices  'Gift cards are valid for two years from '
0.377  gift-cards             '## Using a gift card\n\nEach card has a si'
```

O melhor pedaço teve **0,253, e o pior dos três 0,377**. São **distâncias**, em que menor é melhor: a
distância de cosseno do pgvector, que é 1 menos a similaridade que a aula 6 imprimia. Uma distância
de 0,253 é uma similaridade de 0,747. Copie o piso da aula 6 para este método como "manter notas
acima de 0,5" e ele mantém exatamente os pedaços que deviam ter sido descartados.

O recuperador, uma camada acima, desvira o número. A busca `similarity_score_threshold` dele converte
cada distância numa relevância de 1 menos a distância antes de comparar com o limite, então
`score_threshold: 0.5` ali é o mesmo piso da aula 6. Dois métodos da mesma biblioteca, os dois
chamando seu número de nota, apontando em direções opostas. **Leia o que um número é antes de pôr
um limite nele.**

## A cadeia

O programa que responde usa as instruções da aula 7, o filtro e o piso da aula 6, e o jeito do
LangChain de ligar passos, o `|` da sua linguagem de expressões:

```schooling-example
{
  "language": "python",
  "file": "lc_chain.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import REFUSAL, SYSTEM\nfrom langchain_core.output_parsers import StrOutputParser\nfrom langchain_core.prompts import ChatPromptTemplate\nfrom langchain_openai import ChatOpenAI, OpenAIEmbeddings\nfrom langchain_postgres import PGVector",
      "note": "As instruções e a frase de recusa são as da aula 7, importadas do `answer.py`, e não do LangChain."
    },
    {
      "code": "store = PGVector(embeddings=OpenAIEmbeddings(model=\"lab-minilm\", check_embedding_ctx_length=False),\n                 collection_name=\"docs\", connection=\"postgresql+psycopg:///rag?host=/run/emb-pg\")\nsearch = {\"k\": 3, \"score_threshold\": 0.5}\nif \"--all\" not in sys.argv:\n    search[\"filter\"] = {\"status\": \"current\", \"audience\": \"public\"}\nretriever = store.as_retriever(search_type=\"similarity_score_threshold\", search_kwargs=search)\nprompt = ChatPromptTemplate.from_messages([(\"system\", SYSTEM), (\"user\", \"{sources}\\n\\nQuestion: {question}\")])\nchain = prompt | ChatOpenAI(model=\"extract-1\") | StrOutputParser()",
      "note": "O `similarity_score_threshold` transforma a distância numa relevância de 1 menos a distância antes de comparar com 0,5, então este é o piso da aula 6. O filtro também é o da aula 6, escrito como um dicionário que o armazenamento converte numa condição sobre a coluna JSON. A cadeia são três peças ligadas por `|`: preencher o prompt, chamar o modelo, tirar o texto da resposta."
    },
    {
      "code": "def numbered(found):\n    return \"\\n\\n\".join(f\"[{n}] {d.metadata['title']} (updated {d.metadata['updated']})\\n{d.page_content}\"\n                       for n, d in enumerate(found, 1))",
      "note": "Fontes numeradas com título e data, como o prompt da aula 7 as tem."
    },
    {
      "code": "question = sys.argv[-1]\nfound = retriever.invoke(question)\nprint(chain.invoke({\"sources\": numbered(found), \"question\": question}) if found else REFUSAL)\nfor n, d in enumerate(found, 1):\n    print(f\"  [{n}] {d.metadata['id']}, {d.metadata['status']}\")",
      "note": "Nada acima do piso, nenhuma chamada ao modelo: a recusa da aula 7. A cadeia só roda quando há de onde responder."
    }
  ]
}
```

Primeiro sem o filtro, passando `--all`, e depois com ele:

```
ana@lab:~/rag$ python lc_chain.py --all "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [2] You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
  [1] returns-policy-2025, superseded
  [2] returns-policy, current
  [3] returns-policy, current
ana@lab:~/rag$ python lc_chain.py "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]
  [1] returns-policy, current
  [2] returns-policy, current
  [3] terms-of-sale, current
```

Sem o filtro, a segunda frase da resposta, **14 dias, vem da política de 2025**, que o armazenamento
guarda porque nada lhe disse o contrário; a resposta a cita como [1], e o status dela diz
`superseded`. Com o filtro, as três fontes são atuais. As respostas vêm do extract-1, o substituto
do laboratório, que copia as frases das fontes mais próximas da pergunta; um modelo de linguagem com
as mesmas três fontes teria os mesmos dois números na frente.

```
ana@lab:~/rag$ python lc_chain.py "Can I pay with cryptocurrency?"
No relevant docs were retrieved using the relevance score threshold 0.5
I could not find that in our documents.
```

A primeira linha dessa saída é do LangChain: um aviso de que **nada passou do limite**. A segunda é a
recusa do próprio programa, mandada sem chamar o modelo. Uma cadeia feita só de `|` teria chamado o
modelo sem fonte nenhuma, e a aula 1 mostrou o que um modelo diz quando lhe perguntam sobre a
Marginalia sem nada na frente. O `if` no fim do programa é a decisão da aula 7, e não foi o LangChain
que a tomou.
