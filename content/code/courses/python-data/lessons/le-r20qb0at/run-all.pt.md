---
title: Reiniciar e rodar tudo, antes de confiar
version: 1
---

**O hábito é um item de menu: Kernel, Restart Kernel and Run All Cells…** Ele joga fora a memória
do kernel, inicia um novo e roda cada célula na ordem da página. Se o notebook der as mesmas
respostas, a página e o kernel concordam, e o notebook é um documento e não uma lembrança de uma
sessão. Se parar com um erro, você achou agora a célula fora de ordem ou a variável oculta, em vez
de outra pessoa achar depois.

Faça isso em três momentos: **antes de gravar um notebook que você vai compartilhar**, **antes de
acreditar num resultado a ponto de agir sobre ele** e **sempre que acabou de apagar ou mover uma
célula**. Custa o tempo que o notebook leva para rodar, que para tudo neste curso são segundos.

O notebook da Ana de duas seções atrás, corrigido. A configuração foi para o topo, com as outras
coisas de que o notebook depende:

```py
import csv
limit = 10
```

```py
with open("weather.csv") as f:
    days = list(csv.DictReader(f))
```

```py
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
```

## A mesma conferência, pelo terminal

Um notebook pode ser rodado de cima a baixo sem navegador nenhum, que é como você confere um que
alguém mandou antes de abri-lo, e como uma máquina confere um por você. `jupyter execute` inicia um
kernel novo, roda cada célula em ordem e para no primeiro erro:

```
(.venv) ana@lab:~/pydata$ jupyter execute fixed.ipynb
[NbClientApp] Executing fixed.ipynb
[IPKernelApp] WARNING | Kernel is running over TCP without encryption. All communication (including code and outputs) is sent in plain text and is susceptible to eavesdropping. Use IPC transport or launch with kernel manager-provisioned CurveZMQ keys to enable transport encryption.
[NbClientApp] Executing notebook with kernel: python3
```

Linhas de log e nenhum erro: cada célula rodou, num kernel que nunca tinha visto nenhuma delas. O
`WARNING` é sobre como o kernel conversa com o programa que o iniciou, por uma porta de rede no seu
próprio computador e não por um canal criptografado. Num computador que só você usa, não muda nada;
num servidor em que outras pessoas entram, é uma pergunta para quem cuida desse servidor.

Rodado no notebook quebrado, o mesmo comando para onde o `nbconvert` parou na seção anterior, no
`NameError`. O `jupyter execute` não grava o que rodou; `jupyter nbconvert --to notebook --execute
--inplace` roda o notebook do mesmo jeito e escreve as saídas de volta no arquivo, para que os
contadores gravados fiquem `1`, `2`, `3`:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to notebook --execute --inplace fixed.ipynb
[NbConvertApp] Converting notebook fixed.ipynb to notebook
[IPKernelApp] WARNING | Kernel is running over TCP without encryption. All communication (including code and outputs) is sent in plain text and is susceptible to eavesdropping. Use IPC transport or launch with kernel manager-provisioned CurveZMQ keys to enable transport encryption.
[NbConvertApp] Writing 2014 bytes to fixed.ipynb
(.venv) ana@lab:~/pydata$ python -c 'import json; nb = json.load(open("fixed.ipynb")); print(*[(c["execution_count"], c["source"][-1], c["outputs"][-1]["data"]["text/plain"] if c["outputs"] else []) for c in nb["cells"]], sep="\n")'
(1, 'limit = 10', [])
(2, '    days = list(csv.DictReader(f))', [])
(3, 'len(wet)', ['63'])
```

**Um notebook cujos contadores vão de `1` a `n` sem buraco foi rodado uma vez, de cima, num só
kernel.** É esse o notebook para entregar a alguém, e é o único tipo que a aula 21 transforma num
script.

## O que reiniciar não conserta

Não conserta um arquivo que mudou por baixo, nem uma biblioteca que foi atualizada: estão fora do
kernel, e um reinício os lê como estão agora. Também não conserta a aleatoriedade. Um notebook que
sorteia números sem semente dá números novos a cada execução, de cima ou não; a aula 8 é sobre
isso. Reiniciar e rodar tudo prova que a página é coerente consigo mesma, o que é necessário e não
é o mesmo que reproduzível.
