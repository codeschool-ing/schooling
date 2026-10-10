---
title: Quóruns: quantas réplicas precisam responder
version: 1
---

**Sem um líder, um cliente manda cada escrita para várias réplicas e cada leitura para várias
réplicas, e três números decidem se uma leitura tem certeza de ver a última escrita.** A imagem
errada é a de que toda réplica precisa confirmar toda escrita. Isso deixaria o sistema tão frágil
quanto a sua máquina menos confiável. Um **quórum** é o número de réplicas que basta.

Os três números:

- **N**, quantas réplicas guardam cada dado;
- **W**, quantas precisam confirmar uma escrita para ela contar como feita;
- **R**, quantas são consultadas numa leitura, que então fica com a resposta de versão mais nova.

**Se R + W for maior que N, todo grupo de R réplicas tem pelo menos uma réplica em comum com todo
grupo de W.** Com N = 3, W = 2 e R = 2, uma escrita chegou a duas das três e uma leitura consulta duas
das três; não há como escolher duas de três que deixem de fora as duas escritas. Pelo menos uma das
réplicas consultadas tem o valor novo, e o número da versão diz qual.

O programa abaixo testa isso. A bicicleta B044 estava na ST04, e uma escrita a passa para a ST06 com
um número de versão maior. A escrita chega a W das três réplicas, e o programa então tenta todo grupo
possível de R réplicas que uma leitura poderia consultar, e conta quantas dessas leituras veem a ST06.
Salve como `quorum.py`:

```python
# spread/quorum.py
from itertools import combinations

N = 3


def run(w, r):
    replicas = [{"version": 1, "station": "ST04"} for _ in range(N)]
    for replica in replicas[:w]:            # the write reached w replicas
        replica.update(version=2, station="ST06")
    reads = list(combinations(replicas, r))  # every way of asking r of them
    fresh = sum(max(chosen, key=lambda x: x["version"])["station"] == "ST06"
                for chosen in reads)
    print(f"N={N} W={w} R={r}  R+W={w + r}  {fresh} of {len(reads)} reads see ST06")


for w, r in [(1, 1), (1, 2), (2, 1), (2, 2), (3, 1), (1, 3)]:
    run(w, r)
```

```
ana@lab:~/roda/spread$ python quorum.py
N=3 W=1 R=1  R+W=2  1 of 3 reads see ST06
N=3 W=1 R=2  R+W=3  2 of 3 reads see ST06
N=3 W=2 R=1  R+W=3  2 of 3 reads see ST06
N=3 W=2 R=2  R+W=4  3 of 3 reads see ST06
N=3 W=3 R=1  R+W=4  3 of 3 reads see ST06
N=3 W=1 R=3  R+W=4  1 of 1 reads see ST06
```

A primeira linha é o perigo: uma réplica escrita e uma consultada, e só uma leitura em três encontra a
estação nova. Com R = 2 e W = 1, ou o contrário, duas em três. **Toda linha em que R + W chega a 4 diz
que toda leitura possível vê a escrita**, e as linhas só diferem em onde põem o custo.

| N = 3 | uma escrita precisa de | uma leitura precisa de | ainda funciona com uma réplica fora |
|---|---|---|---|
| W = 3, R = 1 | todas as réplicas | uma | só leituras |
| W = 1, R = 3 | uma | todas as réplicas | só escritas |
| W = 2, R = 2 | duas | duas | as duas coisas |

A última linha é o motivo de a maioria de cada lado, duas de três ou três de cinco, ser a
configuração que você mais vai encontrar. O Cassandra a chama de `QUORUM`, e deixa o cliente escolher
o nível em cada pedido.

## O que a regra não promete

A sobreposição garante que uma leitura encontre a versão mais nova. Ela deixa três coisas em aberto,
que você deve saber reconhecer:

- Alguma coisa precisa dizer qual versão é a mais nova. Aqui é um contador. Um sistema que usa a
  hora da escrita no lugar dele está confiando em relógios, e a seção 02 desta aula mostrou o
  quanto dá para confiar neles.
- Duas escritas no mesmo instante, de dois clientes para réplicas que se sobrepõem, podem deixar
  as réplicas discordando sobre qual veio por último.
- Uma escrita que chegou a menos de W réplicas é relatada como falha, e continua nas réplicas a que
  chegou. Uma leitura posterior pode encontrá-la lá.

Cada uma delas é uma pergunta sobre o que uma leitura tem permissão de devolver, e a aula 10 dá nome a
essas perguntas.
