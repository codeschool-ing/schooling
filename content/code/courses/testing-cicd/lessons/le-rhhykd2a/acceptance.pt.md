---
title: Testes de aceitação
version: 1
---

Um **teste de aceitação** confere uma promessa nas palavras de quem a pediu. A pergunta dele não é
"o código funciona?", e sim **"quem pediu isto aceitaria?"** A técnica costuma ser a de um teste
funcional, pela interface pública; o que muda é de onde o teste vem e quem consegue lê-lo.

A página inicial da livraria diz: *frete grátis em pedidos a partir de R$ 199,00, para todo o
Brasil*. Essa frase é um requisito escrito pelo negócio, e é a origem deste teste:

```python
"""The promise on the shop's front page, checked through the same door a
customer's browser uses: free shipping from R$ 199,00, anywhere in Brazil."""
import pytest

from tests.conftest import get

pytestmark = pytest.mark.acceptance

ONE_CEP_PER_REGION = ["01310-100", "20040-002", "40010-000",
                      "69005-010", "70040-010", "80010-000"]


def test_a_basket_of_199_reais_ships_free_to_every_region(base_url):
    # Given a basket worth exactly R$ 199,00, weighing 2.5 kg
    # When a customer in each region of Brazil asks for a quote
    # Then every one of them is told the freight is R$ 0,00
    for cep in ONE_CEP_PER_REGION:
        status, body = get(f"{base_url}/quote?cep={cep}&weight=2500&subtotal=19900")
        assert (status, body["price"]) == (200, "R$ 0,00"), cep
```

Três coisas fazem dele um teste de aceitação e não mais um funcional.

**Ele é escrito a partir do requisito, não do código.** O teste não sabe que existe uma constante
`FREE_FROM`. Manda o valor que a página inicial anuncia, de um CEP em cada região, porque "todo o
Brasil" é a afirmação.

**Os passos dele são os passos do cliente.** Os comentários *Given / When / Then* (dado, quando,
então) são uma estrutura que um dono de produto lê e corrige: se a promessa é "a partir de
R$ 199,00" e o teste diz R$ 200,00, alguém que nunca abre Python percebe. Ferramentas como Cucumber
e behave transformam essas três palavras em passos executáveis, e a trilha `qa` ensina esse estilo
na aula 16 de `qa-fundamentals`. Os comentários aqui mantêm a forma sem a ferramenta.

**A falha dele é uma falha de negócio.** Se este teste está vermelho, a loja está quebrando uma
promessa da página inicial, qualquer que seja o motivo. Isso o torna candidato a rodar por último
num pipeline, contra a aplicação implantada, o que a aula 7 chama de smoke test.

```
ana@laptop:~/shipquote$ python -m pytest -m acceptance -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 31 items / 30 deselected / 1 selected

tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region PASSED [100%]

======================= 1 passed, 30 deselected in 0.68s =======================
```

## Quantos

Testes de aceitação são o tipo mais caro de manter: lentos, amplos, e quebrados por qualquer
mudança na interface. Então **eles cobrem as promessas, não os casos.** A borda em 19.899 centavos
já está testada na camada unitária, num milissegundo. Repetir cada borda aqui deixaria a suíte
lenta e não diria nada novo. Um teste de aceitação por promessa que o negócio notaria é um bom
ponto de partida; o resto da confiança vem de baixo.

## Os quatro nomes, lado a lado

| | exercita | colaboradores | falha porque |
|---|---|---|---|
| unitário | um comportamento | nenhum fora do processo | uma regra está errada |
| integração | seu código com uma dependência real | um banco, um arquivo, um serviço | os dois lados discordam |
| funcional | a aplicação inteira, pela interface | tudo de que a aplicação precisa | a ligação está errada |
| aceitação | um requisito, nos termos do dono | a aplicação implantada | uma promessa foi quebrada |

As fronteiras se misturam na prática, e equipes discutem os rótulos. A pergunta que importa é a da
última coluna: **quando este teste falha, o que ele te diz?**
