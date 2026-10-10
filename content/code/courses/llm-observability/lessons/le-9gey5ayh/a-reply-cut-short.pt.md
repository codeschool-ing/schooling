---
title: Uma resposta interrompida
version: 2
---

Uma resposta em streaming pode parar no meio. A conexão cai, um proxy encerra por tempo uma resposta
longa, o fornecedor reinicia a máquina que a gerava. O que chega é um começo, e depois nada: nenhum
pedaço final, nenhum motivo de parada, nenhum uso.

O assistente trata um stream sem motivo de parada como uma tentativa que falhou (`IncompleteReply`),
registra quantos pedaços recebeu, e tenta de novo. O flaky.py pode ser instruído a cortar o próximo
stream depois de seis pedaços, com o SDK ainda apontado para ele desde a seção anterior:

```
ana@dev:~/obs$ curl -s -X POST 127.0.0.1:11435/flaky -d '{"cut_after": 6}'; echo
{"fail_rate": 0, "fail": 0, "status": 503, "cut_after": 6, "seed": 7}
ana@dev:~/obs$ rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought.
trace 756285d53ceba6e75566de58790eaa52
ana@dev:~/obs$ python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"
      0   4,373 ms  ask
      1      26 ms    embed
     27       0 ms    search
     28   4,345 ms    generate
                       app.attempts = 2
     28   1,433 ms      chat llama3.2:3b  ERROR IncompleteReply: stream ended after 6 pieces with no finish reason
                         app.partial_pieces = 6
  1,961   2,411 ms      chat llama3.2:3b
  4,372       0 ms    check_citations
```

O cliente recebeu a resposta certa, depois de 4.373 ms, quando a segunda tentativa sozinha levou
2.411. A primeira tentativa entregou seis pedaços em 1.433 ms e parou; a segunda, depois do recuo,
entregou a resposta inteira.

## O que o cliente viu depende da tela

É aqui que uma chamada a modelo difere de quase qualquer outro pedido. **Se os pedaços estavam sendo
mostrados à medida que chegavam, o cliente leu seis deles**, talvez "A gift card is valid for", e
depois viu o texto sumir e começar de novo, ou pior, viu a segunda tentativa ser emendada na primeira.
Uma nova tentativa é invisível para um pedido cuja resposta só aparece completa. Para um em streaming,
é um tropeço visível, e a tela tem de ser feita para lidar com isso: limpar o que foi mostrado, ou
marcar a nova tentativa, ou não tentar de novo e oferecer um botão.

Então duas coisas pertencem ao span, e o assistente escreve as duas: **a falha**, com o que ela foi, e
**até onde chegou** (`app.partial_pieces`). A primeira conta para a taxa de erro por tentativa da seção
anterior. A segunda diz se o cliente viu alguma coisa antes da falha, que é a diferença entre uma
resposta mais lenta e uma quebrada.

## E o que custou

A tentativa cortada não tem uso no span, porque o uso vem no último pedaço e o último pedaço é o que
se perdeu. Um fornecedor gerou esses tokens, e pode muito bem cobrá-los. A conta da aula 3 contaria só
a segunda tentativa. Quando a taxa de erro por tentativa é alta e as falhas acontecem no meio do stream
em vez de no começo, a conta feita a partir dos spans fica abaixo do real mais ou menos nessa
proporção, e a conciliação mensal da aula 3 é onde isso aparece.
