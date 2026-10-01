---
title: A DMZ, onde moram os serviços públicos
version: 1
---

Alguns serviços existem para ser alcançados a partir da internet: a loja, o servidor de nomes que
responde pelo domínio da empresa, um relay de e-mail. Não dá para mantê-los fora de alcance, então
eles são **mantidos em algum lugar onde um comprometimento custe pouco**. Esse lugar é a **DMZ**,
nome tirado da zona desmilitarizada (*demilitarised zone*) entre duas fronteiras: um segmento
próprio, entre a internet e o lado de dentro, em que nenhum dos dois confia.

A regra que define uma DMZ trata de direção:

- a internet pode alcançar a DMZ, nos serviços que ela oferece e em nada mais;
- a DMZ pode alcançar o lado de dentro só onde um serviço precisa, um endereço e uma porta por vez;
- **o lado de dentro nunca é alcançável diretamente a partir da internet**, só através de algo na DMZ.

A loja segue essa regra: `remote` alcança `www`, `www` alcança `app` em 8080, e `app` não é alcançado
por mais nada de fora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas formas de montar uma DMZ. À esquerda, um firewall com três pernas: a internet, a DMZ e a rede interna saem todas do mesmo firewall. À direita, dois firewalls em sequência: o externo entre a internet e a DMZ, o interno entre a DMZ e a rede interna, de modo que o tráfego da internet para dentro atravessa os dois.\"><defs><marker id=\"dz-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um firewall, três pernas</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">internet</text><rect x=\"110\" y=\"114\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"20\" y=\"200\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DMZ</text><rect x=\"200\" y=\"200\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rede interna</text><path d=\"M170 64 L170 114\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M140 144 L80 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M200 144 L270 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M360 20 L360 240\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"390\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dois firewalls</text><rect x=\"390\" y=\"34\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">internet</text><rect x=\"390\" y=\"94\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw externo</text><rect x=\"390\" y=\"154\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DMZ</text><rect x=\"560\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw interno</text><rect x=\"560\" y=\"214\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rede interna</text><path d=\"M450 64 L450 94\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M450 124 L450 154\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M510 169 L560 169\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M630 184 L630 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path></svg>", "caption": "O laboratório tem a forma da esquerda. A da direita troca um segundo conjunto de regras por uma segunda camada."}
```

## Um firewall ou dois

A DMZ do laboratório fica pendurada numa perna do mesmo firewall que guarda todo o resto, uma DMZ de
**três pernas** (*three-legged*) ou de firewall único. O outro desenho clássico põe a DMZ **entre
dois firewalls**: um externo voltado para a internet e um interno guardando o lado de dentro, muitas
vezes de fabricantes diferentes, para que uma falha não abra os dois.

| | um firewall, três pernas | dois firewalls |
|---|---|---|
| custo e manutenção | uma caixa, um conjunto de regras | dois de cada |
| uma falha ou uma regra errada no firewall | pode abrir todas as zonas de uma vez | abre uma camada; a outra continua de pé |
| onde ficam as regras do lado de dentro | na mesma tabela que as da internet | numa caixa com que a internet nunca fala |

A maioria das redes pequenas e médias usa um firewall com várias pernas, e é um desenho sólido **se
o conjunto de regras for mantido com disciplina**, que é o assunto do resto deste curso. O desenho
com dois firewalls compra profundidade ao preço de uma segunda política que precisa continuar
coerente com a primeira.
