---
title: Uma resposta interrompida
version: 1
---

Uma resposta em streaming pode parar no meio. A conexão cai, um proxy encerra por tempo uma resposta
longa, o fornecedor reinicia a máquina que a gerava. O que chega é um começo, e depois nada: nenhum
pedaço final, nenhum motivo de parada, nenhum uso.

O assistente trata um stream sem motivo de parada como uma tentativa que falhou (`IncompleteReply`),
registra quantos pedaços recebeu, e tenta de novo. O labobs pode ser instruído a cortar o próximo
stream depois de seis pedaços:

```
ana@lab:~/obs$ rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
trace 3a3d425f632e77475611cb4af2f6aa74
ana@lab:~/obs$ python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"
      0   2,313 ms  ask
      0      43 ms    embed
     44       4 ms    search
     48   2,264 ms    generate
                       app.attempts = 2
     48     410 ms      chat extract-1  ERROR IncompleteReply: stream ended after 6 pieces with no finish reason
                         app.partial_pieces = 6
    959   1,353 ms      chat extract-1
  2,312       0 ms    check_citations
```

O cliente recebeu a resposta certa, depois de 2.313 ms, quando a segunda tentativa sozinha levou 1.353.
A primeira tentativa entregou seis pedaços em 410 ms e parou; a segunda, depois do recuo, entregou a
resposta inteira.

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
