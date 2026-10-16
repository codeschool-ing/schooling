---
title: Um modelo, dois trabalhos
version: 1
---

Os pedidos da Quitanda moram numa tabela, e essa tabela faz dois trabalhos. Ela **recebe mudanças**: um
pedido é feito, um item é acrescentado, um pagamento chega, e cada mudança tem regras (um pedido pago não
pode ganhar itens). E ela **responde perguntas**: o histórico de pedidos do cliente, a lista do armazém
para a manhã, os mais vendidos da semana, o relatório que o contador quer. As mesmas linhas, as mesmas
colunas, os mesmos índices servem aos dois.

Por muito tempo esse é o projeto certo, e para a maioria dos sistemas continua certo. Ele começa a apertar
quando os dois trabalhos puxam para lados diferentes:

- **As leituras precisam de formatos que as escritas não precisam.** Os mais vendidos querem totais por
  produto, a página do pedido quer itens com nomes e preços, a caixa de busca quer texto. Cada um é um
  join e uma agregação sobre as mesmas tabelas normalizadas, calculados a cada requisição.
- **Leituras e escritas crescem de jeitos diferentes.** Uma loja lê o catálogo centenas de vezes para
  cada pedido feito. A réplica de leitura da aula 10 é uma resposta; ela copia o mesmo modelo, então leva
  os mesmos joins caros para outra máquina.
- **As regras se embolam com as telas.** Colunas acrescentadas para uma tela mostrar alguma coisa acabam
  sendo preenchidas, conferidas e levadas a sério pelo código que recebe pedidos.

O **CQRS**, *Command Query Responsibility Segregation*, nome que Greg Young deu por volta de 2010 a uma
ideia de Bertrand Meyer, separa os dois. Um **modelo de escrita** recebe comandos e impõe as regras. Um
ou mais **modelos de leitura**, cada um com o formato das perguntas que responde, são construídos a
partir das mudanças que o modelo de escrita registra. Consultas nunca tocam o modelo de escrita; comandos
nunca tocam um modelo de leitura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois arranjos. À esquerda, um modelo: comandos e consultas vão para a mesma tabela de pedidos. À direita, CQRS: comandos vão para um modelo de escrita, que registra as mudanças; as mudanças fluem para modelos de leitura, um resumo dos pedidos e unidades vendidas, e as consultas vão para eles.\"><defs><marker id=\"l13-cqrs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-cqrs-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-cqrs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">um modelo</text><rect x=\"70\" y=\"100\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pedidos</text><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">comandos</text><path d=\"M130 78 L130 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-amber)\"></path><text x=\"130\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">consultas</text><path d=\"M130 176 L130 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-phosphor)\"></path><path d=\"M260 40 L260 220\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"490\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">CQRS</text><text x=\"300\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">comandos</text><path d=\"M320 84 L320 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-amber)\"></path><rect x=\"290\" y=\"110\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">modelo de escrita</text><path d=\"M422 135 L478 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-paper-dim)\"></path><text x=\"450\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mudanças</text><path d=\"M478 135 L500 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"62\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order_summary</text><rect x=\"500\" y=\"160\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">units_sold</text><path d=\"M478 135 L498 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cqrs-ah-paper-dim)\"></path><text x=\"590\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">as consultas leem estas</text></svg>", "caption": "O CQRS separa o modelo que recebe mudanças dos modelos que respondem perguntas, e os liga com um fluxo de mudanças."}
```

Três coisas que o CQRS **não** exige, porque costumam vir junto com ele nas descrições:

| o que se costuma supor | na verdade |
| --- | --- |
| bancos separados | o laboratório guarda os dois modelos num PostgreSQL só |
| event sourcing | o modelo de escrita pode ser tabelas comuns que publicam mudanças, com um outbox da aula 7 |
| um broker de mensagens | um modelo de leitura pode ser atualizado na mesma transação, ou lendo uma tabela periodicamente |

O que ele exige é aceitar que **um modelo de leitura construído a partir de mudanças é uma cópia, e
atrasa**: a janela da aula 9, dentro de uma aplicação. Uma tela que mostra um modelo de leitura logo
depois de um comando precisa do ler as próprias escritas da aula 9.
