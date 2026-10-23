---
title: Provando que o domínio é seu, e o registro que fica para trás
version: 1
---

**Um host só serve um site sob um domínio depois que o dono do domínio prova que é dono, em geral com um
registro DNS que só o dono conseguiria criar.** Apontar um registro para o host não é prova suficiente por
si só, porque o perigo corre também no sentido contrário: um nome que você controla apontando para um host
onde você já não tem site.

## Verificação

O host mostra um valor, em geral uma string aleatória, e pede um registro `TXT` com ela, no domínio ou num
nome como `_vercel.example.com` ou `_github-pages-challenge-<user>.example.com`. O host então consulta o
registro. Só quem controla o DNS do domínio consegue fazer essa consulta responder, então a consulta é a
prova. Alguns hosts aceitam como prova o próprio `CNAME` apontando para eles, e só pedem um registro `TXT`
quando outra conta já reivindicou o domínio.

Deixe o registro `TXT` no lugar depois da verificação. A documentação do GitHub descreve para que serve a
verificação exatamente nos termos desta aula: ela impede outros usuários de tomar o domínio quando um
repositório é apagado ou o Pages é desligado enquanto o domínio ainda aponta para lá.

## O registro que fica para trás

É daqui que vem a maioria dos incidentes reais com domínios próprios, e acontece depois que o trabalho
acabou. Uma equipe apaga o site no host, o projeto ou o preview, e esquece o registro DNS:
`docs.example.com` ainda tem um `CNAME` para `example-docs.pages.dev`, que agora não é de ninguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Antes: docs.example.com tem um CNAME para example-docs.pages.dev, que é o projeto da equipe. Depois que o projeto é apagado, o CNAME continua lá e aponta para um nome que não é de ninguém. Qualquer pessoa que criar um projeto com esse nome passa a servir páginas sob docs.example.com.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><rect x=\"20\" y=\"42\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">docs.example.com</text><line x1=\"210\" y1=\"62\" x2=\"300\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,62.0 292.6,65.1 292.6,58.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"255\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"302\" y=\"42\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">example-docs.pages.dev</text><text x=\"530\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o seu projeto</text><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois que o projeto é apagado</text><rect x=\"20\" y=\"132\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">docs.example.com</text><line x1=\"210\" y1=\"152\" x2=\"300\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,152.0 292.6,155.1 292.6,148.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"255\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"302\" y=\"132\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"407\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">example-docs.pages.dev</text><text x=\"530\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">de ninguém, até alguém reivindicar</text></svg>", "caption": "Um registro deixado apontando para um site apagado empresta o seu domínio a quem pegar o nome depois; apague o registro primeiro."}
```

**Qualquer pessoa que consiga criar um projeto com esse nome naquele host passa a servir páginas sob
`docs.example.com`**: o seu domínio, a confiança dos seus usuários, às vezes os seus cookies. Isso se chama
**sequestro de subdomínio** (subdomain takeover), e a defesa está inteira do seu lado:

- **apague o registro DNS primeiro, o site depois.** Um registro apontando para nada que seja seu é o
  perigo; um site sem registro apontando para ele é inofensivo.
- **mantenha o domínio verificado no host**, que é para isso que existem os registros de verificação: um
  domínio verificado não pode ser ligado ao projeto de outra pessoa naquele host.
- **revise a zona de vez em quando**: todo `CNAME` deve apontar para algo que a sua organização ainda
  roda. Uma lista de registros que ninguém sabe explicar é a lista de onde um sequestro começa.

## O que dá para conferir sem um domínio

No seu computador, um nome pode apontar para a sua própria máquina sem DNS nenhum, e é o que o resto
desta aula faz: `planner.test` é um nome que existe só nos comandos que o usam. O domínio `.test` é
reservado pela RFC 2606 para nunca existir na internet, e isso o torna seguro exatamente para isto.
