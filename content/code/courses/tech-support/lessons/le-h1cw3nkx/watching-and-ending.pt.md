---
title: Só olhar, e encerrar
version: 1
---

Muitas vezes o usuário deve digitar e o técnico só olhar: para aprender onde fica uma configuração, ou
porque o que está na tela cabe a ele decidir. A Elisa deixa o acesso só de leitura:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -r ana; tmux -S /tmp/help send-keys -t help "echo typed" Enter
client is read-only
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -l
ana (R)
elisa (W)
```

`client is read-only`: a técnica vê a sessão e não consegue mais digitar nela. A lista diz isso com uma
letra para cada um, `R` para a técnica e `W` para a Elisa. As ferramentas de suporte remoto têm a mesma
chave, em geral chamada de só visualização ou *solicitar controle*.

Quando a ajuda termina, o acesso termina, e é o usuário que o termina:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -d ana; tmux -S /tmp/help send-keys -t help "hostname" Enter
access not allowed
```

`access not allowed` de novo, o estado em que começou. **Encerrar a sessão faz parte do trabalho**: uma
ferramenta remota deixada conectada, ou uma permissão deixada concedida, é acesso que ninguém supervisiona.
Antes de sair, avise que vai desconectar, e confira que o usuário vê que terminou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Os quatro estados de uma sessão remota, da esquerda para a direita. Recusado: o padrão, ninguém entra. Permitido: o usuário disse sim; você digita, ele vê. Só olhar: você vê, ele digita. Encerrado: o usuário retirou. Cada mudança é feita pelo usuário, não pelo técnico.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">recusado</text><text x=\"32\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">o padrão: ninguém entra</text><path d=\"M180 53 L194 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"196\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">permitido</text><text x=\"208\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">ele aceitou; você digita, ele vê</text><path d=\"M356 53 L370 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"372\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"384\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">só olhar</text><text x=\"384\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">você vê, ele digita</text><path d=\"M532 53 L546 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"548\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">encerrado</text><text x=\"560\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">o usuário retirou</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada mudança é feita pelo usuário, não pelo técnico</text></svg>", "caption": "Os mesmos quatro estados existem em toda ferramenta de suporte remoto, seja qual for o nome que ela dá. O que faz deles consentimento é quem passa de um para o outro: a pessoa dona do computador."}
```
