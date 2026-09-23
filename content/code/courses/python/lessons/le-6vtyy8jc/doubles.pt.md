---
title: `monkeypatch`, `mock`, e o teste que prova o mock
version: 2
---

```python
def test_total(monkeypatch):
    monkeypatch.setattr("app.rates.fetch", lambda code: 5.0)
    assert total(2, "USD") == 10.0
```

**Substitua a borda, nunca o sujeito.** `fetch` alcança a rede; `total` é o que está sendo
testado. O `monkeypatch` põe a substituição no lugar, e a desfaz quando o teste acaba seja lá o
que houve — que é a parte que um `setattr` na mão esquece.

Ele também dá conta do resto do mundo ao redor: `monkeypatch.setenv`, `delenv`, `setitem`,
`chdir`. Cada um é desfeito do mesmo jeito.

## `unittest.mock`, para quando você precisa perguntar o que foi chamado

```python
from unittest.mock import patch

def test_notify_sends():
    with patch("app.mailer.send") as send:
        mailer.notify({"email": "a@b.c"})
        send.assert_called_once_with("a@b.c", "Welcome")
```

Um `Mock` registra toda chamada. O `patch` recebe o alvo **onde ele é usado**, não onde é
definido — `app.mailer.send`, porque é esse o nome que `notify` procura.

## Três maneiras de isso dar errado

```python
with patch("app.mailer.notify") as m:      # patching the subject
    m.return_value = True
    assert mailer.notify({"email": "a@b.c"}) is True
```

Verde, para sempre, provando que um `Mock` devolve o que você mandou. Se a função sob teste é a
que está sendo substituída, o teste ficou sem nada dentro.

```python
send.called_once_with("nothing", "like it")     # passes silently
```

Um `Mock` responde qualquer atributo com outro `Mock`, então um nome que não é uma asserção é uma
chamada que se registra e não afirma nada. O Python moderno pega os quase-acertos —
`assert_called_once_wth` levanta `'assert_called_once_wth' is not a valid assertion` — mas só para
nomes que começam como uma asserção. `called_once_with` começa com `c`, e passa.

```python
with patch("app.mailer.send") as send:
    send("only one argument")               # accepted
```

Um `Mock` pelado aceita qualquer assinatura, então um teste segue passando depois de a função de
verdade ganhar um argumento obrigatório. `patch(..., autospec=True)` monta o dublê a partir da
assinatura real e levanta `TypeError: missing a required argument: 'subject'` no lugar.

## Quando não usar dublê nenhum

Uma função pura não precisa de dublê. Uma classe que você constrói em três linhas não precisa de
dublê. Recorra a um numa fronteira de verdade — a rede, o relógio, o sistema de arquivos, o
gateway de pagamento — e prefira passar um objeto simples que você escreveu a trocar um nome,
porque um objeto de verdade tem assinatura de verdade e não responde atributos de que nunca ouviu
falar.
