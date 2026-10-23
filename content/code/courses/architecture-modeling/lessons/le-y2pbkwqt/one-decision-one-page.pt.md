---
title: Uma decisão, uma página
version: 1
---

**Um registro de decisão de arquitetura, um ADR, é um documento curto que guarda uma decisão
importante: a situação que a exigiu, o que foi decidido e o que decorre dela.** Ele é escrito quando
a decisão é tomada, fica junto do código e nunca é reescrito depois. O conjunto deles, em ordem, é o
log de decisões do sistema.

A aula 5 de `architecture-role` mostrou um registro inteiro e defendeu por que cabe ao arquiteto
garantir que os registros existam. Esta aula é sobre o ofício de escrever um: o que vai em cada
parte, como comparar opções com honestidade e como um log continua legível por anos enquanto as
decisões mudam.

## As cinco partes, e para que serve cada uma

O formato de Michael Nygard, de 2011, ainda é aquele pelo qual a maioria dos times começa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l05-anatomy\" aria-label=\"As cinco partes de um registro de decisão, empilhadas como na página, cada uma com a pergunta que responde para um leitor dois anos depois. Título: o que foi decidido? Status: isto ainda vale? Contexto: o que era verdade, e o que puxava para cada lado? Decisão: o que exatamente será feito? Consequências: o que passou a ser verdade por causa dela, de bom e de ruim?\"><defs><marker id=\"l05-anatomy-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"300.0\" height=\"270.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"40.0\" y=\"26.0\" width=\"280.0\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Título</text><text x=\"50.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">9. Hold seats in Redis…</text><path d=\"M330.0 41.0 L372.0 41.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que foi decidido?</text><rect x=\"40.0\" y=\"62.0\" width=\"280.0\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Status</text><text x=\"50.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Accepted, 2025-05-12</text><path d=\"M330.0 77.0 L372.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">isto ainda vale?</text><rect x=\"40.0\" y=\"98.0\" width=\"280.0\" height=\"72.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Contexto</text><text x=\"50.0\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">- 1,800 holds/min at peak…</text><path d=\"M330.0 134.0 L372.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que era verdade, o que puxava?</text><rect x=\"40.0\" y=\"176.0\" width=\"280.0\" height=\"44.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Decisão</text><text x=\"50.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">We will hold each seat…</text><path d=\"M330.0 198.0 L372.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que exatamente será feito?</text><rect x=\"40.0\" y=\"226.0\" width=\"280.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Consequências</text><text x=\"50.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">- CPU falls below 60%…</text><path d=\"M330.0 256.0 L372.0 256.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que virou verdade, bom e ruim?</text></svg>", "caption": "Um registro é curto porque cada parte responde a uma pergunta que um leitor futuro vai ter, e a nada mais.", "same": ["Status"]}
```

| parte | a pergunta que ela responde para um leitor daqui a dois anos |
| --- | --- |
| **título** | *o que foi decidido?*, numa frase curta, depois de um número: `9. Hold seats in Redis with a ten-minute expiry` |
| **status** | *isto ainda vale?* proposto, aceito, obsoleto ou substituído |
| **contexto** | *o que era verdade, e o que puxava para cada lado, quando isto foi decidido?* |
| **decisão** | *o que exatamente será feito?*, em frases completas, na voz ativa |
| **consequências** | *o que passou a ser verdade por causa dela*, de bom e de ruim |

A palavra importante é leitor. **Um registro é escrito para alguém que não estava lá**: uma
engenheira nova, um auditor, o arquiteto que vai substituir você, ou você mesmo daqui a dois anos,
tendo esquecido. Cada parte responde a uma pergunta que essa pessoa vai ter, e uma parte que não
responde nada para ela é enchimento.

## Que decisões merecem um

Nem toda escolha é de arquitetura, e um log de duzentos registros sobre versões de biblioteca é um
log que ninguém lê. Uma decisão merece um registro quando é **cara de reverter** e **afeta mais do
que as pessoas que a tomaram**. Quatro tipos passam nesse teste com segurança:

- **estrutura**: onde fica uma fronteira, o que fala com o quê, qual componente é dono de quais
  dados;
- **tecnologia de cauda longa**: um banco de dados, um broker de mensagens, uma linguagem para um
  serviço novo;
- **trocas entre qualidades**: aceitar escritas mais lentas por leituras mais rápidas, ou
  consistência eventual por disponibilidade;
- **coisas que as pessoas vivem perguntando**: se a mesma pergunta já foi respondida duas vezes no
  chat, a terceira resposta deveria ser um link.

O log da Carcará tem vinte e três registros em três anos. A maioria tem uma página, e o mais longo
tem três.

## Um registro não é um documento de design

Um documento de design explora: descreve um sistema, uma mudança, alternativas, perguntas em aberto,
e evolui enquanto o design evolui. Um registro **fecha**: afirma uma decisão e para. Documentos de
design longos costumam gerar vários registros à medida que as conclusões se firmam, e os registros
apontam de volta para o documento, para quem quiser a exploração inteira. Manter os dois separados é
o que mantém o log curto o bastante para ser lido.
