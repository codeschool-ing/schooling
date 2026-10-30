---
title: Trabalho que precisa acontecer mesmo com o app fechado
version: 1
---

**Certo trabalho precisa terminar esteja o estudante olhando para o app ou não.** O planner guarda
as sessões no celular, e as aulas 13 e 16 as enviam para um servidor. Se o estudante acrescenta uma
sessão no metrô, sem sinal, fecha o app e guarda o celular, o envio ainda precisa acontecer em algum
momento depois, quando houver rede, sem ninguém olhando.

A primeira ideia da maioria das pessoas é uma corrotina. A aula 11 lançou trabalho no
`viewModelScope`, e ele roda numa thread de fundo, então parece trabalho em segundo plano. **Não é.**
Uma corrotina vive no processo do app, e o processo é do sistema para encerrar: quando o estudante
arrasta o app para fora, quando o celular precisa de memória para a câmera, ou a qualquer momento
depois que o app sai da tela. Quando o processo acaba, toda corrotina dentro dele acaba junto, pela
metade, e nada lembra que ela estava rodando. A aula 15 de `mobile-fundamentals` descreve as regras
que cada plataforma aplica; esta aula é a ferramenta do Android que convive com elas.

## O que o WorkManager faz no lugar

O WorkManager é a biblioteca `androidx` para **trabalho que precisa ter garantia de rodar em algum
momento**. Você descreve o trabalho e as condições de que ele precisa, e o WorkManager grava essa
descrição num pequeno banco SQLite próprio, dentro do armazenamento privado do app. Depois ele
entrega o horário ao agendador de jobs do sistema, a parte do Android que decide quando os apps podem
trabalhar em segundo plano. O processo pode morrer a qualquer momento depois disso e nada se perde: o
pedido está no disco, e o sistema sabe que ele está esperando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l18-survive\" aria-label=\"Três faixas ao longo do tempo. No processo do app, o app chama enqueue, e o WorkManager grava o pedido no próprio banco e registra um job no agendador do sistema. Depois o processo é morto. Mais tarde a rede volta, o sistema inicia o processo de novo, e o WorkManager lê o pedido do banco, chama doWork e grava o resultado.\"><defs><marker id=\"l18-survive-ah-scan\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--scan)\"></path></marker><marker id=\"l18-survive-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"12\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o processo</text><text x=\"12\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do app</text><text x=\"12\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o banco do</text><text x=\"12\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">WorkManager</text><text x=\"12\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o agendador</text><text x=\"12\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do sistema</text><rect x=\"150\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">enqueue(request)</text><rect x=\"150\" y=\"112\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido gravado</text><rect x=\"300\" y=\"202\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">job registrado</text><rect x=\"300\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">processo morto</text><rect x=\"450\" y=\"202\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a rede voltou</text><rect x=\"450\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processo iniciado</text><rect x=\"590\" y=\"22\" width=\"115\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">doWork()</text><rect x=\"590\" y=\"112\" width=\"115\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resultado gravado</text><path d=\"M210 58 L210 110\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M270 130 L360 130 L360 200\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M420 220 L448 220\" stroke=\"var(--scan)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-scan)\"></path><path d=\"M510 202 L510 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M570 40 L588 40\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M647 58 L647 110\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M270 40 L298 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path></svg>", "caption": "O pedido mora no banco do WorkManager, não no processo, então matar o processo não perde nada: o sistema o inicia de novo quando as restrições são atendidas."}
```

Quando as condições são atendidas (aqui, uma rede), o sistema inicia o processo do app se ele não
estiver rodando, o WorkManager lê o banco, encontra o pedido e o executa. O resultado volta para o
mesmo banco, e é assim que o app descobre depois o que aconteceu. O mesmo banco é o motivo de o
trabalho sobreviver a uma reinicialização: o WorkManager declara um receiver para o aviso de boot e
recoloca os seus jobs.

## Para que ele não serve

**Não serve para trabalho que o estudante está esperando ver.** Uma lista carregando na tela pertence
à corrotina da tela; se o estudante sai, ninguém precisa da resposta. O WorkManager deixaria tudo
mais lento e não ganharia nada.

**Não serve para trabalho que precisa acontecer numa hora exata.** O WorkManager promete que o
trabalho vai rodar, não quando: o sistema agrupa o trabalho de fundo para poupar bateria, e um pedido
pode esperar bem além do momento em que ficou apto. Um lembrete às 19:00 em ponto é um alarme, e a
notificação da aula 19 é o que ele mostra.

**Não serve para trabalho que precisa continuar rodando enquanto o estudante o acompanha**, como um
download longo com barra de progresso. Isso é um serviço em primeiro plano, que o WorkManager pode
iniciar por você, e que põe uma notificação na tela enquanto roda.

O que sobra é exatamente o que o planner precisa: **enviar as sessões, em breve, quando houver rede,
e nunca duas vezes por acidente.** O resto desta aula constrói isso em quatro peças: um worker que
faz o envio, as condições que ele espera, as regras para quando ele é pedido duas vezes, e a classe
de aplicação que dá ao WorkManager os seus workers.

## Nada aqui precisa de celular, e uma coisa precisa

Cada peça desta aula é testada no seu computador com o `work-testing`, uma biblioteca que roda o
WorkManager dentro de um teste do Robolectric e deixa o teste dizer "a rede voltou" ou "passaram seis
horas". A seção 07 descreve o que só um celular de verdade mostra: o sistema matando o processo, uma
reinicialização e as regras de bateria que atrasam o trabalho. Esses passos **não foram executados**
para este curso, pelo motivo que a seção 02 da aula 1 dá.
