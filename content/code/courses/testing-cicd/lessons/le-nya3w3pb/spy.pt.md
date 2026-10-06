---
title: Spy
version: 1
---

Um **spy** registra como foi usado, para o teste conferir depois. Onde um stub responde, um spy
observa: quais chamadas chegaram, em que ordem, com quais argumentos.

O spy mais simples em Python é uma lista. `price` escreve uma linha quando recorre à tabela, e
escreve por meio de `log`, que tem `print` como padrão. O teste passa `lines.append` no lugar:

```python
def test_the_fallback_is_logged_with_the_reason():
    lines = []
    stub = StubCarrier(error=CarrierError("timed out"))
    price(stub, "01310-100", 1200, 5000, log=lines.append)
    assert lines == ["carrier unavailable, using the table: timed out"]
```

O stub faz a transportadora falhar; o spy, `lines`, coleta o que `price` registrou; a verificação
compara a lista inteira. Esse último detalhe importa: **comparar a lista inteira pega uma segunda
linha inesperada**, e `"timed out" in lines[0]` não pegaria.

## Por que o log merece um teste

Uma reserva que funciona em silêncio é uma reserva que ninguém sabe que está acontecendo. Se a API
da transportadora quebrar numa sexta à noite, a loja segue cotando pela própria tabela o fim de
semana inteiro, os clientes pagam preços que a transportadora não honra, e o único rastro é aquela
linha. A regra do projeto é que **falha silenciosa é proibida**: um caminho que pode falhar precisa
dizer isso, e este teste é o que o mantém dizendo. Apague a chamada `log(...)` em `price` e este
teste fica vermelho; os outros três do arquivo continuam verdes.

## Spies nas bibliotecas

`unittest.mock.Mock` registra toda chamada feita a ele, então qualquer mock pode fazer papel de spy:

```python
mailer = mock.Mock()
place(FakeOrders(), mailer, "bia@example.org", 8990)
print(mailer.send.call_args)       # the arguments of the last call
print(mailer.send.call_count)      # how many calls
```

A diferença entre um spy e um mock, no vocabulário desta aula, é **quem confere**. Com um spy, o
teste lê o registro e faz a verificação, com as próprias palavras. Com um mock, o dublê vem com
métodos de verificação próprios. A linha é borrada na prática e as bibliotecas misturam os dois; o
que importa é que registrar chamadas é uma ferramenta para quando a chamada é o comportamento, como
uma linha de log ou um e-mail, e não para todo colaborador à vista.
