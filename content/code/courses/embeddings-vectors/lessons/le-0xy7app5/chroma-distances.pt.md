---
title: Distâncias, não notas
version: 1
---

A aula 1 deu 0,446 a *Returning a gift* contra a pergunta da cliente, e o Chroma deu 0,5544 ao mesmo
artigo. Os dois estão certos. **Uma nota cresce quando dois vetores se aproximam; uma distância
diminui.** Todo banco de vetores escolhe uma convenção para cada métrica, e ler uma como se fosse a
outra vira toda ordenação de cabeça para baixo.

O Chroma chama a métrica de **espaço** (*space*) e oferece três: `cosine`, `ip` (produto interno) e
`l2`. O programa abaixo copia os quarenta vetores para mais duas coleções, uma sem configuração e
outra no espaço `ip`, e faz a mesma pergunta às três:

```schooling-example
{
  "language": "python",
  "file": "distances.py",
  "parts": [
    {
      "code": "import chromadb\nfrom minilm import embed\n\nclient = chromadb.PersistentClient(path=\"chroma\")\ncos = client.get_collection(\"help\")\neverything = cos.get(include=[\"documents\", \"embeddings\"])",
      "note": "Abra a coleção cosseno e tire tudo dela, vetores incluídos."
    },
    {
      "code": "l2 = client.create_collection(\"help_l2\")\nip = client.create_collection(\"help_ip\", configuration={\"hnsw\": {\"space\": \"ip\"}})\nfor c in (l2, ip):\n    c.add(ids=everything[\"ids\"], embeddings=everything[\"embeddings\"],\n          documents=everything[\"documents\"])\n    print(c.name, \"space:\", c.configuration[\"hnsw\"][\"space\"])",
      "note": "Mais duas coleções com os mesmos vetores e textos: uma sem configuração e outra no espaço `ip`. Passar `embeddings` dispensa a função de embedding."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\nfor c in (cos, ip, l2):\n    r = c.query(query_embeddings=[q], n_results=3)\n    print(f\"{c.name:8}\", \"  \".join(f\"{i} {d:.4f}\" for i, d in zip(r[\"ids\"][0], r[\"distances\"][0])))",
      "note": "Um vetor de pergunta contra as três coleções, os três primeiros de cada."
    },
    {
      "code": "vec = dict(zip(everything[\"ids\"], everything[\"embeddings\"]))\nprint(f\"{'dot':8}\", \"  \".join(f\"{i} {float(vec[i] @ q):.4f}\" for i in r[\"ids\"][0]))",
      "note": "E o produto escalar puro da pergunta com cada um desses artigos, a similaridade que a aula 2 construiu."
    }
  ],
  "output": "ana@lab:~/emb$ python distances.py\nhelp_l2 space: l2\nhelp_ip space: ip\nhelp     h18 0.5544  h15 0.5624  h22 0.6006\nhelp_ip  h18 0.5544  h15 0.5624  h22 0.6006\nhelp_l2  h18 1.1089  h15 1.1249  h22 1.2013\ndot      h18 0.4456  h15 0.4376  h22 0.3994"
}
```

Pegue h18, coleção por coleção:

| | valor | relação com o produto escalar 0,4456 |
|---|---|---|
| `cosine` | 0,5544 | 1 − 0,4456 |
| `ip` | 0,5544 | 1 − 0,4456 |
| `l2` | 1,1089 | 2 − 2 × 0,4456 |

**A distância cosseno é um menos a similaridade**, então 0 quer dizer a mesma direção e 2 a direção
oposta. O espaço `ip` devolve um menos o produto escalar, que para vetores unitários é o mesmo número,
como a aula 2 mostrou. E **`l2` é a distância euclidiana ao quadrado**, não a distância em si: para
vetores unitários, o ‖a − b‖² = 2 − 2 cos da aula 2 dá 2 − 2 × 0,4456 = 1,1088, que é o 1,1089 do
Chroma a menos de um arredondamento no último dígito. A raiz quadrada não aparece em lugar nenhum.

