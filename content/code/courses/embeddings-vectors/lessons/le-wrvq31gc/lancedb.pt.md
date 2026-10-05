---
title: LanceDB, uma tabela em arquivos
version: 1
---

O LanceDB é embutido como o `PersistentClient` do Chroma: sem servidor, um diretório, uma biblioteca
no seu processo. **O que ele guarda lá é uma tabela**, com colunas tipadas, e o vetor é uma coluna
entre outras. Os arquivos estão em Lance, um formato colunar que lê e grava dados no Apache Arrow, o
formato em memória que o pandas e muitas outras ferramentas de dados trocam entre si.

```schooling-example
{
  "language": "python",
  "file": "lance_load.py",
  "parts": [
    {
      "code": "import json\nimport lancedb\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Os artigos e os seus vetores, como antes."
    },
    {
      "code": "db = lancedb.connect(\"lance\")\ntable = db.create_table(\"help\", data=[\n    {\"id\": h[\"id\"], \"category\": h[\"category\"], \"lang\": h[\"lang\"],\n     \"title\": h[\"title\"], \"vector\": v} for h, v in zip(help, X)])\nprint(table.count_rows(), \"rows, version\", table.version)\nprint(table.schema.field(\"vector\"))",
      "note": "`connect` abre um diretório, não um servidor. A tabela é criada a partir de uma lista de dicionários, e a coluna chamada `vector` guarda os embeddings."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\nfor r in table.search(q).limit(3).to_list():\n    print(f\"{r['_distance']:.4f}  {r['id']}  {r['title']}\")",
      "note": "Uma busca sem dizer mais nada, os três primeiros com a sua `_distance`."
    },
    {
      "code": "for r in (table.search(q).distance_type(\"cosine\")\n          .where(\"category = 'ebooks'\").limit(3).to_list()):\n    print(f\"{r['_distance']:.4f}  {r['id']}  {r['title']}\")",
      "note": "A mesma busca medindo a distância cosseno, com uma condição SQL sobre outra coluna."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_load.py\n40 rows, version 1\npyarrow.Field<vector: fixed_size_list<item: float>[384]>\n1.1089  h18  Returning a gift\n1.1249  h15  When your refund arrives\n1.2013  h22  Charged twice for one order\n0.6095  h33  Refunds for e-books\n0.8367  h35  Lending and sharing e-books\n0.8376  h37  Audiobooks"
}
```

A linha do esquema diz o que é a coluna do vetor: uma lista de tamanho fixo com 384 floats, declarada
pelas primeiras linhas que entraram. Uma linha com vetor de outro tamanho não caberia na coluna.

## O padrão é L2 de novo

**A primeira busca devolveu 1,1089 para h18**, o número que o Chroma deu no espaço `l2` na aula 12.
O LanceDB mede a distância euclidiana ao quadrado a menos que alguém diga outra coisa, que também é o
padrão do Chroma. Com `distance_type("cosine")` os números viram distâncias cosseno, 0,6095 para
*Refunds for e-books* (reembolso de e-books), que é de novo um menos a similaridade. A ordem dos
vetores unitários é a mesma dos dois jeitos; um limiar não é.

`where` recebe uma condição SQL sobre as outras colunas, `category = 'ebooks'` aqui, então a linguagem
de filtro é uma que você já conhece. Como essa condição e a busca vetorial se combinam, antes ou
depois de achar os vizinhos mais próximos, é assunto da aula 17.

## Cada escrita é uma versão

**O LanceDB nunca muda um arquivo que já gravou.** Uma escrita acrescenta arquivos novos e uma versão
nova da tabela, que lista os arquivos que a compõem, e isso aparece no Python:

