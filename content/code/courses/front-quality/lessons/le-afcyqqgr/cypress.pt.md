---
title: O mesmo caminho no Cypress
version: 1
---

**O Cypress é a outra ferramenta de ponta a ponta que você vai encontrar, e é construído ao contrário:
em vez de controlar o navegador de fora, ele roda dentro dele, ao lado do seu app.** O teste e a página
dividem uma aba do navegador. Isso dá ao Cypress as suas forças, uma janela em que você assiste a cada
passo e volta por eles, e os seus limites, como uma aba por teste e um site por teste, a menos que você
peça mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l04-where\" aria-label=\"Duas organizações lado a lado. Playwright: o teste roda no Node, fora do navegador, e manda comandos por uma conexão para o Chromium, onde o planner roda numa aba só dele. Cypress: o navegador guarda o teste e o planner, lado a lado numa aba, e um processo Node ao lado do navegador serve o teste e cuida do que o navegador não consegue, como arquivos.\"><defs><marker id=\"l04-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Playwright</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Cypress</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Node</text><rect x=\"32\" y=\"90\" width=\"96\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o seu teste</text><rect x=\"200\" y=\"50\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Chromium</text><rect x=\"212\" y=\"90\" width=\"126\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma aba: o planner</text><path d=\"M128 110 L212 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\"></path><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">comandos por uma conexão</text><rect x=\"400\" y=\"40\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o navegador, uma aba</text><rect x=\"420\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o seu teste</text><rect x=\"560\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o planner</text><path d=\"M540 105 L560 105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\" marker-start=\"url(#l04-where-ah-paper-dim)\"></path><rect x=\"450\" y=\"180\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Node: serve o teste,</text><text x=\"550.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">lê arquivos, a rede</text><path d=\"M550 160 L550 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\" marker-start=\"url(#l04-where-ah-paper-dim)\"></path></svg>", "caption": "Fora ou dentro. O teste do Playwright abre abas e navegadores à vontade; o do Cypress fica ao lado da página e a vê diretamente.", "same": ["Playwright", "Cypress", "Node", "Chromium"]}
```

*Nada nesta seção foi executado.* O Cypress baixa o próprio aplicativo na primeira vez que é instalado,
dos servidores do Cypress, e a máquina em que este curso foi gravado não tinha permissão para alcançá-los.
O que vem a seguir foi escrito a partir da documentação do Cypress para a versão 16, e as transcrições
estão ausentes em vez de inventadas. Para experimentar, instale do jeito que a documentação diz, numa
cópia do planner e não no próprio planner, pelo mesmo motivo de a cópia do Jest na aula 2 ficar
separada:

```sh
npm install --save-exact -D cypress@16.2.0
```

A configuração diz o endereço, como o `baseURL` do Playwright:

```typescript
// cypress.config.ts
import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: "http://localhost:5173",
  },
});
```

E o segundo teste do Playwright, do jeito que o Cypress o escreve, em `cypress/e2e/planner.cy.ts`:

```typescript
// cypress/e2e/planner.cy.ts
describe("the planner", () => {
  beforeEach(() => {
    cy.clock(new Date("2026-10-21T10:00:00-03:00").getTime(), ["Date"]);
  });

  it("a session added to a course counts in its week", () => {
    cy.visit("/");
    cy.contains("a", "JavaScript").click();
    cy.contains("label", "Date").find("input").type("2026-10-23");
    cy.contains("label", "Minutes").find("input").type("15");
    cy.contains("button", "Add session").click();
    cy.contains("This week: 105 min").should("be.visible");
  });
});
```

## Lendo um ao lado do outro

| | Playwright | Cypress |
|---|---|---|
| onde o teste roda | no Node, controlando o navegador | dentro do navegador, ao lado da página |
| como um passo é escrito | `await page.getByLabel("Minutes").fill("15")` | `cy.contains("label", "Minutes").find("input").type("15")`, uma cadeia sem `await` |
| espera | asserções web-first tentam de novo, `await expect(…)` | todo comando e todo `.should(…)` tentam de novo |
| a rede | `page.route` | `cy.intercept` |
| o relógio | `page.clock` | `cy.clock` |
| subir o app | `webServer` na configuração | você sobe, ou um pacote como o `start-server-and-test` |
| navegadores | Chromium, Firefox e WebKit | navegadores da família Chrome e o Firefox; o WebKit é experimental |

**Os hábitos são os mesmos**: ache elementos pelo que uma pessoa lê, deixe a ferramenta tentar de novo
em vez de pausar, finja a rede só para chegar a um estado. As buscas do próprio Cypress são por texto e
por seletor, e a `@testing-library/cypress` acrescenta a ele as buscas por papel e rótulo da aula 3.
Escolha a ferramenta que o projeto já tem; uma equipe que conhece uma aprende a outra num dia.