As três ordenações são idênticas, porque as três são a mesma comparação sobre vetores unitários. Os
números não são, e é aí que começa o problema.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Três retas numéricas para os mesmos três artigos da central de ajuda, h18, h15 e h22, contra a pergunta how do I get my money back. Na reta da similaridade, de 0 a 1, eles ficam perto de 0,4 e mais alto é mais perto. Na reta da distância cosseno, de 0 a 2, ficam entre 0,56 e 0,60 e mais baixo é mais perto; um corte em 0,6 fica com h18 e h15. Na reta de L2 ao quadrado, de 0 a 4, ficam entre 1,1 e 1,2, e o mesmo corte em 0,6 não fica com nenhum.\"><text x=\"60\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">similaridade (produto escalar)</text><text x=\"660\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais alto é mais perto</text><path d=\"M60 60 L660 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 55 L60 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M660 55 L660 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><circle cx=\"327.4\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"322.6\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"299.6\" cy=\"60\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"337.4\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 0.4456 h15 0.4376 h22 0.3994</text><text x=\"60\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">distância cosseno = 1 − similaridade</text><text x=\"660\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais baixo é mais perto</text><path d=\"M60 170 L660 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 165 L60 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M360 165 L360 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M660 165 L660 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><circle cx=\"226.3\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.7\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"240.2\" cy=\"170\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"250.2\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 0.5544 h15 0.5624 h22 0.6006</text><path d=\"M240 148 L240 196\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"234\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">corte 0,6: fica com dois</text><text x=\"60\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">l2, ao quadrado = 2 − 2 × similaridade</text><text x=\"660\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais baixo é mais perto</text><path d=\"M60 280 L660 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 275 L60 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M210 275 L210 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"210\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M360 275 L360 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M510 275 L510 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M660 275 L660 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><circle cx=\"226.3\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.7\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"240.2\" cy=\"280\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"250.2\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">h18 1.1089 h15 1.1249 h22 1.2013</text><path d=\"M150 258 L150 306\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"156\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">corte 0,6: não fica com nenhum</text></svg>", "caption": "Os mesmos três artigos em três escalas. A ordem nunca muda; os números, e o lado que é melhor, mudam. Um corte em 0,6 escrito para a distância cosseno fica com dois deles; na escala l2 não fica com nenhum."}
```

## Um corte pertence a um espaço

Suponha que a Marginalia decida mostrar um artigo só quando ele estiver perto o bastante, e alguém
escreva `distance < 0.6` depois de testar na coleção cosseno. Dois dos três artigos acima passam.
Rode o mesmo código numa coleção criada sem configuração, que é `l2` por padrão, e nenhum passa: o
melhor deles está em 1,1089. Nada dá erro; a central de ajuda simplesmente para de responder.

A aula 16 trata de escolher um corte, para começo de conversa. A lição aqui é mais estreita: **um
limiar é um número num espaço, de um modelo**, e tem de ser guardado junto com eles.

## O espaço é fixado quando a coleção nasce

Não há como passar uma coleção para outro espaço depois que ela existe:

```python
import chromadb

col = chromadb.PersistentClient(path="chroma").get_collection("help")
try:
    col.modify(configuration={"hnsw": {"space": "l2"}})
except Exception as e:
    print(type(e).__name__ + ":", e)
```

```
ana@lab:~/emb$ python space.py
InvalidArgumentError: unknown field `space`, expected one of `ef_search`, `max_neighbors`, `num_threads`, `resize_factor`, `sync_threshold`, `batch_size` at line 1 column 17
```

A lista de campos que o Chroma aceita mudar traz ajustes de busca e de manutenção e deixa `space` de
fora, porque o índice foi construído com aquela métrica e cada ligação entre vizinhos guardada nele
foi medida com ela. Outro espaço é outra coleção, com todos os vetores adicionados de novo, e é por
isso que `distances.py` teve de copiar os quarenta vetores em vez de virar uma chave. Escolha na
criação, e para um modelo que devolve vetores unitários, como o all-MiniLM-L6-v2, escolha `cosine`: a
ordem é a mesma do `ip`, e os números querem dizer o que a aula 2 ensinou.