```schooling-example
{
  "language": "python",
  "file": "lance_versions.py",
  "parts": [
    {
      "code": "import lancedb\nfrom minilm import embed\n\ntable = lancedb.connect(\"lance\").open_table(\"help\")",
      "note": "Abra a tabela que o programa anterior criou."
    },
    {
      "code": "table.add([{\"id\": \"h41\", \"category\": \"payments\", \"lang\": \"en\",\n            \"title\": \"Gift cards by email\", \"vector\": embed(\"Gift cards by email\")[0]}])\nprint(\"after add:   \", table.count_rows(), \"rows, version\", table.version)\ntable.delete(\"id = 'h41'\")\nprint(\"after delete:\", table.count_rows(), \"rows, version\", table.version)",
      "note": "Adicione uma linha, depois apague, e imprima a contagem e a versão depois de cada passo."
    },
    {
      "code": "for v in table.list_versions():\n    m = v[\"metadata\"]\n    print(\"version\", v[\"version\"], \":\", m[\"total_rows\"], \"rows in\", m[\"total_data_files\"], \"data file(s)\")",
      "note": "Cada versão que a tabela guardou, com o que o manifesto dela registra."
    },
    {
      "code": "table.checkout(2)\nprint(\"checked out version 2:\", table.count_rows(), \"rows\")\ntable.checkout_latest()",
      "note": "Volte à versão 2 e conte, depois retorne à mais recente."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_versions.py\nafter add:    41 rows, version 2\nafter delete: 40 rows, version 3\nversion 1 : 40 rows in 1 data file(s)\nversion 2 : 41 rows in 2 data file(s)\nversion 3 : 40 rows in 1 data file(s)\nchecked out version 2: 41 rows"
}
```

O add criou a versão 2, com 41 linhas em dois arquivos de dados. O delete criou a versão 3, com 40
linhas em um, e a versão 2 continua lá: `checkout(2)` contou as 41 linhas dela. O diretório mostra
como:

```
ana@lab:~/emb$ find lance -type f | sort
lance/help.lance/_transactions/0-24dddc8e-55d2-4657-a033-b55270f3e615.txn
lance/help.lance/_transactions/1-8ed5e0e5-d968-4614-9c9a-0e59f670ec9e.txn
lance/help.lance/_transactions/2-e225f4cb-74a1-46e6-9a7b-0fe61a5e0dac.txn
lance/help.lance/_versions/18446744073709551612.manifest
lance/help.lance/_versions/18446744073709551613.manifest
lance/help.lance/_versions/18446744073709551614.manifest
lance/help.lance/_versions/latest_version_hint.json
lance/help.lance/data/0011011110101101000010012a38754bf3ae31d9f2dd79c3a4.lance
lance/help.lance/data/100011111011110000011110d2cce04a5cbd1acfbde7a4aa40.lance
```

Um manifesto por versão em `_versions`, um registro de transação por escrita, e dois arquivos de
dados. O segundo arquivo de dados guarda só h41, e nada atual o usa; ele fica porque a versão 2 fica.
**Versões antigas não saem de graça.** Uma tabela regravada toda noite guarda os arquivos de todas as
noites até você limpá-los, o que nesta versão da biblioteca é `table.optimize(cleanup_older_than=...)`.
Em troca você ganha o que os outros depósitos desta aula não têm: um jeito de olhar a tabela como ela
estava antes da importação de ontem à noite, e um leitor que abriu uma versão e não é perturbado por
quem escreve a próxima.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três versões da tabela help do LanceDB, cada uma um manifesto que lista arquivos de dados. A versão 1 lista o arquivo de dados A, com 40 linhas. A versão 2, depois de um add, lista A e um arquivo novo, B, com h41, 41 linhas. A versão 3, depois do delete, lista só A, 40 linhas. O arquivo B continua no disco porque a versão 2 ainda o lista.\"><defs><marker id=\"vept-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">create</text><rect x=\"30\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 1</text><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40 linhas</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois do add</text><rect x=\"270\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 2</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">41 linhas</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois do delete</text><rect x=\"510\" y=\"36\" width=\"180\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 3</text><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40 linhas</text><rect x=\"150\" y=\"200\" width=\"180\" height=\"56\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arquivo de dados A</text><text x=\"240\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os 40 artigos</text><rect x=\"420\" y=\"200\" width=\"180\" height=\"56\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"510\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arquivo de dados B</text><text x=\"510\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só h41</text><text x=\"510\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mantido enquanto a versão 2 existir</text><path d=\"M120 90 L220 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vept-ah0)\"></path><path d=\"M345 90 L250 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vept-ah0)\"></path><path d=\"M375 90 L490 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vept-ah0)\"></path><path d=\"M600 90 L270 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vept-ah0)\"></path></svg>", "caption": "Cada escrita criou uma versão, e uma versão é uma lista de arquivos de dados. O delete não mexeu em arquivo nenhum: ele criou a versão 3, que lista só o primeiro.", "same": ["create"]}
```

Com quarenta linhas a busca lê todos os vetores. Uma tabela grande ganha um índice aproximado com
`table.create_index(...)`, construído das mesmas famílias dos nomes do FAISS, e é na aula 15 que elas
são explicadas.
