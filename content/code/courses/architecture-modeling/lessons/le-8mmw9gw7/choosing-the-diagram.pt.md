---
title: Escolhendo o diagrama para a pergunta
version: 1
---

**Cada um dos cinco diagramas responde a um tipo diferente de pergunta, e o jeito mais rápido de
escolher um é olhar para as palavras da pergunta.** Uma pergunta com *quem*, uma pergunta com *e
depois*, uma pergunta com *onde*: cada uma aponta para uma notação.

| a pergunta soa como | o diagrama | o que ele mostra que os outros não mostram |
| --- | --- | --- |
| *quem usa o sistema, e para quê?* | **casos de uso** | a fronteira do sistema e os atores fora dela |
| *de que é feita uma reserva? o que precisa ser sempre verdade?* | **classes** | multiplicidades, posse e identidade dos conceitos do domínio |
| *o que acontece, em que ordem, e quem espera?* | **sequência** | o tempo, as esperas e o momento entre enviado e respondido |
| *o que depende do quê? o que poderia ser trocado?* | **componentes** | interfaces oferecidas e exigidas |
| *o que roda onde, e o que cruza a rede?* | **implantação** | máquinas, quantidades, protocolos e posição física |

## Um cenário, cinco desenhos

A melhor prova de que você entendeu os cinco é passar um cenário por todos eles, que é o +1 de
Kruchten da aula 1 na prática. Para *um passageiro compra uma passagem*:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l02-five-views\" aria-label=\"Um cenário, um passageiro compra uma passagem, visto pelos cinco diagramas. Casos de uso: o objetivo e a fronteira. Classes: do que a reserva é feita. Sequência: a ordem das chamadas e quem espera. Componentes: por quais interfaces as chamadas passam. Implantação: quais chamadas atravessam a rede.\"><rect x=\"200.0\" y=\"10.0\" width=\"320.0\" height=\"30.0\" rx=\"15\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um passageiro compra uma passagem</text><path d=\"M360.0 40.0 L76.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"12.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"76.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">casos de uso</text><text x=\"76.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o objetivo e</text><text x=\"76.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fronteira</text><path d=\"M360.0 40.0 L218.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"154.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"218.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">classes</text><text x=\"218.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do que a reserva</text><text x=\"218.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">é feita</text><path d=\"M360.0 40.0 L360.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"296.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sequência</text><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a ordem e</text><text x=\"360.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem espera</text><path d=\"M360.0 40.0 L502.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"438.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">componentes</text><text x=\"502.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por quais</text><text x=\"502.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">interfaces passam</text><path d=\"M360.0 40.0 L644.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"580.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"644.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">implantação</text><text x=\"644.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quais chamadas</text><text x=\"644.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cruzam a rede</text></svg>", "caption": "Percorrer um cenário pelos cinco é como as discordâncias entre eles aparecem, e às vezes a discordância está no código."}
```

- o diagrama de **casos de uso** diz que esse é o objetivo do passageiro e que ele inclui receber o
  pagamento;
- o diagrama de **classes** diz de que é feita a reserva que ele cria;
- o de **sequência** diz quais chamadas acontecem em que ordem e onde o passageiro espera;
- o de **componentes** diz por quais interfaces essas chamadas passam;
- o de **implantação** diz quais dessas chamadas cruzam a rede.

Passar o cenário por cada um também é como você acha as discordâncias. Quando Tainá fez isso para a
compra, o diagrama de sequência tinha uma chamada de Ticketing direto para o banco de Pricing, e o
diagrama de componentes dizia que Ticketing só chegava a Pricing por `FareQuote`. Um dos dois estava
errado, e era o código: um atalho posto no São João anterior, que continuava lá.

## Quando a UML é a escolha errada

A UML é precisa para quem a conhece. **Para quem não conhece, a precisão dela é invisível**, e um
losango vazado é só um losango. Para a diretoria, para Celeste, para o time de produto de uma
empresa parceira, um diagrama de caixas com legenda da aula 1 ou os diagramas C4 da aula 3 vão ser
lidos corretamente mais vezes. A aula 14 trata de escolher o desenho para o público; esta aula deu a
você os cinco desenhos que os engenheiros esperam conseguir ler.
