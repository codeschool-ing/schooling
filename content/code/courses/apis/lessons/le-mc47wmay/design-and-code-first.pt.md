---
title: Design-first e code-first
version: 1
---

**Há duas ordens em que uma especificação e o seu código podem passar a existir, e a diferença é
qual dos dois as pessoas escrevem.** No **design-first**, as pessoas escrevem o documento, discutem e
entram em acordo sobre ele, e o código é construído para combinar. No **code-first**, as pessoas
escrevem o código com algumas anotações, e um framework produz o documento a partir dele. Cada ordem
torna uma coisa barata e transforma outra em trabalho de alguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Duas maneiras de trabalhar. Design-first: pessoas escrevem o openapi.yaml e o revisam; dele saem o código do servidor, os clientes, a documentação e um servidor de mentira, e um teste de contrato roda entre a especificação e o servidor. Code-first: pessoas escrevem o código com anotações; um framework gera o openapi.yaml a partir dele, e a documentação e os clientes saem disso.\"><defs><marker id=\"l06-flow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">design-first</text><rect x=\"20\" y=\"46\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><text x=\"95.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escrito e revisado</text><rect x=\"250\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código do servidor</text><rect x=\"362\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"412.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">clientes</text><rect x=\"474\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"524.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">documentação</text><rect x=\"586\" y=\"52\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"636.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor de mentira</text><line x1=\"170\" y1=\"73\" x2=\"248\" y2=\"73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"230\" y1=\"73\" x2=\"230\" y2=\"34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"34\" x2=\"642\" y2=\"34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"412\" y1=\"34\" x2=\"412\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"524\" y1=\"34\" x2=\"524\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"636\" y1=\"34\" x2=\"636\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"300\" y1=\"94\" x2=\"300\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-flow-ah)\" marker-start=\"url(#l06-flow-ah)\"></line><text x=\"310\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o teste de contrato mantém os dois juntos</text><line x1=\"20\" y1=\"146\" x2=\"680\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">code-first</text><rect x=\"20\" y=\"190\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código e anotações</text><text x=\"95.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escrito e revisado</text><rect x=\"250\" y=\"196\" width=\"150\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><line x1=\"170\" y1=\"217\" x2=\"248\" y2=\"217\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><text x=\"209.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gerado</text><rect x=\"474\" y=\"196\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"524.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">documentação</text><rect x=\"586\" y=\"196\" width=\"100\" height=\"42\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"636.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">clientes</text><line x1=\"400\" y1=\"217\" x2=\"472\" y2=\"217\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><line x1=\"436\" y1=\"217\" x2=\"436\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"436\" y1=\"182\" x2=\"636\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"636\" y1=\"182\" x2=\"636\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-flow-ah)\"></line><text x=\"680\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">âmbar: o que as pessoas escrevem; o resto sai disso</text></svg>", "caption": "A diferença é qual arquivo as pessoas escrevem. Todo o resto é produzido a partir dele, ou conferido contra ele."}
```

O documento do shelf não é nenhum dos dois. O `rest.py` veio primeiro, na lição 1, e a descrição foi
escrita à mão depois, lendo o código. Essa é a ordem mais comum na prática e a que mais tende a se
desencontrar: nenhuma ferramenta gerou o documento, e nenhum revisor o viu antes de o código existir.
O teste de contrato da próxima seção é o que a torna segura mesmo assim.

## O que cada uma custa

| | design-first | code-first |
|---|---|---|
| o que as pessoas escrevem | o documento | o código, com anotações ou tipos |
| quando os clientes podem começar | no dia em que o documento é acordado, contra um servidor de mentira | quando o código está implantado em algum lugar |
| o que mantém documento e código juntos | um teste de contrato, ou um servidor gerado a partir do documento | o gerador, a cada build |
| a falha típica | o código para de combinar com o documento sem ninguém notar | o documento muda sem que ninguém tenha decidido que ele deveria mudar |
| a revisão do contrato | um diff do documento, lido antes de qualquer código | um diff do documento gerado, se alguém fizer commit dele |

O **design-first** põe a discussão onde ela é mais barata. Renomear um campo num rascunho custa uma
edição; renomeá-lo depois que três clientes o usam custa uma versão. Um **servidor de mentira** (um
*mock server*) lê o rascunho e responde com os exemplos dele, então um time de front-end pode
construir contra o contrato antes de o back-end ter uma linha de código; o Prism é um conhecido. O
preço são dois artefatos que podem discordar, e nada além de um teste para perceber quando
discordam.

O **code-first** elimina o desencontro entre as rotas e o documento, porque um é impresso a partir do
outro. Toda linguagem da trilha de back-end tem um jeito de fazer isso, e nenhum deles é rodado aqui:

| a sua linguagem | um jeito comum de gerar o documento |
|---|---|
| Python | o FastAPI o monta a partir das anotações de tipo de cada handler, e serve o Swagger UI em `/docs` |
| Java | o springdoc-openapi lê os controllers de uma aplicação Spring |
| Go | o swag lê comentários estruturados acima de cada handler |
| JavaScript/Node | `@nestjs/swagger` no NestJS, ou `@fastify/swagger` no Fastify |

## A ideia errada sobre code-first

"O documento é gerado, então está sempre certo." Ele está sempre certo sobre o que o código
**declara**: as rotas, os tipos dos parâmetros, o modelo de resposta que um handler nomeia. Ele não
sabe nada do que o código **faz** quando algo dá errado. Uma exceção que o framework transforma num
500 com uma página HTML, uma biblioteca respondendo a um método para o qual ninguém escreveu handler,
um campo que vira `null` num dos caminhos do código: nada disso é declarado, então nada disso está no
documento.

O shelf já tem um desses. O 501 que a biblioteca do Python manda para `OPTIONS` não está em nenhum
handler do `rest.py`, e um gerador lendo o `rest.py` o teria deixado de fora, como o documento escrito
à mão deixou. Então as duas ordens acabam precisando da mesma rede de segurança. No code-first a
parte declarada sai de graça, e o teste de contrato cobre o resto; no design-first o teste de
contrato cobre tudo.

O outro custo do code-first é mais silencioso. Uma pessoa desenvolvedora renomeia `price_cents` numa
classe de modelo, os testes passam, o documento gerado muda junto, e ninguém decidiu que o contrato
devia mudar. **Se o documento gerado for versionado no repositório**, essa troca de nome aparece no
pull request como um diff do contrato, onde alguém que revisa consegue vê-la. Se ele só é gerado em
tempo de execução, ninguém a vê até um cliente quebrar.
