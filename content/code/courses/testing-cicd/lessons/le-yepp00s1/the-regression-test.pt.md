---
title: O teste que teria pegado
version: 1
---

O incidente acabou: o 1.6.0 foi parado, o 1.6.1 o substituiu. Falta um passo, e é o que mais vezes
fica para trás. A correção do 1.6.1 foi de um caractere:

```
ana@laptop:~/shipquote$ git diff v1.6.0 v1.6.1 -- shipquote/quote.py
diff --git a/shipquote/quote.py b/shipquote/quote.py
index 0f1652b..860102b 100644
--- a/shipquote/quote.py
+++ b/shipquote/quote.py
@@ -10,7 +10,7 @@ FREE_FROM = 19900         # an order of R$ 199,00 or more ships free
 # Business days to deliver, by the first two digits of the CEP: the state.
 DAYS = {**{p: 1 for p in range(1, 20)},      # São Paulo
         **{p: 2 for p in range(20, 40)},     # Rio, Espírito Santo, Minas
-        **{p: 4 for p in range(40, 57)},     # Bahia to Pernambuco
+        **{p: 4 for p in range(40, 58)},     # Bahia to Alagoas
         **{p: 5 for p in range(58, 66)},     # Paraíba to Maranhão
         **{p: 6 for p in range(66, 70)},     # the North
         **{p: 3 for p in range(70, 80)},     # the Centre-West
ana@laptop:~/shipquote$ git checkout -q v1.6.0 -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state
F                                                                        [100%]
=================================== FAILURES ===================================
_______________ test_every_state_prefix_has_a_delivery_estimate ________________

    def test_every_state_prefix_has_a_delivery_estimate():
        missing = [p for p in range(1, 100) if p not in DAYS]
>       assert missing == []
E       assert [57] == []
E         
E         Left contains one more item: 57
E         Use -v to get more diff

tests/test_quote.py:52: AssertionError
=========================== short test summary info ============================
FAILED tests/test_quote.py::test_every_state_prefix_has_a_delivery_estimate
1 failed, 15 deselected in 0.64s
ana@laptop:~/shipquote$ git checkout -q HEAD -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state
.                                                                        [100%]
1 passed, 15 deselected in 0.14s
```

O segundo comando põe o `quote.py` do 1.6.0 de volta na árvore de trabalho e roda o teste que o
1.6.1 acrescentou junto com a correção, `test_every_state_prefix_has_a_delivery_estimate`. Ele falha,
e a mensagem diz exatamente o que estava errado: falta o prefixo 57. O terceiro comando restaura o
arquivo corrigido e o teste passa. Um teste de regressão se prova nos dois sentidos: **vermelho no
código com o bug, verde no código sem ele**. Um teste que nunca foi visto falhando pode não testar
nada.

## Por que este teste, e não outro

O 1.6.0 tinha um teste parametrizado, `test_delivery_takes_the_days_of_the_state`, com um CEP para
cada uma de quatro regiões. Ele passou, porque nenhum dos quatro exemplos era em Alagoas. O teste
conferia exemplos; o bug estava num intervalo. O teste de regressão confere a propriedade: **todo**
prefixo de 01 a 99 tem estimativa. Não importa que estado falta, ele teria pegado o 57, ou o 58, ou
qualquer buraco que uma edição futura deixe na tabela.

Isso é o teste baseado em propriedades da aula 3 em miniatura, e responde à pergunta que deveria vir
depois de todo incidente: que tipo de teste teria pegado isto, e a suíte agora tem um?

## A outra lacuna que o incidente mostrou

O smoke test aprovou o 1.6.0, porque só pedia `/health` e `/version`. Um smoke test que pedisse uma
cotação para cada região também não teria pegado Alagoas, mas teria pegado um release que não
conseguisse cotar nada. Acrescentar uma verificação é uma decisão de custo: cada uma deixa todo
deploy mais lento. O teste de regressão mora na suíte, onde custa milissegundos e roda a cada commit.
