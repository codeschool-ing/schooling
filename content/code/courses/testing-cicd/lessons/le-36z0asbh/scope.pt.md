---
title: Escopo, e o estado que vaza
version: 1
---

O **escopo** de uma fixture decide com que frequência ela é montada. O padrão, `function`, monta
para cada teste. `module` monta uma vez por arquivo de teste, `session` uma vez por execução. Um
escopo maior é mais barato, e a aula 1 mediu o motivo para querê-lo: a fixture do servidor HTTP tem
escopo de módulo porque desligar um servidor custa meio segundo, e pagar isso em cada teste
funcional multiplicaria o custo.

O preço de um escopo maior é o **estado compartilhado**. Todo teste que usa um store de escopo de
módulo grava no mesmo banco, e um teste pode então passar ou falhar conforme o que rodou antes dele.

## O pytest recusa o erro óbvio

Mude só o decorador da fixture do store para `scope="module"` e o pytest para antes de qualquer
teste rodar:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q -k saved
E                                                                        [100%]
==================================== ERRORS ====================================
____________ ERROR at setup of test_a_saved_quote_comes_back_by_id _____________
ScopeMismatch: You tried to access the function scoped fixture tmp_path with a module scoped request object. Requesting fixture stack:
tests/conftest.py:13:  def store(tmp_path)
Requested fixture:
.venv/lib/python3.13/site-packages/_pytest/tmpdir.py:290:  def tmp_path(request: 'FixtureRequest', tmp_path_factory: 'TempPathFactory') -> 'Generator[Path]'
=========================== short test summary info ============================
ERROR tests/test_store.py::test_a_saved_quote_comes_back_by_id - Failed: Scop...
2 deselected, 1 error in 0.16s
```

O store pede `tmp_path`, que é criado por teste. Uma fixture de módulo não pode depender de uma de
função, porque viveria mais que a coisa da qual foi construída, e o pytest diz isso com
`ScopeMismatch`. Essa recusa é útil: é um erro de desenho pego na preparação, e não uma falha
estranha mais tarde.

## O erro que o pytest não vê

O jeito de contornar é `tmp_path_factory`, que tem escopo de sessão e cria diretórios sob demanda.
Aqui a fixture é reescrita para usá-lo, e um teste novo é acrescentado, afirmando que um store novo
não tem cotações:

```python
def test_a_new_store_has_no_quotes(store):
    assert store.recent(10) == []
```

```
ana@laptop:~/shipquote$ git diff tests/conftest.py
diff --git a/tests/conftest.py b/tests/conftest.py
index a9a0d29..9320668 100644
--- a/tests/conftest.py
+++ b/tests/conftest.py
@@ -10,9 +10,9 @@ from shipquote.app import Handler
 from shipquote.store import Store
 
 
-@pytest.fixture
-def store(tmp_path):
-    s = Store(tmp_path / "quotes.db")
+@pytest.fixture(scope="module")
+def store(tmp_path_factory):
+    s = Store(tmp_path_factory.mktemp("db") / "quotes.db")
     yield s
     s.close()
 
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q --tb=line
...F                                                                     [100%]
=================================== FAILURES ===================================
E   assert [3, 2, 1] == []
      
      Left contains 3 more items, first extra item: 3
      Use -v to get more diff
/home/ana/shipquote/tests/test_store.py:27: assert [3, 2, 1] == []
=========================== short test summary info ============================
FAILED tests/test_store.py::test_a_new_store_has_no_quotes - assert [3, 2, 1]...
1 failed, 3 passed in 0.16s
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q -k no_quotes
.                                                                        [100%]
1 passed, 3 deselected in 0.15s
```

Rodado com os outros três, o teste novo falha: o store já tem as cotações 1, 2 e 3, gravadas pelos
testes anteriores. Rodado sozinho, com `-k no_quotes`, passa. **O mesmo teste, o mesmo código, dois
resultados, decididos pelo que mais rodou.** Repare também no que não falhou: `recent(2) == [second,
first]` continuou passando, porque as duas linhas mais novas eram por acaso as dele. Estado
compartilhado nem sempre aparece; aparece no dia em que um teste é acrescentado ou a ordem muda.

## Escolhendo um escopo

Amplie o escopo de uma fixture quando duas coisas forem verdade:

1. **Ela é cara de montar**, de forma mensurável, como o meio segundo do servidor.
2. **Os testes não conseguem alterá-la**, ou cada teste limpa completamente o que fez.

Um servidor que responde requisições e não guarda nada se qualifica. Um banco em que os testes
gravam não, a menos que cada teste desfaça as próprias gravações, e a seção 05 mostra como arranjar
isso. Na dúvida, fique com o padrão: uma suíte lenta aparece em toda execução, e uma que depende da
ordem falha ao acaso na máquina de outra pessoa.
