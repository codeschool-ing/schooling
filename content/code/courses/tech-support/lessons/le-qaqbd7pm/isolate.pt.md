---
title: Isolar: descartar o que funciona
version: 1
---

Uma página que não abre envolve pelo menos quatro coisas: o computador da Carla, a rede, o servidor e a
página. Isolar é fazer perguntas cujas respostas descartam partes inteiras dessa lista:

```
ana@pc2:~$ curl -sS -m 10 http://intranet/
intranet: welcome
ana@pc1:~$ getent hosts intranet
10.30.0.200     intranet
ana@pc2:~$ getent hosts intranet
10.30.0.31      intranet
ana@pc1:~$ curl -sS -m 10 http://10.30.0.31/
intranet: welcome
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Isolando o defeito cortando o que sobra. Primeira pergunta: o pc2 abre a intranet? Sim, então o servidor e a página estão bem. Segunda: o pc1 alcança o srv1 pelo endereço, 10.30.0.31? Sim, então a rede do pc1 está bem. Terceira: o pc1 e o pc2 acham o mesmo endereço para intranet? Não: o pc1 acha 10.30.0.200, então o que sobra é o nome, no pc1, no /etc/hosts.\"><defs><marker id=\"hv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o pc2 abre a intranet?</text><rect x=\"440\" y=\"16\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"518\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor e a página estão bem</text><path d=\"M220 62 L220 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hv-ah)\"></path><rect x=\"20\" y=\"78\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o pc1 alcança o srv1 pelo endereço?</text><rect x=\"440\" y=\"78\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"518\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rede do pc1 está bem</text><path d=\"M220 124 L220 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hv-ah)\"></path><rect x=\"20\" y=\"140\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o pc1 e o pc2 acham o mesmo endereço para intranet?</text><rect x=\"440\" y=\"140\" width=\"60\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não</text><text x=\"518\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o nome, no pc1: /etc/hosts</text></svg>", "caption": "Três perguntas, cada uma respondida por um comando, e cada resposta descarta uma boa parte do que sobrava. A terceira não acha a causa sozinha; deixa um lugar só para olhar."}
```

- O `pc2`, o computador de uma colega na mesma rede, **abre a página**. Então o `srv1` está no ar, o nginx
  está servindo e a página está lá. Metade da lista foi embora com um comando.
- O `getent hosts` pergunta a cada computador que endereço ele tem para o nome `intranet`, do mesmo jeito
  que o navegador pergunta. **Eles discordam**: o `pc2` acha `10.30.0.31`, o `pc1` acha `10.30.0.200`.
- O `pc1` abre a página **pelo endereço**, `10.30.0.31`. Então a placa de rede dele e a rota até o servidor
  funcionam.

O que sobra é pequeno: **o nome `intranet`, só no `pc1`**. Nada foi mudado ainda, e de propósito. Toda
checagem até aqui só leu; se uma delas tivesse mudado alguma coisa, o resultado seguinte não quereria
dizer o que parece.
