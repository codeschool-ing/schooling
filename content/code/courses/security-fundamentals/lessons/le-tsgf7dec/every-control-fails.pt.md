---
title: Todo controle falha de vez em quando
version: 1
---

O jeito tentador de proteger algo é achar o melhor controle e pô-lo na frente: a senha mais forte, o
melhor firewall, o produto mais caro. **Esse projeto tem um ponto único de falha, e todo controle
falha de vez em quando.** Senhas vazam, regras são digitadas errado, software tem defeito, pessoas
clicam em links. Um plano que só funciona enquanto um controle é perfeito é um plano para o dia em
que ele não for.

**Defesa em profundidade** é o projeto oposto: vários controles em sequência, cada um capaz de parar
o que passou pelo anterior, de modo que uma falha não vire um incidente. A ideia é militar e antiga,
um castelo com fosso, muralha, portão e torre, e passa para a informação com pouca mudança.

A imagem que a maioria usa para ela vem da investigação de acidentes, e não da segurança: o **modelo
do queijo suíço**, de James Reason. Cada camada de defesa é uma fatia de queijo. Toda fatia tem
furos, as fraquezas daquele controle, e os furos ficam em lugares diferentes em cada fatia. Um
acidente só acontece quando os furos se alinham e algo atravessa todos eles de uma vez.

```schooling-figure
{"svg": "<svg id=\"sf-swiss-cheese\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O modelo do queijo suíço. Quatro fatias em fila: login, verificação de permissão, permissões de arquivo e o log. Cada uma tem furos em lugares diferentes. Uma seta vinda da esquerda passa por um furo da primeira fatia e é parada pela segunda, cujo furo fica em outro lugar. Um incidente exige que os furos de todas as fatias se alinhem.\"><defs><marker id=\"sf-swiss-cheese-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"188\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"188\" cy=\"140\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"188\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">login</text><rect x=\"300\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"318\" cy=\"100\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"318\" cy=\"160\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"318\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">permissão</text><rect x=\"430\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"448\" cy=\"70\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"448\" cy=\"120\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"448\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">permissões de arquivo</text><rect x=\"560\" y=\"30\" width=\"36\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"578\" cy=\"150\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"578\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o log</text><text x=\"20\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma ameaça</text><path d=\"M20 60 L176 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M204 60 L292 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-swiss-cheese-ah-phosphor)\"></path><text x=\"318\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parada pela segunda fatia</text></svg>", "caption": "Toda fatia tem furos. Uma ameaça só passa onde eles se alinham.", "same": ["login"]}
```

Duas coisas decorrem da imagem, e as duas são práticas.

**Os furos não precisam ser tapados para a defesa funcionar.** Uma camada com uma fraqueza conhecida
continua útil se a próxima cobre essa fraqueza. Um firewall que libera a porta web deixa passar
ataques web; quem os para são as verificações da própria aplicação. Nenhuma camada é completa, e
juntas cobrem mais que qualquer uma sozinha.

**O que mata uma defesa são furos que se alinham**, e furos se alinham quando as camadas compartilham
uma causa. Dois controles que dependem da mesma senha, do mesmo administrador ou do mesmo software
falham juntos, então são uma fatia desenhada duas vezes. A última seção desta aula é sobre perceber
isso.

Uma terceira consequência, menos óbvia, é sobre tempo. Um atacante determinado precisa achar um furo
em cada fatia, e cada fatia custa esforço. Mesmo quando ele passa, as camadas compram tempo, e tempo
é o que a detecção precisa: um log que percebe o terceiro passo em falso pode impedir o quarto. É
por isso que detecção é uma camada por direito próprio, e por isso a aula 11 trata de acertá-la.
