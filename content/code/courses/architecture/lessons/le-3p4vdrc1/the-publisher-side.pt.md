---
title: O lado do publicador: confirmações e devoluções
version: 1
---

Tudo até aqui supôs que a mensagem chegou ao broker. Um publicador tem dois jeitos de perder uma antes
de qualquer consumidor entrar na história, e a aula 6 mostrou um deles acontecendo: **uma mensagem
publicada numa exchange sem ligação que bata é descartada**, e por padrão ninguém fica sabendo.

O outro é o broker falhar entre receber uma mensagem e guardá-la. Um `basic_publish` simples escreve num
socket e retorna; se o broker cai um instante depois, o publicador já seguiu em frente.

O `publish.py` liga dois recursos que fecham as duas brechas:

| recurso | o que o publicador fica sabendo |
| --- | --- |
| **confirmações do publicador**, `confirm_delivery()` | o broker assumiu a responsabilidade pela mensagem: guardada em toda fila para onde foi roteada, em disco para uma fila durável e uma mensagem persistente |
| **mandatory**, `mandatory=True` | a mensagem não bateu com nenhuma fila, e o broker a está devolvendo em vez de descartar |

Com os dois, a biblioteca cliente espera a resposta do broker a cada publicação. Um pagamento publicado
com a chave certa é confirmado; um publicado com uma chave a que nada está ligado volta como um erro sobre
o qual o script pode agir:

```
ana@vm:~/lab/delivery$ $R publish.py q-3 990 refunds
returned by the broker, no queue for key 'refunds': q-3
```

`q-3` foi mandado com a chave de roteamento `refunds`, a que nenhuma fila está ligada na exchange
`payments`, e o broker o devolveu. **O publicador agora sabe**, e pode registrar, alertar, ou guardar para
tentar depois, em vez de acreditar que um reembolso estava a caminho.

## O que as confirmações custam

Uma confirmação é uma ida e volta por mensagem, ou por lote quando a biblioteca confirma em lotes, então
uma publicação confirmada é mais lenta do que uma sem confirmação. Em geral é a troca certa para qualquer
coisa que importe, e ainda não basta sozinha: as confirmações dizem ao publicador se o broker tem a
mensagem, e nada sobre se o banco do próprio publicador gravou a mudança que a mensagem anuncia. Essa
brecha é o assunto da próxima seção.
