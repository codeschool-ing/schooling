---
title: O id de trace é uma alça
version: 2
---

O `assistant.py` imprime um id de trace embaixo de cada resposta. Em produção ele vai além do terminal:
**é devolvido a quem chamou o assistente**, e de lá vai parar na tela do cliente, no chamado de
atendimento, e em toda linha de log escrita enquanto o pedido rodava. É o único valor que liga tudo
isso ao registro do que aconteceu.

## Achando um trace de novo

Mais uma pergunta, a que um cliente poderia fazer sobre um vale-presente, e o arquivo guarda dezesseis
spans de três traces:

```
ana@dev:~/obs$ python assistant.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought.
trace 7816f4d9ea7282a767b310a42b569fd3
ana@dev:~/obs$ wc -l spans.jsonl
16 spans.jsonl
ana@dev:~/obs$ python -c "import json; print(sorted({json.loads(l)[\"trace\"] for l in open(\"spans.jsonl\")}))"
['5ea30205e6a9ef29c4b98b45d1595ab9', '7816f4d9ea7282a767b310a42b569fd3', 'b0f29bf4b40469cb859c35e290b1bcec']
```

Um id de trace tem 32 caracteres hexadecimais, e ninguém lê isso em voz alta ao telefone. Os oito
primeiros bastam para achar um trace entre milhares, e é isso que uma tela de atendimento mostra como
referência:

```
ana@dev:~/obs$ grep -c 5ea30205 spans.jsonl
6
ana@dev:~/obs$ python tree.py 5ea30205
trace 5ea30205e6a9ef29c4b98b45d1595ab9   start(ms) took(ms)
      0   3,021 ms  ask
      0      25 ms    embed
     26       4 ms    search
     31   2,990 ms    generate
     31   2,990 ms      chat llama3.2:3b
  3,021       0 ms    check_citations
```

Um cliente escreve dizendo que o assistente lhe disse que ele pagaria a postagem de uma devolução, e o
site diz que as devoluções são gratuitas. Se a tela mostrou uma referência a ele, a equipe de
atendimento a digita e recebe a árvore acima, e com `--attrs` tudo o que a seção 08 leu: a versão, o
trecho, a resposta, o tempo. Sem ela, a busca é por horário e por palavras, no meio de todo mundo que
perguntou sobre devoluções naquela tarde.

## O que se liga por ele

O id de trace é a chave de que tudo nas próximas aulas depende:

- **Feedback** (aula 5). Um polegar para baixo chega segundos depois da resposta, vindo do navegador.
  Ele traz o id de trace a que se refere, e a ligação é exata. Ligá-lo por horário ou por usuário
  o prende à resposta errada sempre que a mesma pessoa perguntou duas vezes num minuto.
- **Notas** (aulas 8 e 9). Uma avaliação de uma resposta é registrada contra o trace, para que uma
  nota baixa leve direto às entradas que a produziram.
- **Linhas de log.** A integração de logs do OpenTelemetry põe o id de trace e o id de span correntes
  em todo registro de log escrito dentro de um span; a aula 8 do `observability` monta isso. Uma linha
  de log com o id de trace é uma linha que se acha a partir do trace e vice-versa.

A regra que este curso segue daqui em diante é a que o catálogo inteiro segue para os próprios dados:
**as coisas se ligam por um id estável, nunca por um horário, uma posição ou um pedaço de texto**. Dois
pedidos podem ter as mesmas palavras e o mesmo segundo. Nunca têm o mesmo id de trace.

## O que um id de trace não é

Não é um segredo nem uma permissão: conhecer um deveria permitir a alguém da equipe achar um trace, e
nada mais. Qualquer coisa que mostre traces a alguém precisa verificar quem está pedindo, exatamente
como faria com a própria conversa, porque um trace com a pergunta é a conversa. A aula 2 trata do que
isso implica para o que se guarda.
