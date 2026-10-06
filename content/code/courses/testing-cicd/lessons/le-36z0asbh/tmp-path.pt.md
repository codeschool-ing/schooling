---
title: Arquivos que pertencem a um teste
version: 1
---

Um teste que grava um arquivo precisa de um lugar para gravá-lo. As escolhas que dão errado são as
óbvias: o diretório atual, onde o arquivo fica para trás e a próxima execução tropeça nele; um
caminho fixo como `/tmp/quotes.db`, que duas execuções simultâneas dividem; ou o diretório de dados
real, onde um teste apaga algo de que uma pessoa precisava.

A resposta do pytest é `tmp_path`, uma fixture que dá a cada teste um diretório novo e vazio. Os
testes do store o usam pela fixture do store, e os bancos deles podem ser achados depois da
execução:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q
...                                                                      [100%]
3 passed in 0.18s
ana@laptop:~/shipquote$ ls /tmp/pytest-of-ana/
pytest-1
pytest-2
pytest-3
pytest-current
ana@laptop:~/shipquote$ find /tmp/pytest-of-ana/pytest-current/ -name "*.db"
/tmp/pytest-of-ana/pytest-current/test_recent_lists_the_newest_f0/quotes.db
/tmp/pytest-of-ana/pytest-current/test_the_database_refuses_a_ce0/quotes.db
/tmp/pytest-of-ana/pytest-current/test_a_saved_quote_comes_back_0/quotes.db
```

Três coisas para ler nessa listagem.

**Cada teste teve o próprio diretório**, com o nome do teste, cortado e numerado. Três testes, três
arquivos `quotes.db`, e nenhum jeito de um ver as linhas do outro.

**O diretório fica sob o nome do usuário**, `/tmp/pytest-of-ana`, então duas pessoas na mesma
máquina também não colidem.

**O pytest guarda as três últimas execuções** e apaga as mais antigas: `pytest-0`, `pytest-1` e
`pytest-current`, um link para a mais nova. É de propósito. Quando um teste falha, os arquivos que
ele gravou ainda estão lá para inspeção, e o disco não enche com todas as execuções já feitas.

## Outras coisas que um teste não deveria dividir

O mesmo raciocínio vale para tudo o que um teste pode tocar fora da própria memória:

| recurso | a versão compartilhada | a versão por teste |
|---|---|---|
| um arquivo | um caminho fixo | `tmp_path` |
| uma porta | 8080 | porta 0, escolhida pelo sistema (aula 1) |
| uma variável de ambiente | `os.environ[...] = ...` deixada definida | `monkeypatch.setenv`, desfeita depois do teste |
| o diretório atual | `os.chdir` deixado mudado | `monkeypatch.chdir` |

`monkeypatch` é a fixture que a aula 2 seção 09 citou ao lado de `mock.patch`, e este é o uso dela
no dia a dia: **mudanças desfeitas automaticamente quando o teste termina**, passando ou falhando.

Um teste que deixa algo para trás é um teste que funciona da primeira vez e falha na segunda, ou que
funciona sozinho e falha num pipeline em que o job anterior deixou um arquivo. A aula 5 mostra por
que um pipeline começa de um checkout limpo; um teste não deveria precisar disso para passar.
