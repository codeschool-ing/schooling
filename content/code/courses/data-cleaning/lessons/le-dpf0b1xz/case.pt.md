---
title: Maiúsculas: para comparar, e para mostrar
version: 1
---

**Maiúsculas não carregam significado num nome de cidade, então para comparar elas não devem
contar.** `SAO PAULO`, `São Paulo` e `são paulo` são uma cidade; qualquer chave feita para agrupar ou
comparar deve juntá-las. A cascata no fim desta aula mostra que passar para minúsculas é o maior
passo isolado: leva as cidades de 21 grafias para 12.

Três funções fazem isso, e não são iguais:

```
ana@lab:~/clean$ python -c "print('Straße'.lower(), 'Straße'.casefold(), 'DA SILVA'.title(), 'mcdonald'.title())"
straße strasse Da Silva Mcdonald
```

- `lower()` troca maiúsculas por minúsculas. Basta para português e inglês.
- `casefold()` é a versão mais estrita, feita para comparar: o `ß` alemão vira `ss`, então `Straße` e
  `STRASSE` comparam iguais. Quando uma chave vai ser comparada, `casefold()` é a escolha correta;
  neste dado as duas dão o mesmo resultado.
- `title()` põe maiúscula em cada palavra, e erra com nomes: `DA SILVA` vira `Da Silva` onde o
  português escreve `da Silva`, e `mcdonald` vira `Mcdonald`. **Nenhuma regra mecânica escreve
  corretamente o nome de uma pessoa.**

## Duas colunas, não uma

Esse último ponto é o motivo de a regra principal desta aula aparecer primeiro aqui: **limpe uma
cópia para comparar, e mantenha o original para mostrar.** Uma coluna-chave — minúsculas, sem
acentos, espaços simples — é o que agrupa, junta e compara. A coluna que as pessoas leem mantém o
nome como a pessoa ou a lista canônica o escreveu. Pôr o nome em minúsculas poria `ana lima` na
próxima nota fiscal, e o `title()` poria `Ana Lima Da Silva`.

Para um valor com forma canônica fixa, como uma cidade, a coluna de exibição também não é o
original: vem de uma lista, como faz a seção sobre abreviações. Para o nome de uma pessoa, o original
é a única forma correta que existe, e a chave existe para que ninguém precise mudá-lo.
