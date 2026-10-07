---
title: Rodando um modelo na sua própria máquina
version: 1
---

As aulas 7 e 8 mandaram cada texto a um provedor e pagaram por token. Um **modelo aberto** inverte
isso: os pesos dele são um arquivo que qualquer pessoa pode baixar, e, com o arquivo no seu disco, o
modelo roda no seu processador, quantas vezes você quiser, sem mais ninguém envolvido.

Disso saem quatro consequências, e elas são os motivos habituais para escolher um.

- Nenhuma conta por texto. Transformar a central de ajuda em vetores cem vezes custa
  eletricidade. O custo passa para a máquina que roda o modelo, e a última seção desta aula o mede.
- Nada sai. A mensagem de um cliente vira vetor onde ela está guardada. A aula 1 argumentou que
  um vetor também é dado pessoal; com um modelo aberto, nem o texto nem o vetor passam para um
  terceiro.
- Funciona sem rede, e a latência é a da sua máquina, não a de uma ida e volta.
- Nunca muda sem você saber. Um arquivo com checksum é o mesmo modelo no ano que vem. Um modelo
  hospedado pode ser atualizado ou aposentado pelo provedor, e aí todo vetor guardado precisa ser
  feito de novo, o que a aula 18 põe na conta.

O que você assume em troca é a operação: a memória, o tempo de processador e as atualizações que
ninguém vai fazer por você.

## O jeito habitual, que aqui não rodou

A maioria dos modelos abertos de embedding é publicada no **Hugging Face**, um site que hospeda
arquivos de modelos como um índice de pacotes hospeda bibliotecas. A maioria das pessoas os roda com
o **sentence-transformers**, a biblioteca do projeto que publicou o all-MiniLM-L6-v2. Este é o
programa inteiro:

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
print(model.max_seq_length, model.get_sentence_embedding_dimension())

vectors = model.encode(
    ["When your refund arrives", "Tracking a parcel"],
    normalize_embeddings=True,
)
print(vectors.shape)
```

**Este programa não foi rodado para este curso.** A primeira chamada a `SentenceTransformer` baixa o
modelo de huggingface.co para um cache local, e a própria biblioteca instala o PyTorch, cujo índice
de pacotes também estava fora de alcance. Pedir a página do modelo a huggingface.co mostra por quê:

```
ana@lab:~/emb$ curl -sS -D - -o /dev/null https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2 | head -n 2
HTTP/2 403 
x-deny-reason: host_not_allowed
```

A rede desta máquina recusa o host. Por isso nada abaixo afirma o que `st.py` imprimiria. A primeira
linha dele pergunta ao modelo a entrada máxima e a dimensão, que o model card dá como 256 e 384, e a
próxima seção abre o que o `encode` faz com elas.

## Os mesmos pesos, de outro jeito

O modelo em si não está preso à biblioteca. O Chroma, o banco de dados vetorial que a aula 12 roda,
distribui o all-MiniLM-L6-v2 exportado para **ONNX**, um formato que um runtime pequeno chamado
onnxruntime executa sem PyTorch. O `setup.sh` da aula 1 baixou essa exportação do armazenamento do próprio
Chroma e a conferiu contra o SHA-256 que o código do Chroma traz, então estes são os pesos
publicados, e não uma cópia de origem desconhecida:

```
ana@lab:~/emb$ ls -l $MINILM_DIR
total 89208
-rw-r--r-- 1 ana ana      650 Mar 30  2023 config.json
-rw-r--r-- 1 ana ana 90387606 Mar 30  2023 model.onnx
-rw-r--r-- 1 ana ana      125 Mar 30  2023 special_tokens_map.json
-rw-r--r-- 1 ana ana   711661 Mar 30  2023 tokenizer.json
-rw-r--r-- 1 ana ana      518 Mar 30  2023 tokenizer_config.json
-rw-r--r-- 1 ana ana   231508 Mar 30  2023 vocab.txt
```

`model.onnx` é o transformer, 90.387.606 bytes. O resto é o tokenizador e as configurações dele. O
`minilm.py`, que toda aula até aqui importou, embrulha tudo isso em cinquenta linhas:

```schooling-example
{
  "language": "python",
  "file": "local.py",
  "parts": [
    {
      "code": "from minilm import embed\n\nvectors = embed([\"When your refund arrives\", \"Tracking a parcel\"])\nprint(vectors.shape)\nprint(round(float(vectors[0] @ vectors[1]), 4))",
      "note": "Dois títulos passando pelo `minilm.py`: dois vetores de 384 números e o produto escalar entre eles."
    }
  ],
  "output": "ana@lab:~/emb$ python local.py\n(2, 384)\n0.1653"
}
```

Dois textos entram, dois vetores de 384 números saem, e um produto escalar de 0,1653 entre um título
sobre reembolso e um sobre rastreamento, que pouco têm a ver um com o outro. É a mesma conta que
`model.encode(..., normalize_embeddings=True)` faz; a próxima seção a desmonta e confere o resultado
contra o código do próprio Chroma até a oitava casa decimal.
