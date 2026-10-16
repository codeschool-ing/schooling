---
title: Estado oculto, e a variável cuja célula sumiu
version: 1
---

**Apagar uma célula não apaga o que ela fez.** O kernel a rodou, e o que ela atribuiu continua na
memória, disponível para toda célula depois dela, sem nada na página mostrando de onde veio. Isso é
estado oculto, e é o segundo jeito de um notebook funcionar para o autor e para mais ninguém.

Ana está contando viagens por plano. Ela testa um limite para separar corridas curtas de longas:

```python
import csv
with open("trips.csv") as f:
    trips = list(csv.DictReader(f))
short_limit = 15 * 60
len(trips)
```
```
33337
```

```python
from datetime import datetime

def minutes(trip):
    if not trip["ended_at"]:
        return None
    start = datetime.fromisoformat(trip["started_at"])
    end = datetime.fromisoformat(trip["ended_at"])
    return (end - start).total_seconds() / 60
```

Mais tarde ela decide que o limite pertence a uma função, escreve isto, e apaga da primeira célula
a linha de `short_limit`, por achá-la desarrumada:

```python
def is_short(trip):
    m = minutes(trip)
    return m is not None and m * 60 < short_limit

sum(is_short(t) for t in trips)
```
```
17919
```

Roda, porque `short_limit` continua no kernel, da linha que ela apagou. Pergunte ao kernel o que
ele guarda e a órfã está lá, listada com todo o resto, inclusive o `total` da primeira seção desta
aula, que está no mesmo notebook:

```python
%who
```
```
csv	 datetime	 f	 is_short	 minutes	 short_limit	 total	 trips	 
```

`%who` é uma **mágica** do IPython, um comando para o próprio kernel e não para o Python, escrito
com um `%` na frente. Ele lista cada nome que o notebook criou, e é o jeito mais rápido de achar
uma variável que nenhuma célula da página define. `%whos` acrescenta o tipo de cada uma e uma
visão curta do valor.

O kernel pode ser esvaziado sem reiniciar, que é o mais perto que uma célula chega de um começo do
zero:

```python
%reset -f
sum(is_short(t) for t in trips)
```
```
NameError: name 'trips' is not defined
```

Depois de `%reset -f` nada está definido, nem as funções; `trips` é só o primeiro nome faltante que
a linha encontra. Rodar a página de cima de novo é o único caminho de volta. Se ela tivesse feito
isso, a célula que usa `short_limit` falharia com `NameError` na primeira execução, que é
exatamente o que deve acontecer com um notebook que se refere a uma linha que não existe mais.
**Restart Kernel**, no menu Kernel, faz o mesmo e mais: encerra o processo Python e inicia um novo,
então até os módulos importados são carregados de novo.

## Mais dois jeitos de deixar algo para trás

**Uma função redefinida, com saídas antigas acima dela.** Mude `minutes` e rode a versão nova: as
células acima que já rodaram ficam com as saídas que receberam da antiga. A página agora mostra
resultados de duas funções diferentes com um mesmo nome.

**Um valor sobrescrito mais abaixo.** Uma célula perto do fim faz `trips = trips[:1000]` para
testar algo rápido. Toda célula rodada depois dela, inclusive as mais acima que você roda de novo,
trabalha com mil viagens, enquanto as saídas gravadas antes ainda descrevem 33.337.

Nenhum desses levanta um erro. Esse é todo o perigo deles, e o motivo de a correção ser um hábito e
não uma regra: a seção depois da próxima.
