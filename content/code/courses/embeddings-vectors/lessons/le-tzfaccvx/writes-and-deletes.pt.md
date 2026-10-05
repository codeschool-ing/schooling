---
title: Escritas e remoções
version: 1
---

Uma central de ajuda muda. Um artigo é corrigido, outro é retirado, um novo aparece. A expectativa
natural é que um banco vetorial edite um registro no lugar e tire um registro apagado na hora, do
jeito que uma linha some de uma planilha. **A maioria deles não faz nenhuma das duas coisas de
imediato.** Uma edição escreve uma versão nova e aposenta a antiga; uma remoção marca o registro
como apagado e o deixa onde está até uma limpeza posterior. O armazenamento pequeno faz as duas do
mesmo jeito, e `writes.py` mostra as contagens:

```schooling-example
{
  "language": "python",
  "file": "writes.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nask = lambda: [id for id, _ in store.search(q, k=3, model=\"all-MiniLM-L6-v2\")]\nq = embed(\"how do I get my money back\")[0]\nprint(\"before:      \", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Carregue o armazenamento e faça a pergunta da aula 1. Imprima os três primeiros ids, as linhas do array e as linhas ainda vivas."
    },
    {
      "code": "help = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}\nh = help[\"h15\"]\ntext = h[\"title\"] + \". \" + h[\"body\"].replace(\"three working days\", \"five working days\")\nstore.upsert(\"h15\", embed(text)[0], {\"category\": \"returns\", \"lang\": \"en\", \"updated\": \"2026-10-05\"}, text)\nprint(\"after edit:  \", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Edite um artigo: o h15 agora diz cinco dias úteis em vez de três. O texto novo é transformado em vetor de novo e entra por upsert com o mesmo id."
    },
    {
      "code": "store.delete(\"h18\")\nprint(\"after delete:\", ask(), \"rows\", len(store.ids), \"alive\", int(store.alive.sum()))",
      "note": "Apague o artigo do presente, h18, e pergunte de novo."
    },
    {
      "code": "store.save()\nprint(\"saved:       \", len(Store.load(\"store\").ids), \"records\")",
      "note": "Salve, o que compacta, e conte os registros que voltam do disco."
    }
  ]
}
```

```
ana@lab:~/emb$ python writes.py
before:       ['h18', 'h15', 'h22'] rows 40 alive 40
after edit:   ['h18', 'h15', 'h22'] rows 41 alive 40
after delete: ['h15', 'h22', 'h14'] rows 41 alive 39
saved:        39 records
ana@lab:~/emb$ ls -l store
total 76
-rw-r--r-- 1 ana ana 13796 Oct  5 14:21 records.json
-rw-r--r-- 1 ana ana 60032 Oct  5 14:21 vectors.npy
```

## Um upsert, não um insert nem um update

**Escrever um id que já existe substitui o registro; escrever um id novo acrescenta um.** Essa
operação se chama upsert, e é a escrita comum nos bancos vetoriais (Chroma, Qdrant e Pinecone têm
um método com esse nome) porque torna uma escrita segura de repetir. Um trabalho que transforma de
novo em vetor a central de ajuda toda noite pode fazer upsert dos 40 artigos sem antes perguntar
quais existem.

A edição do `h15` entrou desse jeito, e a segunda linha mostra o que ela custou por dentro. **As
linhas foram de 40 para 41, enquanto os registros vivos continuaram 40.** O vetor antigo do `h15`
continua no array, marcado como morto; o novo foi acrescentado no fim. O ranking não mudou, porque
trocar *três* por *cinco* dias úteis quase não mexe no sentido, e esse é o resultado certo:
`writes.py` calculou o vetor de novo a partir do texto novo.

**Essa é a regra que o armazenamento não consegue garantir por você: um vetor precisa ser
recalculado sempre que o texto dele muda.** `upsert` recebe o vetor e o texto como dois argumentos,
e nada impede quem chama de passar o texto novo com o vetor velho. O registro então responde a
perguntas sobre o que o artigo dizia antes e mostra o que ele diz agora. Todo banco de verdade tem a
mesma brecha, porque nenhum consegue conferir se um vetor pertence a um texto. O código que escreve
precisa transformar o texto em vetor no mesmo passo, toda vez.

## Uma remoção deixa uma lápide

`delete("h18")` tirou o artigo do presente dos resultados: a terceira linha põe o `h15` em
primeiro e traz o `h14`. **Mas as linhas continuaram 41.** A remoção só desligou a marca `alive` da
linha, então o vetor continua lá, ainda multiplicado por toda consulta e depois descartado. Uma
marca assim, no lugar de algo apagado, se chama **lápide** (*tombstone*).

As lápides existem porque remover sai caro. Tirar uma linha do meio de um array significa mover
todas as linhas depois dela, e num índice de verdade é pior. Um índice aproximado, que a aula 15
constrói, é uma estrutura de ligações entre vetores, e tirar um vetor dela significa consertar cada
ligação que passava por ele. Marcar como morto é instantâneo. O custo é pago depois, de uma vez.

**Salvar é onde o armazenamento paga.** `save()` grava só as linhas vivas, então o armazenamento em
disco tem 39 registros. O `vectors.npy` encolheu exatamente um vetor, de 61.568 para 60.032 bytes,
uma diferença de 1.536, que são 384 números de 4 bytes. Os bancos de verdade chamam esse passo de
compactação, vacuum ou reconstrução, rodam em segundo plano e ficam mais lentos enquanto lápides
demais se acumulam. A aula 18 mede quanto custa reconstruir um índice, e quando vale a pena.
