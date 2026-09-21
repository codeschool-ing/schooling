---
title: Contar operações, não segundos
version: 1
---

```python
def contem(itens, alvo):
    for item in itens:          # uma vez por item, no pior caso
        if item == alvo:
            return True
    return False
```

**Segundos são propriedade da máquina.** A mesma função é mais rápida num laptop mais novo, mais
lenta sob um profiler, e diferente de novo no dia em que outra coisa está compilando. Nada disso é
propriedade do código.

Então a medida é **como o trabalho cresce com a entrada**. Chame o tamanho da entrada de `n`. A
função acima faz no máximo `n` comparações, então o custo dela é `O(n)`: dobre os dados, dobre o
trabalho.

## O que é `n`

O que quer que esteja crescendo. A quantidade de linhas, de arquivos, de usuários, de caracteres
numa string. Uma função pode ter dois — `O(n × m)` para um laço sobre clientes dentro de um laço
sobre pedidos — e nomeá-los é a maior parte da análise.

## Por que a constante é descartada

```python
for item in itens:
    x = item * 2
    y = x + 1
    total += y          # três operações por item, não uma
```

Isso é `3n`, e se escreve `O(n)`. A constante é descartada porque ela depende da máquina, do
interpretador e das linhas exatas — e porque **a forma é o que sobrevive a uma mudança de
escala**. Em `n = 1.000.000`, um algoritmo `3n` e um `n` são os dois um arredondamento ao lado de
um `n²`.

O mesmo argumento descarta os termos menores: `n² + 5n + 200` é `O(n²)`, porque em um milhão o
termo `n²` é um milhão de vezes maior que o resto junto.

## Pior caso, e por quê

`O` descreve o **pior caso** a menos que algo diga o contrário. O `contem` volta na hora quando o
alvo é o primeiro da lista, e isso é `O(1)` num dia bom — mas um custo com que você só pode contar
quando tem sorte não é um custo com que você pode contar.

## O que ele ignora de propósito

```python
dados[i]               # O(1)
algum_set.add(x)       # O(1)
```

Os dois são `O(1)` e um é várias vezes o outro. O Big-O diz que eles se comportam do mesmo jeito
conforme os dados crescem, e não diz nada sobre qual é mais rápido hoje. **É essa a troca**: ele
joga fora tudo o que é específico da máquina para o que sobra ser verdade em toda parte, que é
também por que ele nunca substitui uma medição.
