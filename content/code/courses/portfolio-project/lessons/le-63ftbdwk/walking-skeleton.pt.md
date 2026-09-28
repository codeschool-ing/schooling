---
title: Um esqueleto que anda
version: 1
---

Há dois jeitos de construir o mesmo projeto, e só um deles termina. O primeiro é camada por camada:
desenhar todas as telas, depois escrever a API inteira, depois o banco, depois descobrir como fazer o
deploy. Parece caprichado, e nada roda até a última camada ficar pronta, que é geralmente onde o projeto
para.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois jeitos de construir as mesmas quatro camadas: página, API, banco e deploy. À esquerda, camada por camada: a página está pronta e larga, a API pela metade, o banco um esboço e o deploy ausente, então nada funciona de ponta a ponta. À direita, um esqueleto que anda: uma fatia fina atravessa as quatro camadas, então a menor versão funciona de ponta a ponta desde a primeira semana.\"><defs><marker id=\"sk5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">construído camada por camada</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">um esqueleto que anda</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página</text><rect x=\"90\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página</text><rect x=\"460\" y=\"36\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"36\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><rect x=\"90\" y=\"86\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"86\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API</text><rect x=\"460\" y=\"86\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"86\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco</text><rect x=\"90\" y=\"136\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"90\" y=\"136\" width=\"80\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco</text><rect x=\"460\" y=\"136\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"136\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><rect x=\"90\" y=\"186\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"390\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><rect x=\"460\" y=\"186\" width=\"250\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"560\" y=\"186\" width=\"50\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M585 76 L585 86\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M585 126 L585 136\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M585 176 L585 186\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path></svg>", "caption": "Camada por camada, nada roda até a última ficar pronta. Um esqueleto que anda roda desde a primeira semana, e toda mudança depois disso melhora uma coisa que funciona.", "same": ["API", "deploy"]}
```

O segundo é um **esqueleto que anda**: a fatia mais fina possível que atravessa todas as camadas, de uma
página que uma pessoa abre até o banco por trás dela, funcionando de ponta a ponta nos primeiros dias.
Tudo depois disso é uma mudança em algo que já roda, e um projeto que já roda é muito mais difícil de
abandonar.

O esqueleto do loanbook são os seus cinco primeiros commits:

```
ana@laptop:~/loanbook$ git log --oneline
28edce4 Take an item back
3227967 Lend an item to somebody
8623595 List the equipment from SQLite
64f0369 Serve a page with nothing on it yet
19e36eb Say what loanbook is for
```

Cada commit é uma fatia, não uma camada. *Serve a page with nothing on it yet* é uma página e um servidor
sem dados. *List the equipment from SQLite* acrescenta o banco e a API de uma vez, e a página mostra o que
eles devolvem. *Lend* e *take back* acrescentam cada um uma rota, uma consulta e um botão. No quinto
commit uma professora já poderia, em princípio, usar. A aula 7 marca esse commit como `v0.1.0`.

Repare no que o esqueleto não tem: nada de testes, quase nenhum estilo, nenhum tratamento de erro, nenhum
deploy ainda. Tudo isso vem, mas **depois** de algo funcionar, porque cada um é mais fácil de acrescentar
a uma coisa que roda do que a um plano.
