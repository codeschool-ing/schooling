---
title: Os cinco dublês lado a lado
version: 1
---

Os nomes vêm do livro *xUnit Test Patterns*, de Gerard Meszaros, e vale mantê-los separados porque
cada um responde a uma pergunta diferente sobre um colaborador. Eis os cinco contra as quatro coisas
que um dublê pode fazer:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma grade dos cinco dublês de teste contra quatro capacidades. Um dummy não tem nenhuma. Um stub responde com valores definidos antes. Um spy responde e também registra as chamadas. Um mock responde, registra e confere as chamadas por conta própria. Um fake responde e funciona de verdade, com comportamento próprio, sem registrar nem conferir chamadas.\"><text x=\"220.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">responde com</text><text x=\"220.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">valores definidos antes</text><text x=\"360.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">registra</text><text x=\"360.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as chamadas</text><text x=\"500.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">confere as</text><text x=\"500.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">chamadas sozinho</text><text x=\"640.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">funciona de verdade,</text><text x=\"640.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por um atalho</text><text x=\"134\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">dummy</text><rect x=\"156\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"296\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"436\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"576\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><text x=\"134\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">stub</text><rect x=\"156\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"296\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"436\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"576\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><text x=\"134\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">spy</text><rect x=\"156\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"296\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"436\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"576\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><text x=\"134\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">mock</text><rect x=\"156\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"296\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"436\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"576\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><text x=\"134\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fake</text><rect x=\"156\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text><rect x=\"296\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"436\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não</text><rect x=\"576\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sim</text></svg>", "caption": "Cada dublê se define pelo que faz, não pela biblioteca que o constrói: um mesmo objeto Mock pode fazer papel de stub, spy e mock no mesmo teste."}
```

Leia o desenho da esquerda para a direita como capacidade crescente, e pelos exemplos da aula:

| dublê | no shipquote | o que o teste verifica |
|---|---|---|
| dummy | `mailer=None` no teste de recusa | nada sobre ele; não deveria ser tocado |
| stub | `StubCarrier(cents=1999)` | o resultado que `price` devolve |
| spy | `log=lines.append` | as linhas registradas, lidas pelo teste |
| mock | `create_autospec(SmtpMailer)` | as chamadas, pelos métodos do próprio mock |
| fake | `FakeOrders()` | o resultado, e o estado deixado para trás |

Todo dublê dessa tabela roda em dois arquivos, `tests/test_carrier.py` e `tests/test_orders.py`. Seis
testes, e nenhum toca rede, servidor de e-mail ou disco:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_carrier.py tests/test_orders.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 6 items

tests/test_carrier.py::test_the_carriers_price_wins_when_it_answers PASSED [ 16%]
tests/test_carrier.py::test_the_table_is_used_when_the_carrier_is_down PASSED [ 33%]
tests/test_carrier.py::test_the_fallback_is_logged_with_the_reason PASSED [ 50%]
tests/test_carrier.py::test_a_free_order_never_asks_the_carrier PASSED   [ 66%]
tests/test_orders.py::test_placing_an_order_sends_exactly_one_confirmation PASSED [ 83%]
tests/test_orders.py::test_an_order_of_nothing_is_refused_before_anything_is_written PASSED [100%]

============================== 6 passed in 0.70s ===============================
```

## Escolhendo

Comece pelo assunto do teste:

- **É sobre um resultado?** Use um stub para montar a cena, ou um fake quando o colaborador precisa
  lembrar de algo entre chamadas. Verifique o que voltou.
- **É sobre uma chamada que é o comportamento**, como um e-mail enviado ou uma API paga *não*
  chamada? Use um spy ou um mock, construído a partir da classe real.
- **É sobre outra coisa**, com um colaborador no caminho? Um dummy.

A falha comum é pegar um mock para tudo porque a biblioteca facilita. Um teste cheio de
`assert_called_once_with` confere *como* o código faz o trabalho, chamada por chamada. Mude o como
sem mudar o resultado, uma refatoração, e esses testes quebram. A seção 11 mostra esse custo.

**E nenhum deles é a coisa real.** Todo dublê é uma afirmação sobre como o colaborador se comporta,
escrita por alguém que pode estar errado. Quanto menos afirmações um teste faz, menos jeitos ele tem
de errar, e a seção 10 é sobre como conferir as afirmações que sobram.
