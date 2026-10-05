---
title: O que um banco acrescenta
version: 1
---

A primeira imagem comum de um banco vetorial é "a coisa que deixa a busca rápida". Velocidade é
uma das coisas que ele acrescenta, e para os 40 artigos da Marginalia é a que menos importa: a
seção anterior buscou dez mil vetores em menos de um milissegundo. **A maior parte do que um banco
vetorial acrescenta é o que um banco acrescenta a qualquer coisa**: os dados sobrevivem ao
programa, os registros têm nome, e podem ser alterados um de cada vez enquanto outras pessoas leem.

Compare isso com os arrays das aulas 3 a 10. Uma matriz de vetores do NumPy não tem:

- Persistência. Ela vive na memória de um programa e some quando o programa termina, a menos que
  alguém a grave num arquivo e lembre qual arquivo.
- Ids. Uma linha só é um artigo porque uma lista separada diz isso, na mesma ordem. Insira uma
  linha numa e não na outra, e toda busca responde com o artigo errado dali em diante.
- Metadados. A categoria, a língua e a data de cada artigo estão em outro lugar, então "só artigos
  em português" é uma segunda busca escrita à mão.
- Atualizações nem remoções. Mudar um artigo significa reconstruir a matriz, ou acertar números de
  linha à mão.
- Concorrência. Dois programas gravando o mesmo arquivo ao mesmo tempo dão um arquivo corrompido.
- Índice. Cada consulta lê todos os vetores, ao custo que a seção anterior mediu.
- Backups, controle de acesso, nem registro de qual modelo fez os números.

**Um banco vetorial é um armazenamento que resolve tudo isso.** Antes dos de verdade, ajuda ver
que o núcleo é pequeno. O programa abaixo é um armazenamento inteiro em umas cinquenta linhas:
persistência, ids, metadados, atualizações, remoções e um filtro, com busca exata por dentro. Não
tem índice nem concorrência, e não foi feito para produção; foi feito para que cada palavra das
próximas três seções seja algo que você rodou.

```schooling-example
{
  "language": "python",
  "file": "tinystore.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\n\n\nclass Store:\n    \"\"\"A collection: one model, one dimension, records of id + vector + metadata + text.\"\"\"",
      "note": "Um `Store` é uma coleção, e a docstring dele diz o que é um registro."
    },
    {
      "code": "    def __init__(self, path, model, dim):\n        self.path, self.model, self.dim = path, model, dim\n        self.ids, self.meta, self.docs = [], [], []\n        self.vecs = np.zeros((0, dim), dtype=np.float32)\n        self.alive = np.zeros(0, dtype=bool)\n        self.where = {}                                  # id -> row",
      "note": "O modelo e a dimensão ficam fixos quando a coleção é criada. As linhas vivem em listas paralelas e num array do NumPy; `alive` marca quais linhas valem, e `where` acha a linha de um id."
    },
    {
      "code": "    def upsert(self, id, vec, meta, doc):\n        vec = np.asarray(vec, dtype=np.float32)\n        if vec.shape != (self.dim,):\n            raise ValueError(f\"{self.model} vectors have {self.dim} numbers, got {vec.shape}\")\n        vec = vec / np.linalg.norm(vec)\n        if id in self.where:                             # same id: replace in place\n            self.alive[self.where[id]] = False\n        self.where[id] = len(self.ids)\n        self.ids.append(id); self.meta.append(meta); self.docs.append(doc)\n        self.vecs = np.vstack([self.vecs, vec])\n        self.alive = np.append(self.alive, True)",
      "note": "Um upsert recusa um vetor do tamanho errado e normaliza os outros. Um id que já existe tem a linha antiga marcada como morta, e o registro novo vai para o fim."
    },
    {
      "code": "    def delete(self, id):\n        self.alive[self.where.pop(id)] = False           # a tombstone, not a removal",
      "note": "Um delete só marca a linha como morta. O vetor fica no array até o armazenamento ser salvo."
    },
    {
      "code": "    def search(self, q, k=3, model=None, **filters):\n        if model != self.model:\n            raise ValueError(f\"this collection holds {self.model} vectors, not {model}\")\n        ok = self.alive.copy()\n        for key, value in filters.items():\n            ok &= np.array([m.get(key) == value for m in self.meta], dtype=bool)\n        scores = np.where(ok, self.vecs @ q, -np.inf)\n        best = np.argsort(-scores)[:k]\n        return [(self.ids[i], float(scores[i])) for i in best if ok[i]]",
      "note": "Uma busca precisa dizer com que modelo a pergunta foi transformada em vetor. Linhas mortas ou que não passam num filtro recebem nota menos infinito, o resto é ordenado pelo produto escalar, e os k melhores voltam como ids com notas."
    },
    {
      "code": "    def save(self):\n        keep = np.flatnonzero(self.alive)                # compaction drops the tombstones\n        os.makedirs(self.path, exist_ok=True)\n        np.save(os.path.join(self.path, \"vectors.npy\"), self.vecs[keep])\n        with open(os.path.join(self.path, \"records.json\"), \"w\") as f:\n            json.dump({\"model\": self.model, \"dim\": self.dim,\n                       \"records\": [{\"id\": self.ids[i], \"meta\": self.meta[i], \"doc\": self.docs[i]}\n                                   for i in keep]}, f)\n\n    @classmethod\n    def load(cls, path):\n        info = json.load(open(os.path.join(path, \"records.json\")))\n        s = cls(path, info[\"model\"], info[\"dim\"])\n        for r, v in zip(info[\"records\"], np.load(os.path.join(path, \"vectors.npy\"))):\n            s.upsert(r[\"id\"], v, r[\"meta\"], r[\"doc\"])\n        return s",
      "note": "Salvar grava só as linhas vivas: os vetores num arquivo `.npy` e todo o resto em JSON ao lado. Carregar lê os dois e faz upsert de cada registro de novo."
    }
  ]
}
```

