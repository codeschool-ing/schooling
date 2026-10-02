---
title: Peça uma resposta que um programa confira
version: 1
---

Uma resposta em prosa é lida por uma pessoa, e uma pessoa passa os olhos. **Uma resposta num formato
que uma ferramenta entende pode ser conferida antes de alguém ler**: um diff pode ser testado contra
o código, JSON pode ser interpretado e validado, um arquivo de teste pode ser rodado. Pedir esse
formato é a checagem de qualidade mais barata que existe, porque a checagem já existe.

## Um diff, conferido antes de ser aplicado

O `comma.diff` da aula 5 seção 03 é um diff unificado. O `git apply --check` o testa contra a árvore
de trabalho sem mudar nada:

```
ana@dev:~/shop$ git apply --check comma.diff && echo "applies cleanly"
applies cleanly
```

Um diff que não bate com o código, porque foi escrito contra uma versão do arquivo que não é a do
disco, ou porque uma linha dele foi inventada, é recusado do mesmo jeito. Aqui está o mesmo diff com
uma linha de contexto alterada, o tipo de deslize que um modelo comete quando cita código de memória:

```
ana@dev:~/shop$ sed 's/^-    units/-    unit/' comma.diff | git apply --check
error: patch failed: shop/money.py:3
error: shop/money.py: patch does not apply
```

**A checagem falha, e nada foi mudado.** Uma resposta que fosse a função inteira em prosa teria sido
colada por cima da verdadeira, e a diferença seria achada depois, se fosse. O diff bom entra, e a
suíte roda:

```
ana@dev:~/shop$ git apply comma.diff && python -m pytest -q
........                                                                 [100%]
8 passed in 0.48s
```

## Formatos que vale pedir

| tarefa | formato | a checagem |
|---|---|---|
| uma mudança em código existente | um diff unificado | `git apply --check`, depois os testes |
| código novo | um arquivo completo ou uma função | importa, o linter passa, os testes rodam |
| dados extraídos de um texto | JSON que segue um esquema | interpretar e validar (aula 8) |
| uma decisão | uma palavra de uma lista fixa | está na lista? |
| testes | um arquivo de teste | roda, e falha no código de antes da mudança |

**Diga "e nada mais"** quando um programa for ler a resposta. Uma resposta que começa com "Claro,
aqui está o diff:" não é um diff, e o parser que esperava um ou falha ou, pior, pula a primeira linha
e segue em frente.

A última linha merece uma frase própria: **um teste gerado deve falhar antes da mudança que ele
testa**. Um teste que passa no código antigo não confere nada do código novo, o que a aula 4 seção 04
descobriu do jeito difícil.
