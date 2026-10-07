---
title: Documentação que roda
version: 2
---

Escrever docstrings é a tarefa que as pessoas entregam mais contentes a um assistente: é chata, o
assistente é fluente, e ninguém lê documentação com atenção suficiente para discutir com ela. Essa
última parte é o risco. **Uma docstring faz afirmações sobre o código, e uma afirmação errada e
fluente é acreditada** pela próxima pessoa, que não tem motivo para conferir.

O Python tem um jeito de tornar algumas dessas afirmações conferíveis. Um exemplo de docstring
escrito como uma sessão interativa (`>>>` e a saída esperada) é um **doctest**, e o pytest
consegue rodá-lo.

## Pedindo uma docstring

A ana pede três exemplos para a docstring do `format_price`, e pede um valor negativo entre eles,
porque um caso de borda é para isso que um exemplo serve. Um modelo pequeno é bem mais confiável
quando lhe pedem três linhas do que uma docstring inteira, então é isso que ela pede, e o `--write`
guarda o bloco de código da resposta:

```
ana@dev:~/shop$ python scratch/assist.py ask "Write three doctest examples for format_price, one of them with a negative amount. Reply with only the >>> lines and the results, in one block of code." --open shop/money.py --write scratch/examples.txt > /dev/null
context sent (137 of 3000 tokens):
    137  shop/money.py
---
ana@dev:~/shop$ cat scratch/examples.txt
>>> format_price(1290)
'12.90'

>>> format_price(-1290)
'-12.90'

>>> format_price(1000)
'10.00'
```

Três exemplos, e eles parecem os óbvios. A ana os cola na docstring e, antes de fazer commit, a
roda:

```

Three examples, and they look like the obvious ones. ana pastes them into the docstring and,
before committing it, runs it:

```

**O segundo exemplo está errado, e o código também.** A docstring diz que `-1290` centavos
deveriam virar `'-12.90'`, que é o que qualquer pessoa esperaria. A função devolve `'-13.10'`,
porque o `//` do Python arredonda para menos infinito: `-1290 // 100` é `-13` e `-1290 % 100` é
`10`. O exemplo foi escrito a partir do que a função deveria fazer, o código faz outra coisa, e
ninguém nunca tinha perguntado a ele sobre um valor negativo.

Então os exemplos do assistente acharam um bug de verdade, por acaso, e só porque foram executados.
Se a ana tivesse lido os três exemplos e feito commit, a documentação agora afirmaria algo falso
sobre o código, no único lugar onde as pessoas olham para saber o que ele faz. A aula 4 volta a esta
função e acha a classe inteira de entradas que ela erra.

## Regras para documentação gerada

- **Rode todo exemplo.** Um doctest, um trecho do README que um teste executa, um exemplo de API
  que a CI chama. Documentação que é executada não se afasta do código sem falhar.
- **Confira contra o código toda afirmação que não for exemplo**: as exceções que levanta, as
  unidades dos argumentos, o que faz com uma lista vazia. São exatamente os detalhes que um
  escritor fluente preenche por plausibilidade.
- **Prefira o motivo à paráfrase.** `"""Return the total."""` em cima de `def total()` não diz nada
  que o nome não dissesse. O que um leitor precisa de uma docstring é o que o código não consegue
  dizer: a unidade, a regra de arredondamento, por que o limite vem depois do desconto. Isso é
  conhecimento sobre o projeto, e o assistente só o tem se você o puser no contexto.
