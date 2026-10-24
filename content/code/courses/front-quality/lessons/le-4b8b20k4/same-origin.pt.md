---
title: A política de mesma origem, que o CORS relaxa
version: 1
---

**Os scripts de uma página só podem ler respostas da própria origem da página, e uma origem são três
coisas juntas: o esquema, o host e a porta.** Essa regra é a política de mesma origem, todo navegador a
aplica desde os anos 1990, e ela é o motivo de uma página que você abre não conseguir ler em silêncio o
seu e-mail do site de outra aba, com os seus cookies junto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l07-origin\" aria-label=\"O endereço http://localhost:5173/api/plan?week=43 dividido nas suas partes. O esquema http, o host localhost e a porta 5173 estão agrupados como a origem. O caminho /api/plan e a consulta ?week=43 ficam fora do grupo: eles não mudam a origem. Embaixo, o endereço da API, http://localhost:3000, tem o mesmo esquema e o mesmo host e outra porta, então é outra origem.\"><rect x=\"60\" y=\"50\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">http://</text><text x=\"90.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">esquema</text><rect x=\"126\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><text x=\"171.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">host</text><rect x=\"222\" y=\"50\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:5173</text><text x=\"252.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">porta</text><rect x=\"288\" y=\"50\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"338.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/api/plan</text><text x=\"338.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">caminho</text><rect x=\"394\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"439.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?week=43</text><text x=\"439.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">consulta</text><path d=\"M60 38 L60 30 L282 30 L282 38\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"171.0\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">a origem: as três precisam bater</text><text x=\"386.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">não fazem parte da origem</text><rect x=\"60\" y=\"140\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">http://</text><rect x=\"126\" y=\"140\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><rect x=\"222\" y=\"140\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3000</text><text x=\"298\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outra origem: só a porta difere</text></svg>", "caption": "Dois endereços num computador, e duas origens. O navegador compara as três partes como estão escritas, então uma porta, um esquema ou uma grafia do host fazem um estranho.", "same": ["host"]}
```

A página do planner é servida de `http://localhost:5173`. Comparados a ela:

| endereço | mesma origem? | porque |
|---|---|---|
| `http://localhost:5173/api/plan` | sim | esquema, host e porta batem |
| `http://localhost:3000/api/plan` | **não** | a porta difere |
| `https://localhost:5173/` | não | o esquema difere |
| `http://127.0.0.1:5173/` | não | o host está escrito de outro jeito, e o navegador compara as palavras, não a máquina |
| `http://planner.localhost:5173/` | não | outro host |

**A segunda linha é a que toda pessoa de front-end encontra.** O app numa porta, a API em outra, os dois
no seu próprio computador, e o navegador os trata como estranhos.

## O que a política bloqueia, e o que não bloqueia

A política é sobre **ler**. Uma página ainda pode mandar requisições para qualquer lugar: um formulário
pode enviar para outro site, um `<img>` pode carregar de outro site, uma tag de script pode rodar código
de outro site. O que os scripts da página não podem fazer é ler a resposta a uma requisição que fizeram a
outra origem, a menos que essa origem diga que podem. Essa permissão, dada pelo servidor em cabeçalhos de
resposta, é o **CORS**, cross-origin resource sharing. É um jeito de um servidor relaxar a política para
as origens que ele nomeia, e mais nada: **o CORS nunca deixa nada mais seguro do que a política de mesma
origem já deixava.**
