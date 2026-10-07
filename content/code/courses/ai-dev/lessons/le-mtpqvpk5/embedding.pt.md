---
title: Um índice de vetores
version: 2
---

Para buscar pelo significado, cada trecho vira um embedding uma vez, antes, e é guardado. Uma
pergunta vira embedding quando chega, e é comparada com todos eles. A aula 1 seção 09 mostrou o que é
um embedding e o que ele não enxerga; esta seção os guarda.

## Construindo o índice

```python
def build():
    cs = chunks()
    vectors = WordLlama.load().embed([c["text"] for c in cs], norm=True)
    INDEX.mkdir(exist_ok=True)
    np.save(INDEX / "vectors.npy", vectors)
    (INDEX / "chunks.json").write_text(json.dumps(cs, indent=1))
    return cs, vectors
```

```
ana@dev:~/shop$ time PYTHONPATH=scratch python -c 'import rag; cs, v = rag.build(); print(len(cs), "chunks,", v.shape, v.dtype)'
26 chunks, (26, 256) float32

real	0m1.016s
user	0m1.020s
sys	0m0.250s
ana@dev:~/shop$ ls -la .rag
total 44
drwxr-xr-x 2 ana ana  4096 Oct  7 15:07 .
drwxr-xr-x 8 ana ana  4096 Oct  7 15:07 ..
-rw-r--r-- 1 ana ana  5881 Oct  7 15:07 chunks.json
-rw-r--r-- 1 ana ana 26752 Oct  7 15:07 vectors.npy
```

Vinte e seis vetores de 256 números, em cerca de um segundo no processador de um notebook, quase
tudo para carregar o modelo. O índice são dois arquivos: os vetores, 26.752 bytes como um array do
numpy, e os trechos com os ids. **Isso é um banco vetorial no menor tamanho possível**: uma matriz, e
uma lista que diz que linha é que trecho.

## Quando partir para um de verdade

Uma matriz na memória e uma multiplicação por pergunta é a ferramenta certa até dezenas de milhares
de trechos; a comparação leva milissegundos. Além disso, ou quando o índice tem de ser compartilhado,
atualizado enquanto é buscado ou filtrado por campos (só os chamados deste cliente, só documentos deste
ano), um banco vetorial ou uma extensão vetorial do banco que você já roda assume. Eles guardam os
mesmos vetores e respondem à mesma pergunta, mais rápido, com uma busca aproximada que troca um pouco
de recall por muita velocidade.

Três regras valem em qualquer tamanho:

- **Gere o embedding da pergunta e dos trechos com o mesmo modelo.** Vetores de dois modelos não estão
  nos mesmos eixos, e compará-los dá números com cara de nota que não querem dizer nada.
- **Reconstrua quando o modelo mudar.** Um modelo de embedding novo quer dizer um índice novo, todo
  trecho de novo.
- **Reconstrua quando os documentos mudarem**, ao menos os trechos que mudaram. Um índice mais velho
  que o manual responde com regras que a loja não tem mais, com uma citação de aparência perfeita.
