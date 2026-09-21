---
title: O desvio que ninguém enxerga
version: 1
---

```python
@so_admin
def apagar_tudo():
    ...
```

Leia o corpo. Nada nele diz que uma permissão é conferida, o que acontece quando a conferência
falha, ou qual permissão é. **A linha mais importante desta função não está nesta função**, e ela
está acima do `def`, onde quem lê o corpo não vai olhar.

## A regra

**Um decorador está certo quando ele envolve a CHAMADA e errado quando ele decide a RESPOSTA.**

Em volta da chamada: cronometrar, repetir, cachear, registrar em log, abrir uma transação,
registrar a função em algum lugar. Essas são coisas que acontecem e não mudam o que a função
significa.

Decidir a resposta: retornar antes, escolher outra implementação, engolir uma exceção, mudar o
resultado. Essas são ramificações, e uma ramificação pertence ao lugar em que quem lê vai
encontrá-la.

## O argumento que teria sido mais claro

```python
@repetir(vezes=3)
def buscar(url): ...

def buscar(url, vezes=3): ...    # o mesmo comportamento, visível na assinatura
```

Quando o envolvimento é pequeno e a função é sua, um parâmetro diz isso onde dá para ler. O
decorador vence quando o mesmo envolvimento está em nove funções — e perde quando está em uma.

## O custo na depuração

Um traceback através de uma função decorada tem quadros a mais, e uma pilha de três tem três. O
`functools.wraps` mantém os nomes honestos, e nada mantém a pilha curta.

**Todo decorador é uma camada entre o que alguém lê e o que de fato roda.** Isso vale a pena no
caso das nove funções e não vale a pena por esperteza.

## E o teste

Se você não consegue dizer o que o decorador faz numa frase curta, sem "e", ele está fazendo duas
coisas — e a segunda é a que vai surpreender alguém.
