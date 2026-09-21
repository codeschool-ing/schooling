---
title: Dez módulos, uma linha cada
version: 1
---

Você não precisa decorá-los. Você precisa lembrar que eles existem, para que da próxima vez que o
problema aparecer você olhe antes de escrever.

| módulo | para |
| --- | --- |
| `pathlib` | caminhos como objetos — juntar, testar, ler, percorrer um diretório |
| `datetime` | datas, horas, e a aritmética entre elas |
| `collections` | `Counter`, `defaultdict`, `deque`, `namedtuple` |
| `itertools` | peças para laços que de outro jeito se aninhariam |
| `json` | ler e gravar JSON — aula 9 |
| `re` | expressões regulares — aula 10 |
| `math` | raízes, logaritmos, `inf`, `isclose` |
| `random` | uma escolha, um embaralhamento, um número numa faixa |
| `os` | o ambiente, e o que o `pathlib` não cobre |
| `sys` | argumentos, códigos de saída, o caminho, os fluxos padrão |

## Mais quatro que aparecem o tempo todo

`csv` para qualquer coisa que uma planilha produziu, `statistics` para uma média ou uma mediana,
`textwrap` para quebrar e desindentar, `subprocess` para rodar outro programa.

## E a forma da pergunta

A maior parte do que quem está começando escreve à mão está aqui dentro. Alguns exemplos, cada um
deles uma seção do primeiro programa de alguém:

- contar ocorrências → `collections.Counter`
- "hoje mais trinta dias" → `datetime.timedelta`
- construir um caminho de arquivo → `pathlib.Path`
- toda combinação de duas listas → `itertools.product`
- "este número está perto o bastante" → `math.isclose`

**O teste não é se você conhece a função. É se você pensa em olhar**, e o hábito vale mais que
qualquer um dos módulos acima.

## O que NÃO está aqui

Requisições HTTP (`requests`, aula 21 — o `urllib` existe e é desagradável), data frames
(`pandas`), arrays (`numpy`), e qualquer coisa ligada à web. Essas são dependências, e a aula 18 é
onde instalar uma direito acontece.
