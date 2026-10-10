---
title: "Aberto/fechado: estender sem editar"
version: 1
---

**O princípio aberto/fechado diz que um módulo deve estar aberto para extensão e fechado para
modificação: um caso novo entra escrevendo código novo, e não editando código que já funciona.** O
código fechado mantém seus testes, suas revisões e seus meses em produção; o caso novo chega ao lado
dele e se encaixa num ponto deixado para isso.

A leitura literal, de que código que funciona nunca pode ser editado, é impossível e ninguém quer
dizer isso. Um bug se corrige editando. Uma regra que muda é mudada onde mora. O que o princípio
mira é mais estreito: um tipo de mudança que **vive acontecendo**, em que cada ocorrência significa
abrir a mesma função e acrescentar mais um ramo nela.

## O ramo que não para de crescer

Aqui está a regra de multa escrita do jeito óbvio, como uma função que pergunta que tipo de membro
tem nas mãos:

```python
# by_kind.py
def fine(kind: str, days_late: int) -> int:
    if kind == "adult":
        return max(days_late, 0) * 50
    elif kind == "student":
        return max(days_late - 3, 0) * 50


def receipt(kind: str, days_late: int) -> str:
    return f"{kind}: {fine(kind, days_late)} cents"


if __name__ == "__main__":
    print(receipt("adult", 5))
    print(receipt("student", 5))
    print(receipt("child", 40))
    print(sum(fine(k, 40) for k in ("adult", "child")))
```

A biblioteca acabou de criar a categoria infantil, e os primeiros empréstimos estão sendo feitos
antes de alguém editar `fine`:

```
ana@laptop:~/patterns/solid-1$ python3 by_kind.py
adult: 250 cents
student: 100 cents
child: None cents
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/by_kind.py", line 17, in <module>
    print(sum(fine(k, 40) for k in ("adult", "child")))
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
```

O recibo de uma criança diz `None cents`, impresso para um membro, e o total falha uma linha depois.
A cadeia chegou ao fim e o Python devolveu `None`, como faz com qualquer função que chega à última
linha. O conserto é mais um `elif`, nesta função e em toda outra função do código que faz a mesma
pergunta: o texto do aviso, a duração do empréstimo, o limite de itens fora ao mesmo tempo. Cada
categoria nova de membro é uma busca por todas as cópias da cadeia, e a cópia esquecida é um bug
como este.

## Duas versões do princípio

Meyer enunciou o princípio em 1988 pensando em herança: uma classe está fechada depois de
publicada, e é estendida por subclasses. A lição 2 mediu quanto isso custa. A reformulação de
Martin, que é a usada hoje, põe o ponto de extensão numa **abstração**: o código fechado depende de
uma descrição do que precisa, um protocolo ou uma interface, e cada caso novo é uma nova
implementação dela. O código fechado nunca aprende o nome do caso novo.

| | Meyer, 1988 | Martin, anos 1990 |
|---|---|---|
| código fechado | uma classe publicada | código que depende de uma abstração |
| extensão | uma subclasse | uma nova implementação da abstração |
| o que o código fechado conhece | nada das suas subclasses | o protocolo, e mais nada |

## Onde deixar a abertura

O porém é que um ponto de extensão tem de ser posto **antes** de a extensão chegar, o que significa
prever que eixo vai variar. Ninguém consegue deixar um código aberto a qualquer mudança; uma função
aberta em todos os eixos é uma indireção em cada linha. A regra prática é deixar o eixo se mostrar
primeiro. Mais um `elif` numa função é um conserto barato. Quando a mesma cadeia aparece numa
segunda função, ou cada categoria nova de membro já virou uma caçada pelo código, o eixo se mostrou
e a abertura vai ali.

A próxima seção faz isso para os tipos de multa: um protocolo para a regra, uma função fechada em
relação a ele, e uma regra nova acrescentada num arquivo novo, com os arquivos antigos intocados e o
programa rodado antes e depois.
