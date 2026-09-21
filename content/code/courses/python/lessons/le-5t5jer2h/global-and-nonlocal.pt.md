---
title: Duas palavras-chave, e o que precisar de uma costuma dizer
version: 1
---

```python
contagem = 0

def somar():
    global contagem
    contagem += 1
```

`global` diz que o nome é do módulo. Sem ela a atribuição tornaria `contagem` local e o valor do
módulo nunca se moveria.

```python
def contador():
    n = 0
    def passo():
        nonlocal n        # o n da função de fora, não o do módulo
        n += 1
        return n
    return passo
```

`nonlocal` diz que o nome é da função ENVOLVENTE mais próxima. Ela não alcança o nível do módulo, e
se não existir tal nome o arquivo não compila — um `SyntaxError`, levantado quando o módulo é lido e
antes de uma única linha dele rodar. Essa é a falha boa: um erro de digitação no nome é pego sem
ninguém chamar nada.

## Por que elas são raras

Uma função que muda um nome de nível de módulo tem um efeito que a assinatura dela não menciona.
Duas coisas decorrem disso, e as duas são comuns em vez de teóricas:

- **o resultado dela depende do que rodou antes**, então um teste precisa montar o mundo e desmontar
- **duas delas são difíceis de ler juntas**, porque a ligação entre as duas é um nome num terceiro
  lugar

A alternativa de sempre é receber o valor e devolvê-lo:

```python
def somar(contagem):
    return contagem + 1
```

Agora quem chama decide o que acontece com o resultado, e nada na função depende do histórico.

## Onde `global` está bem

Uma constante de módulo, escrita uma vez na importação e nunca mais atribuída, não precisa de
palavra-chave nenhuma — ler é de graça. Um cache de processo único ou um registro preenchido na
partida é o caso em que o `global` ganha a linha dele, e **ele merece um comentário dizendo por
quê**, porque quem ler depois vai supor que foi acidente.

O `nonlocal` tem uma casa que vale conhecer: um fechamento que guarda estado entre chamadas, que é a
forma com que a aula 12 constrói decoradores.
