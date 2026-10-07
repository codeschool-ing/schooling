---
title: Perda esperada
version: 1
---

Multiplicar as duas metades dá um número por risco: **a perda que você deve esperar por ano**, na
média de muitos anos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l09-ale\" aria-label=\"Perda esperada por ano para a T01, o webhook forjado. Probabilidade: 0,5 evento por ano, um a cada dois anos em média. Impacto: R$ 12.000 por evento. Multiplicados: R$ 6.000 por ano.\"><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">probabilidade</text><text x=\"120.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">0,5 por ano</text><text x=\"120.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um evento a cada dois anos</text><rect x=\"260.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">impacto</text><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 12.000</text><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por evento</text><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perda esperada</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 6.000</text><text x=\"600.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por ano</text><text x=\"230.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">×</text><text x=\"470.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">=</text><text x=\"360.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">SLE × ARO = ALE, nos nomes clássicos</text></svg>", "caption": "Uma média de muitos anos, não uma previsão para o ano que vem: na maioria dos anos a T01 não custa nada, e em alguns custa doze mil."}
```

> perda esperada por ano = eventos por ano × custo por evento

A literatura clássica de segurança chama as mesmas três quantidades de **expectativa de perda
única** (SLE, o custo de um evento), **taxa anual de ocorrência** (ARO, eventos por ano) e
**expectativa de perda anualizada** (ALE = SLE × ARO). Vale reconhecer os nomes porque auditores e
seguradoras os usam; a aritmética é a mesma.

Para a T03, uma conta da equipe roubada por phishing chegando a todos os prontuários:

> 0,3 por ano × R$ 250.000 por evento = R$ 75.000 por ano

Isso não significa que a Vereda perde R$ 75.000 todo ano. Na maioria dos anos ela não perde nada com
a T03; mais ou menos um ano em cada quatro, perde um quarto de milhão. **O valor esperado é quanto o
ano médio custa no longo prazo**, que é o número certo para um orçamento e o errado para imaginar um
ano qualquer. A última seção desta aula é sobre essa diferença.

### Para que serve

A perda esperada transforma uma lista de ameaças em algo que se soma. Nove riscos na Vereda dão
**R$ 139.400 por ano**, e um deles é mais da metade do total. Nenhum dos dois fatos aparecia numa
lista de alto, médio e baixo, e os dois mudam o que é feito primeiro.

Ela também dá um teto para gastar. Se um controle elimina a maior parte dos R$ 75.000 por ano da
T03, vale a pena pagar por ele se custar bem menos que isso. A aula 11 faz essa comparação direito,
porque "bem menos" depende de quão segura é a estimativa.

### O que ela não é

**Não é uma previsão.** Uma perda esperada de R$ 9.000 por ano com a T14 não significa que R$ 9.000
serão perdidos no ano que vem; quase certamente não serão.

**Não é precisa.** É o produto de duas estimativas, cada uma podendo estar errada por um fator de
dois ou mais. Escrever R$ 75.000 em vez de "uns setenta e cinco mil" é conveniência de conta, não uma
pretensão de exatidão. Duas estimativas que diferem em 10% são um empate.

**Não é o risco inteiro.** Não diz nada sobre quão ruim um ano ruim pode ficar, que para alguns
riscos é a única pergunta que importa.
