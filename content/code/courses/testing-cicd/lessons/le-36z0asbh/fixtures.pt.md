---
title: Fixtures, montadas e desmontadas
version: 1
---

Todo teste precisa de um mundo para rodar: um banco com esquema, um servidor escutando numa porta,
um arquivo num lugar conhecido. O código que monta esse mundo e o remove depois se chama
**fixture**. Escrevê-lo dentro de cada teste enterra o objetivo do teste debaixo da preparação;
escrevê-lo uma vez e compartilhar é para isso que servem as fixtures.

No pytest uma fixture é uma função decorada com `@pytest.fixture`. Um teste a pede citando o nome
dela como parâmetro, e o pytest roda a fixture antes e passa o que ela devolve. A fixture do store
do `shipquote`, em `tests/conftest.py`, tem cinco linhas:

```schooling-example
{
  "language": "python",
  "file": "tests/conftest.py",
  "parts": [
    {
      "code": "@pytest.fixture\ndef store(tmp_path):\n    s = Store(tmp_path / \"quotes.db\")",
      "note": "Preparação: um arquivo SQLite novo dentro de `tmp_path`, um diretório que o pytest cria só para este teste. `tmp_path` também é uma fixture, e é assim que fixtures se combinam: esta pede aquela pelo nome."
    },
    {
      "code": "    yield s",
      "note": "`yield` entrega o store ao teste e fica parado aqui enquanto o teste roda."
    },
    {
      "code": "    s.close()",
      "note": "Desmontagem: o que vem depois do `yield` roda depois do teste, **tenha ele passado ou falhado**, então a conexão é fechada de qualquer jeito."
    }
  ]
}
```

`conftest.py` é um arquivo que o pytest lê antes dos testes do diretório, então uma fixture definida
nele fica disponível para todo arquivo de teste ao lado, sem import.

## Vendo acontecer

`--setup-show` imprime cada fixture enquanto ela é montada e desmontada, em volta de cada teste:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py --setup-show -q

SETUP    S tmp_path_factory
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_a_saved_quote_comes_back_by_id (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_recent_lists_the_newest_first (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
TEARDOWN S tmp_path_factory
3 passed in 0.65s
```

Leia como um aninhamento. `tmp_path_factory`, marcada `S` de sessão, é montada uma vez no começo e
desmontada uma vez no fim. Dentro dela, **cada teste recebe um `tmp_path` novo e um `store` novo**,
marcados `F` de função, e os dois são desmontados antes de o próximo teste começar. Três testes,
três bancos, nenhum compartilhado.

## O que uma fixture compra

Duas coisas, e a segunda importa mais que a primeira.

**Menos repetição.** Os três testes do store abririam cada um uma conexão, criariam o esquema e
fechariam. São três cópias das mesmas linhas, e três lugares para esquecer o fechamento.

**Isolamento por padrão.** Como a fixture do store tem escopo de função, nenhum teste vê as linhas
de outro. Um teste que passa sozinho também passa em qualquer ordem, ao lado de qualquer outro. A
seção 03 mostra o que acontece quando essa garantia é trocada por velocidade, e por que a troca
tenta.

Uma fixture também é onde a limpeza fica confiável. O código depois do `yield` roda mesmo quando o
teste falha, e um `close()` no fim do corpo do teste não: uma verificação que falha para o teste
naquela linha, e tudo abaixo dela é pulado.