`index.py` o preenche com a central de ajuda. Cada artigo vira um registro com o id, o vetor, três
campos de metadados e o texto, e o armazenamento se grava num diretório:

```schooling-example
{
  "language": "python",
  "file": "index.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom tinystore import Store\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "Os 40 artigos, cada um como título e corpo juntos, que é o texto transformado em vetor e o texto que a busca devolve."
    },
    {
      "code": "store = Store(\"store\", \"all-MiniLM-L6-v2\", 384)\nfor h, text, vec in zip(help, texts, embed(texts)):\n    meta = {\"category\": h[\"category\"], \"lang\": h[\"lang\"], \"updated\": h[\"updated\"]}\n    store.upsert(h[\"id\"], vec, meta, text)\nstore.save()\nprint(len(store.ids), \"records saved\")",
      "note": "Uma coleção para os 384 números do all-MiniLM-L6-v2. Cada artigo vira um registro: o id, o vetor, três campos de metadados e o texto. Depois salve no diretório `store`."
    }
  ]
}
```

```
ana@lab:~/emb$ python index.py
40 records saved
ana@lab:~/emb$ ls -l store
total 80
-rw-r--r-- 1 ana ana 14140 Oct  5 14:21 records.json
-rw-r--r-- 1 ana ana 61568 Oct  5 14:21 vectors.npy
```

**Dois arquivos, e cada um é fácil de explicar.** `vectors.npy` tem 61.568 bytes: 40 vetores de
384 números `float32` são 40 × 1.536 = 61.440 bytes, e os outros 128 são o cabeçalho que o NumPy
escreve na frente de todo array. `records.json` guarda os ids, os metadados, os textos e o nome e
a dimensão do modelo. O diretório persistente do Chroma, na aula 12, guarda os mesmos ingredientes
num arquivo SQLite e num conjunto de arquivos de índice, e o LanceDB, na aula 13, os guarda em
arquivos colunares. Nenhum dos dois é tão fácil de ler quanto este, e a principal coisa que cada um
acrescenta é o índice.

Buscar nele é a linha da aula 3 de novo, atrás de uma função que sabe quais linhas são registros:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import sys\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nq = embed(sys.argv[1])[0]\nfor id, score in store.search(q, k=3, model=\"all-MiniLM-L6-v2\"):\n    print(f\"{score:.3f}  {id}  {store.docs[store.where[id]][:58]}\")",
      "note": "Carregue o armazenamento do disco, transforme em vetor a pergunta da linha de comando com o modelo da coleção e imprima os três melhores registros com as notas e o começo do texto."
    }
  ]
}
```

```
ana@lab:~/emb$ python ask.py "how do I get my money back"
0.446  h18  Returning a gift. The person who received the gift can ret
0.438  h15  When your refund arrives. We refund within three working d
0.399  h22  Charged twice for one order. When a payment fails and you 
```

As notas são as que a aula 1 imprimiu para a mesma pergunta e os mesmos artigos: 0,446 para o
artigo do presente e 0,438 para o do reembolso. O armazenamento mudou onde os vetores moram e como
eles se chamam, não o que eles são.
