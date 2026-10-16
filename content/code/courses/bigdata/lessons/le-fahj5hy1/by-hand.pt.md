---
title: MapReduce com um pipe do Unix
version: 1
---

**O modelo inteiro cabe num comando de shell**, numa máquina e num dia de dados. Salve as duas
funções como arquivos. O mapper, `~/big/mapper.py`:

```schooling-example
{
  "language": "python",
  "file": "mapper.py",
  "parts": [
    {
      "code": "\"\"\"Map: for every event, emit its kind and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    fields = line.rstrip(\"\\n\").split(\",\")\n    print(f\"{fields[3]}\\t1\")\n",
      "note": "**Um mapper lê linhas da entrada padrão e escreve pares chave-valor na saída padrão**, com um tab entre eles. Ele vê uma linha por vez e não lembra de nada, e é isso que deixa mil cópias dele rodarem ao mesmo tempo em mil fatias do arquivo."
    }
  ]
}
```

O reducer, `~/big/reducer.py`:

```schooling-example
{
  "language": "python",
  "file": "reducer.py",
  "parts": [
    {
      "code": "\"\"\"Reduce: the input arrives sorted by key; add up each run of equal keys.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "current, total = None, 0\nfor line in sys.stdin:\n    key, value = line.rstrip(\"\\n\").split(\"\\t\")\n    if key != current:\n        if current is not None:\n            print(f\"{current}\\t{total}\")\n        current, total = key, 0\n    total += int(value)\n",
      "note": "**O reducer se apoia numa promessa: a entrada chega ordenada pela chave.** Então todo `cart` chega junto, depois todo `purchase`, e ele só precisa perceber onde termina uma sequência de chaves iguais e começa a próxima. Ele guarda um total corrente, nunca um dicionário de todas as chaves."
    },
    {
      "code": "if current is not None:\n    print(f\"{current}\\t{total}\")\n",
      "note": "A última sequência não tem próxima chave para anunciar o fim, então ela é escrita quando a entrada acaba."
    }
  ]
}
```

Depois junte-os com um pipe, com o `sort` fazendo o papel do shuffle:

```
ana@lab:~/big$ time (zcat data/raw/clicks/day=2025-03-14/*.gz | tail -n +2 | python3 mapper.py | sort | python3 reducer.py)
cart	5203
purchase	2588
search	5370
view	52592

real	0m0.137s
user	0m0.168s
sys	0m0.026s
```

**Os eventos de um dia por tipo, num piscar de olhos.** Leia o pipe da esquerda para a direita e ele
é o modelo da seção anterior: o `zcat` e o `tail` produzem os registros sem a linha de cabeçalho, o
`mapper.py` mapeia cada um para um par, o `sort` junta as chaves iguais e o `reducer.py` soma cada
sequência. O reducer só funciona porque o `sort` rodou antes; dê a ele pares fora de ordem e ele
imprime `view` muitas vezes, uma para cada sequência de visualizações que encontrar.

Nada em nenhum dos dois programas sabe de arquivos, máquinas ou HDFS. Eles leem a entrada padrão e
escrevem na saída padrão, e esse é o contrato que deixa o Hadoop rodá-los num cluster sem mudança: a
próxima seção faz isso.
