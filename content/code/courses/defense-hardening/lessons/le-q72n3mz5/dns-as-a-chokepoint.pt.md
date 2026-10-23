---
title: Toda conexão começa com um nome
version: 1
---

**Antes de se conectar a qualquer coisa, um programa quase sempre pergunta por um nome.** Um
navegador abrindo uma página de phishing, um cliente de e-mail buscando o link de um anexo, um
malware ligando para casa: cada um transforma primeiro um nome num endereço, e numa rede de empresa
essa pergunta vai para um lugar só, o resolvedor da empresa. Isso faz do resolvedor um ponto de
passagem obrigatório, um único lugar por onde toda conversa de saída passa antes de começar, e é num
ponto assim que quem defende põe um controle.

A imagem comum de bloquear um site ruim é uma regra de firewall com o endereço dele. Isso funciona
para um endereço num dia. Endereços mudam, um nome pode responder com dezenas deles, e um firewall não
sabe que site um visitante queria quando cem sites dividem um endereço. **O nome é a parte estável**,
e um resolvedor que se recusa a responder por um nome barra todo programa de toda máquina que
pergunte a ele, sem mexer em nenhuma delas.

Esta aula monta esse controle em duas etapas. Primeiro o escritório ganha um resolvedor próprio no
`dns`, a que toda máquina pergunta. Depois o resolvedor ganha uma lista de nomes para os quais não
vai responder a verdade, e as respostas que dá no lugar apontam para um **sinkhole**: uma máquina que
recebe o que ia para o site perigoso e, assim, diz qual das suas máquinas tentou ir até lá.

## A quem o desk pergunta hoje

Suba o laboratório desta aula:

```sh
sudo bash hostlab.sh up dns desk trap
```

Depois pergunte ao `desk` para onde vão as perguntas dele:

```
ana@desk:~$ cat /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2 attempts:3
ana@desk:~$ dig web.jatoba.example | tail -2
;; UDP setup with 8.8.4.4#53(8.8.4.4) for web.jatoba.example failed: network unreachable.
;; no servers could be reached
```

O `desk` pergunta aos resolvedores públicos do Google, `8.8.8.8` e `8.8.4.4`, e não consegue
alcançá-los, porque nada no laboratório chega à internet. Essas duas linhas não são escolha de
ninguém da Jatobá: o contêiner as copiou do computador em que roda quando deu boot, então no seu
computador elas podem citar outra coisa. Esse é o primeiro achado, e é o estado comum de um escritório
pequeno: cada máquina pergunta a quem o sistema operacional ou o roteador de casa mandou perguntar, e
o escritório não vê nenhuma dessas perguntas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-chokepoint\" aria-label=\"Dois desenhos do mesmo escritório. Em cima, antes da aula: desk, web e um notebook mandam cada um as suas perguntas de nome direto para resolvedores fora do escritório, e o escritório não vê nenhuma. Embaixo, depois: toda máquina pergunta ao dns, o resolvedor do escritório, que guarda um log e encaminha para a internet o que não sabe responder.\"><defs><marker id=\"l14-chokepoint-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-chokepoint-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-chokepoint-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">antes: cada máquina pergunta a quem mandaram</text><rect x=\"30.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><path d=\"M85.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"160.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M215.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"290.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">notebook</text><path d=\"M345.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"560.0\" y=\"76.0\" width=\"140.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a internet</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">depois: um resolvedor, um log</text><rect x=\"30.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><path d=\"M85.0 206.0 L425.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"160.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M215.0 206.0 L455.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"290.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">notebook</text><path d=\"M345.0 206.0 L485.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"400.0\" y=\"222.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns</text><text x=\"460.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">registra cada pergunta</text><rect x=\"560.0\" y=\"224.0\" width=\"140.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a internet</text><path d=\"M520.0 243.0 L560.0 243.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-paper-dim)\"></path></svg>", "caption": "Um resolvedor próprio é o único lugar por onde toda conversa de saída passa antes de começar."}
```

Um resolvedor próprio resolve as duas metades de uma vez. Dá a toda máquina as mesmas respostas e
anota cada pergunta, que a aula 18 vai tratar como parte do inventário do que cada máquina faz.
