---
title: Pegando um workflow quebrado antes de rodar
version: 2
---

Um erro num arquivo de workflow sai caro de achar pelo caminho de sempre: push, esperar um runner,
ler uma falha, corrigir, push de novo. Alguns erros nem falham. Uma expressão com erro de digitação
vira uma string vazia, e um passo roda em silêncio com nada onde deveria haver um valor.

Eis dois erros de digitação feitos de propósito: `matrix.pyton` no lugar de `matrix.python` no job
suite, e `cache-dependancy-path` no lugar de `cache-dependency-path` no job fast. Faça os dois em
`.github/workflows/ci.yml`, rode o actionlint de novo e ponha o arquivo de volta depois com
`git checkout .github/workflows/ci.yml`:

```
ana@laptop:~/shipquote$ actionlint; echo "exit status $?"
.github/workflows/ci.yml:43:31: property "pyton" is not defined in object type {python: number; tz: string} [expression]
   |
43 |           python-version: ${{ matrix.pyton }}
   |                               ^~~~~~~~~~~~
exit status 1
```

**Um dos dois foi pego.** O actionlint conhece a forma da matriz, um objeto com `python` e `tz`, então
`pyton` é uma propriedade que não existe. No GitHub a expressão teria virado uma string vazia, e o
`setup-python` teria recebido uma versão vazia, então o erro apareceria como uma mensagem confusa da
action, depois de um runner gasto nisso.

**O outro não.** Um input de action escrito errado é algo que o actionlint só confere para actions de
que tem dados, e ele não apontou este. No GitHub a execução seguiria, e a action ignoraria o input
desconhecido com um aviso no log, então o cache passaria a ter outra chave em silêncio. Todo
verificador tem bordas, e a borda aqui é a mesma da aula 4: **uma verificação que não achou nada não
provou que não há nada.**

## Onde rodá-lo

Um verificador de workflow é barato o bastante para rodar onde todas as outras verificações rodam:
como primeiro passo do próprio workflow, e antes de um commit, na máquina de quem escreve. Trate os
achados dele como um teste falhando. Um verificador cujos avisos são sempre ignorados vira uma linha
de log que ninguém lê, e é assim que uma expressão que vira nada chega à `main`.

O GitLab oferece a mesma ideia de outra forma: todo projeto tem uma página de **CI lint** e uma API
que valida o `.gitlab-ci.yml` contra a configuração do próprio projeto, que é o equivalente mais
próximo. A seção 10 roda de verdade o arquivo do GitLab do laboratório, o que é uma verificação mais
forte que as duas.
