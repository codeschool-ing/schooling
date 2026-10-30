---
title: Onde o HTML é feito
version: 1
---

**Toda página que um navegador mostra começa como HTML, e alguém precisa escrever esse HTML a
partir dos dados.** Este curso chama essa etapa de **renderização**. A pergunta desta aula não é
*se* ela acontece, e sim *onde* e *quando*: no navegador, depois que um script rodou, ou num
servidor, antes de qualquer coisa ser enviada.

Uma ideia comum sobre a diferença é que um tipo de site "usa JavaScript" e o outro não. Não é isso.
Os dois tipos de página desta aula rodam o mesmo JavaScript no navegador. O que muda é o que a
**primeira resposta** carrega, e portanto o que a pessoa vê, e quando, antes de esse JavaScript
chegar e rodar.

## Três respostas para "onde"

| | o HTML é feito | a primeira resposta carrega | nome neste curso |
|---|---|---|---|
| **no cliente** | no navegador, pelo seu script, depois de buscar os dados | um contêiner vazio e uma tag `<script>` | CSR, renderização no cliente |
| **no servidor** | no servidor, a cada requisição, com os dados que ele tem naquela hora | a página pronta | SSR, renderização no servidor |
| **no build** | no seu computador ou na CI, uma vez, antes do deploy | um arquivo que ficou pronto antes de alguém pedir | SSG, geração estática (aula 3) |

**Híbrida** é a quarta resposta, e a que a maioria dos sites reais dá: o servidor manda uma página
pronta, e depois o script no navegador assume, de modo que cada clique depois do primeiro é
atendido sem pedir HTML ao servidor de novo. A aula 4 é sobre o momento dessa passagem, chamado
hidratação; esta aula só precisa da ideia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três linhas, uma por jeito de renderizar, cada uma uma linha do tempo da esquerda para a direita. No cliente: o navegador recebe uma página vazia, busca o script, o script busca os dados, e só então a página é desenhada. No servidor: o servidor lê os dados e desenha a página quando a requisição chega, e o navegador a mostra assim que a recebe. No build: a página foi desenhada antes de alguém pedir, e o servidor só entrega o arquivo.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no cliente</text><rect x=\"150\" y=\"44\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML vazio</text><rect x=\"280\" y=\"44\" width=\"102\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"331.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><rect x=\"400\" y=\"44\" width=\"102\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"451.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados</text><rect x=\"520\" y=\"44\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"596.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">página desenhada</text><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no servidor</text><rect x=\"150\" y=\"129\" width=\"222\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"261.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor lê dados, desenha</text><rect x=\"390\" y=\"129\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"466.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">página exibida</text><rect x=\"560\" y=\"129\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no build</text><rect x=\"150\" y=\"214\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo</text><rect x=\"280\" y=\"214\" width=\"152\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"356.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">página exibida</text><rect x=\"450\" y=\"214\" width=\"112\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><text x=\"150\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desenhada antes, no seu computador ou na CI</text><line x1=\"140\" y1=\"285\" x2=\"700\" y2=\"285\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,285.0 692.6,288.1 692.6,281.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "A mesma página, feita em três lugares. O que muda é o momento em que a pessoa a vê pela primeira vez.", "same": ["script"]}
```

## Por que isso decide tanta coisa

Onde o HTML é feito decide quatro coisas que o resto do curso mede:

- **quando o primeiro conteúdo aparece.** Uma página renderizada no cliente não consegue mostrar
  o conteúdo antes de três coisas chegarem, uma depois da outra: o HTML, o script que ele nomeia e
  os dados que o script pede. Uma página renderizada no servidor mostra o conteúdo com a primeira.
- **o que um programa que não roda scripts lê.** Alguns crawlers e todas as prévias de link leem a
  primeira resposta e mais nada.
- **quem faz o trabalho.** Renderizar no servidor custa tempo do servidor a cada requisição;
  renderizar no navegador custa esse tempo ao celular do visitante, a cada visita.
- **o que dá para guardar em cache.** Uma página pronta é um arquivo que um cache consegue
  guardar. Uma página feita por requisição para uma pessoa não pode ser compartilhada com a
  próxima.

Nenhuma delas tem uma resposta certa para o site inteiro. A lista de cursos do planner que você vai
construir agora e o formulário que adiciona uma sessão querem coisas diferentes, e os frameworks
da aula 2 deixam você escolher por página. **Escolher bem é saber quanto cada resposta custa**, e
é isso que o resto desta aula mede, no seu próprio computador, num app que você mesmo constrói.
