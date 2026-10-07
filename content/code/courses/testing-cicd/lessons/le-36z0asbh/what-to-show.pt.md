---
title: O que um teste deve mostrar, e o que deve esconder
version: 2
---

Fábricas escondem dados. Esse é o propósito delas, e dá para exagerar. Um teste é lido muito mais
vezes do que é escrito, em geral por alguém tentando entender por que ele acabou de falhar, e essa
pessoa precisa ver **todo valor do qual o resultado depende**, e nenhum dos que não importam.

## O convidado misterioso

A falha clássica tem nome, o **convidado misterioso** (*mystery guest*): um teste cujo resultado
depende de dados definidos num lugar que quem lê não vê. Suponha que o peso padrão da fábrica fosse
o que decide um teste sobre faixas de peso:

```python
def test_a_heavy_parcel_pays_two_extra_bands():
    q = a_quote()
    assert freight(q["cep"], q["weight_g"], 5000) == 2190
```

O teste passa, e ninguém que o lê sabe dizer por que 2190 está certo. A resposta depende de 1200 g,
que mora em outro arquivo. Mude o peso padrão da fábrica para 800 g por causa de outro teste, e este
falha por um motivo que as próprias linhas dele não mostram. **Um valor do qual a verificação depende
pertence ao teste.** A correção é um argumento, `a_quote(weight_g=1200)`, ou fábrica nenhuma.

## Detalhe irrelevante

A falha oposta é um teste que escreve tudo por extenso:

```python
def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    assert store.get(quote_id)["cents"] == 2190
```

Esse é o teste do store como a aula 1 o escreveu, e não está errado. Mas quem lê precisa descobrir
qual dos quatro valores importa. Só o `2190` importa: aparece na chamada e na verificação. A versão
com fábrica, `a_quote(cents=2190)`, diz isso diretamente.

## A regra

Entre as duas, uma regra decide cada valor:

| o valor | onde ele fica |
|---|---|
| a verificação depende dele | no teste, pelo nome |
| precisa ser válido, e qualquer valor válido serve | no padrão da fábrica |
| precisa ser diferente do de outro teste | gerado pela fábrica |

Uma conferência útil ao revisar um teste: **cubra o arquivo da fábrica com a mão e leia o teste.**
Se ainda dá para dizer por que o valor esperado está certo, o teste mostra o suficiente. Se for
preciso abrir a fábrica, há um convidado misterioso escondido lá.

## Nomes também carregam dados

A tabela da seção 08 dá a cada linha um id montado a partir dos próprios dados, `69005-010-5000g`,
para uma falha dizer qual caso quebrou sem abrir o CSV. O nome ou o id de um teste é a primeira coisa
que quem lê o log de um pipeline vê, e vale gastar alguns caracteres nele.
