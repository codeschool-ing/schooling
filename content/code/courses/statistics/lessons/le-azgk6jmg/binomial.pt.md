---
title: A distribuição binomial
version: 1
---

Os registros da Horta dizem que 15% das entregas chegam atrasadas. Hoje à noite há 10 entregas. Qual é a
chance de 3 ou mais atrasarem?

A **distribuição binomial** responde perguntas exatamente desse formato. Ela se aplica quando:

1. há um número fixo de **tentativas**, *n* — aqui 10 entregas;
2. cada tentativa tem dois resultados, um **sucesso** e um fracasso — atrasada ou no prazo, em que
   "sucesso" é só o resultado que se está contando;
3. cada tentativa tem a mesma probabilidade de sucesso, *p* — aqui 0,15;
4. as tentativas são **independentes**: uma entrega atrasar não muda a chance de outra.

A variável aleatória é o número de sucessos, que pode ir de 0 a *n*.

## A fórmula, e de onde ela vem

A probabilidade de exatamente *k* sucessos em *n* tentativas é

```localised
P(X = k) = C(n, k) × p^k × (1 − p)^(n − k)
```

Cada pedaço tem um motivo. Uma sequência específica qualquer com *k* atrasadas e *n* − *k* no prazo tem
probabilidade *p*^*k* × (1 − *p*)^(*n* − *k*), multiplicando chances independentes. E existem **C(*n*,
*k*)** sequências assim — "combinação de *n*, *k* a *k*", o número de jeitos de escolher quais *k* das *n*
tentativas são as atrasadas.

Para exatamente 2 atrasadas em 10: C(10, 2) = 45, então P(X = 2) = 45 × 0,15² × 0,85⁸ = **0,2759**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l08-binomial\" aria-label=\"Um gráfico de barras da distribuição binomial com 10 entregas, cada uma atrasando com probabilidade 0,15. As barras de 0 a 5 atrasos são 0,197, 0,347, 0,276, 0,130, 0,040 e 0,008; de 6 para cima são pequenas demais para ver. As barras de 3 ou mais estão destacadas e somam 0,180.\"><path d=\"M70.0 40.0 L70.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 200.0 L70.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M70.0 160.0 L570.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 160.0 L70.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,1</text><path d=\"M70.0 120.0 L570.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 120.0 L70.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M70.0 80.0 L570.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 80.0 L70.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,3</text><path d=\"M70.0 40.0 L570.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 40.0 L70.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">probabilidade</text><path d=\"M83.4 200.0 L83.4 121.3 L110.2 121.3 L110.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"96.8\" y=\"112.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0,197</text><text x=\"96.8\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M128.0 200.0 L128.0 61.0 L154.8 61.0 L154.8 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"141.4\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0,347</text><text x=\"141.4\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M172.7 200.0 L172.7 89.6 L199.5 89.6 L199.5 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"186.1\" y=\"80.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0,276</text><text x=\"186.1\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M217.3 200.0 L217.3 148.1 L244.1 148.1 L244.1 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"230.7\" y=\"139.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0,130</text><text x=\"230.7\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M262.0 200.0 L262.0 184.0 L288.8 184.0 L288.8 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"275.4\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0,040</text><text x=\"275.4\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M306.6 200.0 L306.6 196.6 L333.4 196.6 L333.4 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"320.0\" y=\"187.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0,008</text><text x=\"320.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M351.2 200.0 L351.2 199.5 L378.0 199.5 L378.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"364.6\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><path d=\"M395.9 200.0 L395.9 199.9 L422.7 199.9 L422.7 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"409.3\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7</text><path d=\"M440.5 200.0 L440.5 200.0 L467.3 200.0 L467.3 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"453.9\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8</text><path d=\"M485.2 200.0 L485.2 200.0 L512.0 200.0 L512.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"498.6\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9</text><path d=\"M529.8 200.0 L529.8 200.0 L556.6 200.0 L556.6 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"543.2\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10</text><path d=\"M70.0 200.0 L570.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">entregas atrasadas em 10</text><text x=\"387.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">3 ou mais: 0,180</text></svg>", "caption": "Uma contagem, onze valores possíveis, e uma probabilidade para cada. As barras destacadas são as noites com três ou mais atrasos."}
```

## Três ou mais atrasadas

"3 ou mais" é tudo menos 0, 1 e 2. Somando essas três barras e subtraindo de 1:

```localised
1 − (0,1969 + 0,3474 + 0,2759) = 0,1798
```

Cerca de **18% das noites** com dez entregas vão ter três ou mais atrasos. A planilha faz a soma por você:

```localised
=DISTR.BINOM(2; 10; 0,15; FALSO)          0,275896656602051
=1 - DISTR.BINOM(2; 10; 0,15; VERDADEIRO) 0,179803519632422
```

O último argumento escolhe entre uma barra (`FALSO`) e o total de todas as barras até ela, inclusive
(`VERDADEIRO`), chamado de probabilidade **acumulada**.

## Média e dispersão

Uma distribuição binomial tem média ***np*** e desvio padrão **√(*np*(1 − *p*))**. Para dez entregas a
15%: média de 1,5 entrega atrasada por noite, com desvio padrão de 1,13.

## Quando as condições falham

A quarta condição é a que mais quebra. Numa noite de chuva, todas as entregas ficam mais propensas a
atrasar juntas. As tentativas deixam de ser independentes, as noites ruins se agrupam, e a binomial vai
subestimar quantas vezes três ou mais atrasam. Um modelo com a média certa e a independência errada erra
as caudas, que é onde costumam estar as perguntas importantes.
