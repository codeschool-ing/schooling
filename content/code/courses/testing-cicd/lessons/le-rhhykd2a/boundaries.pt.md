---
title: Escolhendo entradas nas bordas
version: 1
---

Um teste confere as entradas que você deu e nenhuma outra, então **escolher as entradas é a maior
parte de escrever um teste.** Duas técnicas fazem quase todo o trabalho, e as duas vêm da mesma
observação: defeitos se juntam onde o comportamento muda.

## Classes de equivalência

Divida as entradas possíveis em grupos que o código deveria tratar do mesmo jeito. Para a regra de
frete grátis há dois grupos: subtotais abaixo de R$ 199,00, que pagam frete, e subtotais de
R$ 199,00 ou mais, que não pagam. Qualquer valor dentro de um grupo serve tanto quanto outro para
dizer se o grupo é tratado; testar 5.000 e 6.000 centavos não acrescenta nada que 5.000 sozinho já
não dissesse.

Para um CEP as classes são menos óbvias, e esse é o valor de listá-las: oito dígitos, oito dígitos
com hífen, curto demais, longo demais, com uma letra no meio. O `shipquote` testa um caso inválido
fácil de esquecer: `0131O-100`, em que o quinto caractere é a letra O maiúscula, não um zero. Um
formulário preenchido por uma pessoa produz exatamente isso.

## Valores de borda

Dentro de cada classe, os valores encostados na borda são os que mais provavelmente estão errados,
porque a borda é onde alguém escreveu `>` ou `>=`. Então teste **o último valor de uma classe e o
primeiro da seguinte**: 19.899 e 19.900 centavos. Um terceiro valor logo depois da borda, 19.901,
confirma que a regra vale além do ponto.

Para ver o que isso compra, eis a comparação em `freight` trocada de `>=` para `>`, o tipo de deslize
que sobrevive à revisão de código porque os dois leem como "199 ou mais":

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote.py -q
.......F...                                                              [100%]
=================================== FAILURES ===================================
____________ test_an_order_of_199_reais_or_more_ships_free[19900-0] ____________

subtotal = 19900, cents = 0

    @pytest.mark.parametrize("subtotal, cents", [
        (FREE_FROM - 1, 1290),
        (FREE_FROM, 0),
        (FREE_FROM + 1, 0),
    ])
    def test_an_order_of_199_reais_or_more_ships_free(subtotal, cents):
>       assert freight("01310-100", 300, subtotal) == cents
E       AssertionError: assert 1290 == 0
E        +  where 1290 = freight('01310-100', 300, 19900)

tests/test_quote.py:27: AssertionError
=========================== short test summary info ============================
FAILED tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19900-0]
1 failed, 10 passed in 0.15s
```

Uma linha de três falha, e é a linha **na** borda: um pedido de exatamente R$ 199,00 agora paga
R$ 12,90. A linha `where 1290 = freight('01310-100', 300, 19900)` mostra a chamada e o que ela
devolveu. Um teste que usasse R$ 250,00 como exemplo de "grátis" continuaria passando, e o teste de
aceitação da seção 11 também, se tivesse usado R$ 200,00 redondos. O cliente que gasta exatamente o
valor anunciado descobriria primeiro.

## Um checklist que pega quase tudo

Para qualquer entrada, pergunte quais são as classes e onde elas se encontram. Algumas bordas
aparecem de novo e de novo:

| tipo de entrada | valores que valem tentar |
|---|---|
| um número com limite | o limite, um abaixo, um acima |
| uma quantidade | zero, um, o maior permitido, um a mais que ele |
| um texto | vazio, um caractere, o tamanho máximo, não ASCII (`São`) |
| uma lista | vazia, um elemento, muitos, repetidos |
| uma data ou hora | meia-noite, um horário de corte, um fim de semana, uma troca de fuso |

A última linha não é enfeite. O `shipquote` decide o dia de despacho por um corte às 14:00, e a
aula 5 mostra essa regra passando numa máquina e falhando em outra por causa de onde a máquina acha
que está.

**Bordas também são um motivo para ler o requisito duas vezes.** "Pedidos acima de R$ 199,00 têm
frete grátis" e "pedidos de R$ 199,00 ou mais têm frete grátis" só diferem na borda, e só um teste
na borda obriga alguém a decidir qual dos dois o negócio quis dizer.
