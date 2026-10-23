---
title: A cadeia, desenhada de ponta a ponta
version: 1
---

"Segurança da cadeia de suprimentos" costuma ser lida como "checar as dependências". Dependências são
um elo. **A cadeia é cada passo entre a intenção de alguém e o software que roda**, e cada passo é um
lugar onde o que chega pode ser diferente do que se pretendia. O linkbox tem todos eles, pequenos o
bastante para nomear:

1. **Uma pessoa escreve uma mudança** e faz commit em `~/linkbox`.
2. **O repositório de código** a guarda: `~/ci/linkbox.git` aqui, GitHub ou GitLab em outros lugares.
3. **O build** transforma código em artefato: o hook clona o commit e roda `ci/pipeline.sh`, que roda
   `docker build`.
4. **Dependências** entram no build vindas de fora: as imagens base do Docker Hub e do gcr.io, os
   pacotes Python do PyPI, os scanners das releases do GitHub.
5. **O artefato** é publicado: `ci/push.sh` envia a imagem para o registry.
6. **O registry** o distribui: `localhost:5000`, ou o Docker Hub, ou o PyPI para uma biblioteca.
7. **O consumidor escolhe e implanta**: o cluster kind puxa `localhost:5000/linkbox:main`.

### As letras do SLSA

O SLSA (Supply-chain Levels for Software Artifacts, pronunciado "salsa") é um framework da Open Source
Security Foundation que nomeia as ameaças ao longo desta cadeia e classifica os controles contra elas.
A visão geral de ameaças dele rotula cada ponto com uma letra. Vale conhecer as letras, porque relatos de incidentes e ferramentas as usam:

| letra | ameaça a | no linkbox |
|---|---|---|
| A | o produtor: as pessoas que fazem o software | quem consegue fazer commit |
| B | a autoria e a revisão de uma mudança | um commit que ninguém mais leu |
| C | a gestão do código-fonte | `~/ci/linkbox.git`, o histórico e os hooks |
| D | os parâmetros externos do build | o que mandaram o build construir, e de onde |
| E | o processo de build | o hook e o `ci/pipeline.sh` rodando como ana |
| F | a publicação do artefato | o `docker push` do `ci/push.sh` |
| G | o canal de distribuição | o registry, um mirror, uma CDN |
| H | a escolha do pacote | qual nome e qual versão o consumidor pede |
| I | o uso | como o software implantado é configurado e executado |

Dependências não têm letra própria: **cada dependência traz esta cadeia inteira atrás de si**, de A a
H de novo, dentro do projeto de outra pessoa. Uma dependência comprometida é uma dessas letras dando
errado um nível abaixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l12-chain\" aria-label=\"A cadeia de suprimentos de software, da mudança de uma pessoa até o software rodando, com as letras de ameaça do SLSA. Uma pessoa escreve uma mudança (A, B), o repositório guarda (C), o build recebe o que construir (D) e constrói (E), o artefato é publicado (F) por um registry (G), o consumidor escolhe um pacote (H) e o executa (I). Cada dependência entra no build trazendo a mesma cadeia, de A a H, dentro de outro projeto.\"><defs><marker id=\"sp-l12-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l12-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A · B</text><text x=\"64.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pessoa e mudança</text><text x=\"64\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/linkbox</text><rect x=\"128\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"182.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">código-fonte</text><text x=\"182\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/ci/linkbox.git</text><path d=\"M116 68 L126 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"246\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">D · E</text><text x=\"300.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">build</text><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/pipeline.sh</text><path d=\"M234 68 L244 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"364\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">F</text><text x=\"418.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publicação</text><text x=\"418\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/push.sh</text><path d=\"M352 68 L362 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"482\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">G</text><text x=\"536.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registry</text><text x=\"536\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:5000</text><path d=\"M470 68 L480 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"600\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">H · I</text><text x=\"654.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escolha e uso</text><text x=\"654\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">kind</text><path d=\"M588 68 L598 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"150\" y=\"170\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"315.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cada dependência</text><text x=\"315.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a mesma cadeia, de A a H, no projeto de outra pessoa</text><path d=\"M315 168 L315 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-amber)\"></path></svg>", "caption": "Sete passos entre uma intenção e o software rodando, e uma dependência é a cadeia inteira de novo, um nível abaixo.", "same": ["A · B", "C", "D · E", "F", "G", "H · I", "build", "registry"]}
```

### O que "onde ela quebra" quer dizer

Em cada letra, a pergunta é a mesma: **o que chega aqui poderia ser diferente do que se pretendia, e
alguém perceberia?** Para o linkbox, hoje:

- um commit poderia ser feito por qualquer pessoa com acesso à conta da ana, e nada registra quem o
  revisou (A, B);
- o build roda num laptop, como o mesmo usuário que escreve o código, com acesso ao Docker, o que a
  aula 16 chama pelo nome (E);
- as dependências estão fixadas por versão mas não por hash, então um arquivo diferente com a mesma
  versão seria instalado (as cadeias das dependências, H);
- a imagem é enviada por tag, e uma tag pode ser movida para apontar para outros bytes (F, G);
- o cluster implanta o que quer que `main` aponte, sem checar quem a construiu (H, I).

Nada disso é um erro para um projeto de estudo, e o curso fecha a maior parte: a aula 13 registra o
que há no artefato, a aula 14 o assina e registra como foi construído, a aula 15 fixa as dependências
por hash, a aula 16 endurece o build. **O motivo de desenhar a cadeia primeiro é que um controle
pertence a uma letra**, e um time que sabe qual letra um controle cobre também sabe quais letras nada
cobre.

As duas próximas seções põem sete incidentes públicos nesta cadeia, cada um com o controle que o teria
pegado.
