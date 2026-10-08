---
title: Registrando cada consulta
version: 2
---

Três aulas prometeram esta seção. A aula 2 queria um registro do que foi perguntado e recuperado, para
que um vazamento seja achado num log e não num print de tela. A aula 6 queria a nota de cada consulta,
para ajustar o piso contra perguntas reais. A aula 8 queria perguntas reais para aumentar o conjunto de
teste. As três são o mesmo arquivo: **uma linha por consulta, dizendo tudo o que aconteceu.**

O `ask` do `rag.py` a escreve, depois que a resposta é conhecida:

```schooling-example
{
  "language": "python",
  "file": "last_query.py",
  "parts": [
    {
      "code": "import json\n\nrecord = json.loads(open(\"queries.jsonl\").read().splitlines()[-1])\ndel record[\"ms\"]\nprint(json.dumps(record, indent=2))",
      "note": "A última linha do registro, arrumada para leitura. O tempo que a consulta levou fica de fora, porque muda a cada execução."
    }
  ]
}
```

```
ana@vm:~/rag$ wc -l < queries.jsonl
2
ana@vm:~/rag$ python rag.py "How long is a gift card valid?" > /dev/null; python last_query.py
{
  "question": "How long is a gift card valid?",
  "sources": [
    [
      "gift-cards:40925d184216",
      0.835
    ],
    [
      "payments-and-invoices:7c26788f8bc3",
      0.714
    ],
    [
      "payments-and-invoices:b3d2df106a40",
      0.573
    ]
  ],
  "reply": "According to [1], a gift card is valid for two years from the day it was bought. This is also confirmed by [2], which states that gift cards are valid for two years from purchase.",
  "cited": [
    "gift-cards:40925d184216",
    "payments-and-invoices:7c26788f8bc3"
  ],
  "prompt_tokens": 336,
  "completion_tokens": 42
}
```

As duas consultas anteriores desta aula deixaram duas linhas; a linha da terceira é impressa inteira,
menos o tempo, que muda de uma execução para outra e fica fora da impressão só por isso.

## Para que serve cada campo

| campo | quem lê |
| --- | --- |
| `question` | as próximas perguntas do conjunto de teste, e quem quiser saber o que os usuários querem |
| `sources`, com as notas | o ajuste do piso, e a busca de perguntas cuja melhor nota é baixa |
| `reply` | a revisão, e a avaliação da aula 8 rodada em perguntas reais |
| `cited` | quais pedaços são de fato usados, e quais nunca são citados |
| `prompt_tokens`, `completion_tokens` | o custo por consulta da aula 17 |
| `ms` | quanto tempo o cliente esperou |

Dois deles merecem um segundo olhar. **As notas transformam o piso de um palpite numa medição**: uma
semana de melhores notas registradas, com as perguntas de que as pessoas reclamaram marcadas, é uma base
muito melhor para o limiar da aula 6 do que trinta perguntas escritas pelo curso. **Os ids dos pedaços
citados transformam o corpus em algo que pode ser auditado**: um pedaço nunca citado num mês de
consultas ou é sobre algo que ninguém pergunta, ou está escrito de um jeito que a busca nunca o acha, e
vale saber as duas coisas.

## O que não registrar

A pergunta são as palavras do cliente, e clientes digitam nome, número de pedido e endereço em chats de
atendimento. Um registro de perguntas é dado pessoal, pela mesma lei que o aviso de privacidade deste
corpus cita: precisa de um prazo de retenção, de um jeito de apagar as linhas de uma pessoa quando ela
pede, e de acesso restrito a quem precisa. A regra do próprio aviso de privacidade para conversas de
atendimento, nomes e números de pedido removidos antes de o texto ser usado para melhorar a busca, vale
para este registro no momento em que ele for usado para isso.

A resposta é texto gerado que pode citar documentos internos: o vazamento da aula 2 estaria inteiro
neste registro. Então o registro herda o público mais restrito de tudo o que ele pode conter, o que,
para um pipeline sobre documentos internos, quer dizer só a equipe.

## Para onde ele vai depois

Um arquivo é o lugar certo para começar e o lugar errado para ficar. O mesmo registro mandado para um
pipeline de logs ou uma ferramenta de tracing fica pesquisável, agregado e com alertas; o
`llm-observability`, mais adiante na trilha, constrói exatamente isso a partir de registros como estes.
O que importa agora é o hábito: **se uma consulta aconteceu, há uma linha que diz o que ela fez**, e
nada do que o pipeline decidiu, as fontes, o piso, a recusa, as citações, falta nela.
