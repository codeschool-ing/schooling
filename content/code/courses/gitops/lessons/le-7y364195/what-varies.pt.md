---
title: Três coisas que variam, em três velocidades
version: 1
---

**Toda organização de repositório é uma resposta a uma pergunta: quando algo muda, quantos arquivos
mudam junto?** Três coisas variam no que um repositório GitOps descreve, e elas mudam em velocidades
diferentes, por motivos diferentes, por pessoas diferentes.

- **A aplicação**: o código dela, construído numa imagem. Muda muitas vezes por dia, por quem a
  escreve. No `fleet` ela aparece só como uma referência: `localhost:5001/bulletin:1.0`.
- **O ambiente**: staging, produção, um ambiente de teste para uma funcionalidade. Muda quando um
  ambiente é criado ou aposentado, raramente, por quem cuida da plataforma.
- **A configuração**: o que uma aplicação precisa num ambiente. Duas réplicas no staging, três na
  produção; uma mensagem aqui, outra ali; um endereço de banco por ambiente. Muda quando alguém ajusta
  ou promove, a cada release.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Três coisas que variam: a aplicação, mudada por quem desenvolve muitas vezes por dia; a configuração, mudada a cada release ou ajuste; e o ambiente, mudado raramente, pelo time de plataforma. Cada uma corresponde a um lugar no repositório.\"><rect x=\"0\" y=\"0\" width=\"680\" height=\"280\" fill=\"var(--ink)\"/><text x=\"30\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">o que varia</text><text x=\"250\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">com que frequência</text><text x=\"430\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">onde mora no fleet</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"120.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a aplicação</text><rect x=\"240\" y=\"50\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">muitas vezes por dia</text><rect x=\"430\" y=\"50\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">uma referência de imagem</text><line x1=\"410\" y1=\"77\" x2=\"418.0\" y2=\"77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,77 418.0,72.5 418.0,81.5\" fill=\"var(--paper-dim)\"/><rect x=\"20\" y=\"125\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"120.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a configuração</text><rect x=\"240\" y=\"125\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a cada release</text><rect x=\"430\" y=\"125\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">um arquivo por app e ambiente</text><line x1=\"410\" y1=\"152\" x2=\"418.0\" y2=\"152.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,152 418.0,147.5 418.0,156.5\" fill=\"var(--paper-dim)\"/><rect x=\"20\" y=\"200\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"120.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">o ambiente</text><rect x=\"240\" y=\"200\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">raramente</text><rect x=\"430\" y=\"200\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">uma pasta</text><line x1=\"410\" y1=\"227\" x2=\"418.0\" y2=\"227.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,227 418.0,222.5 418.0,231.5\" fill=\"var(--paper-dim)\"/></svg>", "caption": "O que varia, com que frequência, e onde mora. Uma mudança de um tipo deve tocar um lugar só."}
```

Uma boa organização põe cada uma dessas coisas num lugar só, para que uma mudança de um tipo toque um
arquivo. Um release novo muda uma referência de imagem na pasta de um ambiente. Um ambiente novo é
uma pasta nova. Uma aplicação nova é uma pasta nova em `apps/`. **A organização falha quando um único
tipo de mudança precisa ser feito em vários lugares**, porque cedo ou tarde um deles é esquecido, e
os ambientes se afastam de jeitos que ninguém decidiu.

O resto desta aula monta essa organização para o `fleet`, em quatro passos: o código da aplicação vai
para um repositório próprio, os arquivos vão para pastas por aplicação e ambiente, a produção chega, e
um release é promovido de um para o outro. A aula 6 então tira a duplicação que as pastas deixam.
