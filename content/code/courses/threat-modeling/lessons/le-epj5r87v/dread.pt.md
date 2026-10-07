---
title: DREAD, e por que a Microsoft o abandonou
version: 1
---

O STRIDE deixa as ameaças sem ordem, e o desejo óbvio seguinte é uma nota. O **DREAD** foi a
resposta da Microsoft no começo dos anos 2000: avaliar cada ameaça em cinco fatores, tirar a média
e ordenar.

| fator | a pergunta | 1 | 10 |
|---|---|---|---|
| **D**amage (dano) | quão ruim é se acontecer? | um incômodo | todos os prontuários, ou o sistema inteiro |
| **R**eproducibility (reprodutibilidade) | funciona toda vez? | raramente, em condições estranhas | toda vez |
| **E**xploitability (explorabilidade) | quanta habilidade e esforço exige? | um especialista, com tempo | qualquer um, com um navegador |
| **A**ffected users (usuários afetados) | quantas pessoas alcança? | uma | todas |
| **D**iscoverability (descoberta) | quão fácil é de achar? | precisa de conhecimento de dentro | óbvio de fora |

A ideia é razoável, e o método foi muito usado. Também é o único método com nome desta aula que
este curso desaconselha, e o motivo cabe numa figura.

### Duas pessoas, uma ameaça

A carla e a ana pontuaram, cada uma, a T01, o webhook forjado, com os mesmos fatos na frente:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-dread-raters\" aria-label=\"Duas pessoas pontuam o webhook forjado, T01, com DREAD de 1 a 10. carla: dano 6, reprodutibilidade 9, explorabilidade 8, usuários afetados 3, descoberta 7, média 6,6. ana: 4, 8, 5, 2 e 3, média 4,4. As maiores diferenças são descoberta, 7 contra 3, e explorabilidade, 8 contra 5.\"><text x=\"160.0\" y=\"43.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Damage</text><rect x=\"170.0\" y=\"30.0\" width=\"180.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"36.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6</text><rect x=\"170.0\" y=\"45.0\" width=\"120.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"296.0\" y=\"51.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4</text><text x=\"160.0\" y=\"83.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Reproducibility</text><rect x=\"170.0\" y=\"70.0\" width=\"270.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"76.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">9</text><rect x=\"170.0\" y=\"85.0\" width=\"240.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"91.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><text x=\"160.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Exploitability</text><rect x=\"170.0\" y=\"110.0\" width=\"240.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"116.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><rect x=\"170.0\" y=\"125.0\" width=\"150.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"326.0\" y=\"131.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5</text><text x=\"160.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Affected users</text><rect x=\"170.0\" y=\"150.0\" width=\"90.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"156.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"170.0\" y=\"165.0\" width=\"60.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"171.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><text x=\"160.0\" y=\"203.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Discoverability</text><rect x=\"170.0\" y=\"190.0\" width=\"210.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7</text><rect x=\"170.0\" y=\"205.0\" width=\"90.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><path d=\"M170.0 24.0 L170.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M230.0 24.0 L230.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M290.0 24.0 L290.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M350.0 24.0 L350.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M410.0 24.0 L410.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M470.0 24.0 L470.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><rect x=\"500.0\" y=\"60.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"510.0\" y=\"70.0\" width=\"10.0\" height=\"10.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">carla: média 6,6</text><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"510.0\" y=\"110.0\" width=\"10.0\" height=\"10.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ana: média 4,4</text><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesma ameaça, mesmos fatos,</text><text x=\"600.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma diferença de 2,2 pontos</text><text x=\"320.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nota, de 0 a 10</text></svg>", "caption": "A descoberta fez a maior parte do estrago: a carla supôs que alguém vai achar o endereço, a ana supôs que ninguém vai.", "same": ["Affected users", "Damage", "Discoverability", "Exploitability", "Reproducibility"]}
```

**Mesma ameaça, mesmos fatos, uma diferença de 2,2 pontos numa escala de dez.** Nenhuma das duas
está errada. A carla supôs que alguém vai achar o endereço do webhook, porque endereços vazam em
logs, históricos de navegador e nas próprias páginas de erro do gateway; a ana supôs que ninguém
de fora da Vereda o conhece. As duas coisas são premissas, a escala não tem como dizer qual está
certa, e a média esconde que a discordância existiu. Ordene catorze ameaças assim e a ordem depende
de quem segurava a caneta.

Foi essa a conclusão da própria Microsoft. As equipes de segurança dela pararam de usar o DREAD no
fim dos anos 2000, e quem o tinha promovido escreveu publicamente o porquê: as notas eram
subjetivas, não concordavam entre avaliadores, e a descoberta em particular premiava esconder uma
fraqueza em vez de corrigi-la.

### O que vale guardar dele

Duas coisas no DREAD são sólidas e sobrevivem em métodos melhores:

- **Separar quão provável de quão ruim.** Reprodutibilidade, explorabilidade e descoberta são sobre
  probabilidade; dano e usuários afetados são sobre impacto. As aulas 9 e 10 mantêm exatamente essa
  divisão e medem cada metade direito.
- **Anotar os fatores.** Mesmo uma nota contestada mostra *por que* alguém achou que uma ameaça
  importava. O 7 da carla para descoberta é um argumento que dá para conferir: procurar o endereço
  do webhook nos logs. A média de cinco argumentos assim, não.

### O que não fazer com ele

Não tire média de notas de pessoas diferentes, e não compare uma nota DREAD com uma nota CVSS ou
com um risco em reais. São escalas diferentes medindo coisas diferentes, e pô-las lado a lado numa
planilha dá uma ordem sem nada por trás.
