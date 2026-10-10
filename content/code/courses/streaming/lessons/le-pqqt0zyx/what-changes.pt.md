---
title: Quatro coisas que mudam quando o período nunca fecha
version: 1
---

Um processador de stream lê eventos à medida que chegam e nunca alcança o fim da entrada. **Quatro
coisas que um batch tem de graça deixam de ser de graça**, e quase toda lição deste curso é sobre
uma delas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O mesmo dia de vendas tratado de dois jeitos. Em cima, um batch: as vendas se acumulam o dia todo e um job às duas da manhã lê todas, então toda resposta é sobre ontem. Embaixo, um stream: cada venda é tratada segundos depois de acontecer, e uma venda de Natal chega três horas e quarenta minutos atrasada, depois de vendas que aconteceram mais tarde que ela.\" data-fig=\"l1-batch-stream\"><defs><marker id=\"l1-batch-stream-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1-batch-stream-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">batch</text><line x1=\"90\" y1=\"70\" x2=\"520\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"20\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stream</text><line x1=\"90\" y1=\"175\" x2=\"520\" y2=\"175\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><text x=\"520\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><text x=\"630\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">02:00</text><circle cx=\"110\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"160\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"185\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"215\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"300\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"330\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"360\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"395\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"440\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"470\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"500\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"305.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vendas durante o dia</text><rect x=\"565\" y=\"48\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um job às 02:00</text><text x=\"630\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê todo o dia de ontem</text><path d=\"M 520 70 L 560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l1-batch-stream-ah-8343)\"></path><circle cx=\"110\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"110\" y1=\"168\" x2=\"110\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"160\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"160\" y1=\"168\" x2=\"160\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"185\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"185\" y1=\"168\" x2=\"185\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"215\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"215\" y1=\"168\" x2=\"215\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"245\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"245\" y1=\"168\" x2=\"245\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"300\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"300\" y1=\"168\" x2=\"300\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"330\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"330\" y1=\"168\" x2=\"330\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"360\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"360\" y1=\"168\" x2=\"360\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"395\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"395\" y1=\"168\" x2=\"395\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"440\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"440\" y1=\"168\" x2=\"440\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"470\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"470\" y1=\"168\" x2=\"470\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"500\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"500\" y1=\"168\" x2=\"500\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"138\" cy=\"175\" r=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"270\" cy=\"175\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"270\" y1=\"168\" x2=\"270\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><path d=\"M 141 184 Q 204 214 266 184\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l1-batch-stream-ah-83)\"></path><text x=\"204\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">atrasada: aconteceu 10:20, chegou 14:00</text><text x=\"305\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada venda tratada segundos depois de acontecer</text></svg>", "caption": "Um batch espera o período fechar; um stream trata cada evento quando ele chega, inclusive o que chega atrasado.", "same": ["batch", "stream"]}
```

## 1. Não existe "tudo"

Um batch pode dizer *total de vendas de ontem* porque ontem acabou. Um stream não pode dizer
*total de vendas* de jeito nenhum: o total é outro um segundo depois, e nunca para de mudar.
Qualquer agregado sobre um stream — uma soma, uma contagem, uma média, um top dez — precisa ser
perguntado sobre uma fatia dele, e **a fatia precisa ser escolhida**. As fatias se chamam
**janelas**: a cada cinco minutos, a última hora, a visita de um cliente. A lição 10 trata delas.

## 2. O tempo tem dois sentidos

Num batch, a hora da venda e a hora em que ela foi processada estão a horas de distância e
ninguém se importa, porque o job lê o dia inteiro de qualquer jeito. Num stream elas estão a
segundos de distância, quase sempre — e as exceções são onde os resultados saem errados. Um caixa
que perde a conexão às 10:20 e a recupera às 14:00 manda as vendas numa rajada, e um processador que
conta vendas pela hora em que *chegaram* põe duas horas de vendas de Natal no minuto das 14:00.
**Tempo do evento** é quando aconteceu; **tempo de processamento** é quando o programa viu. As
lições 9 a 11 tratam de manter os dois separados, e de decidir quanto esperar pelos atrasados.

## 3. Rodar de novo não é de graça

Um batch que falhou roda de novo sobre a mesma entrada. Um processador de stream que cai já fez
parte do trabalho: alguns eventos foram tratados e gravados em algum lugar, outros não, e o
programa precisa saber quais. Se recomeçar cedo demais no stream, trata alguns eventos duas vezes;
se recomeçar tarde demais, pula alguns. **O que uma queda custa é uma decisão**, e ela tem nomes —
no máximo uma vez, pelo menos uma vez, exatamente uma vez — que as lições 7 e 8 desmontam.

## 4. Ele nunca para

Um job batch roda vinte minutos por noite, e no resto do tempo não há nada para observar. Um stream
roda o tempo todo, e tudo de que ele precisa também: os brokers, os processadores, os discos que
guardam o histórico. **Ele precisa ser operado**: alguém tem de perceber quando o processador fica
para trás dos eventos, o que se chama **lag**, e o que fazer quando isso acontece. E ele precisa ser
pago o dia inteiro. As lições 16 e 17 tratam das duas coisas.

## E uma que não muda: a ordem

Há uma quinta pergunta que um batch responde ordenando, e um stream responde pela forma como guarda
as coisas: *em que ordem isso aconteceu?* Um saque aplicado antes do depósito de que depende dá um
saldo diferente dos mesmos dois eventos na ordem inversa. A resposta do Kafka é precisa e mais
estreita do que se espera — a ordem é mantida **por chave, dentro de uma partição**, e em nenhum
outro lugar — e é o assunto das lições 2 e 3.

Nenhuma das quatro torna o streaming pior que o batch. Elas o tornam outro tipo de programa, cuja
correção precisa ser argumentada em vez de suposta. A próxima seção é sobre quando vale a pena
fazer esse argumento.
