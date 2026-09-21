---
title: O `def`, o corpo, e o que volta quando nada volta
version: 1
---

```python
def saudar(nome):
    return f"olá, {nome}"

print(saudar("ada"))
```

`def`, um nome, os parâmetros entre parênteses, dois-pontos, e um corpo indentado — a mesma regra
de bloco da aula 4. Nada roda quando a linha do `def` roda; ela liga um nome a um corpo, e o corpo
espera por uma chamada.

## Definir e chamar são momentos diferentes

```python
saudar          # a própria função
saudar("ada")   # a chamada
```

**Os parênteses são a chamada.** Um nome sem parênteses é a função como valor, o que parece um
engano até a seção que faz isso de propósito.

## Uma função sem `return`

```python
def gritar(texto):
    print(texto.upper())

resultado = gritar("ada")     # resultado é None
```

Toda função devolve alguma coisa. Um corpo que chega ao fim devolve `None` — que é um valor, e não
a ausência de um, e por isso `if gritar("ada"):` é um teste que nunca passa.

**A versão mais comum disto é o `sorted` contra o `sort` da aula 3**, uma camada acima: uma função
que faz o trabalho imprimindo não tem nada para dar à linha seguinte.

## Dar nome

Um verbo, e aquilo sobre o que ele age: `carregar_linhas`, `eh_valido`, `enviar_fatura`.
`processar_dados` não diz nada; um `obter_` na frente de tudo também não diz nada.

**Uma função que precisa de um "e" no nome são duas funções.** `validar_e_salvar` é a forma que
deixa o teste desconfortável, e a aula 15 é onde essa conta chega.

## Chamar antes de definir

```python
def main():
    ajudante()        # tudo bem — esta linha roda depois

def ajudante():
    ...

main()
```

O nome é resolvido quando a chamada roda, não quando o corpo é lido. Então a ordem dentro de um
arquivo é para quem lê, com uma exceção: uma chamada no nível do módulo só alcança o que já foi
definido acima dela.
