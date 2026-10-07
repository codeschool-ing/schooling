---
title: Exceções que apodrecem
version: 1
---

Um risco aceito é uma exceção de segurança, e **exceções apodrecem**: sobrevivem ao motivo pelo qual
foram concedidas, à pessoa que as concedeu, e às vezes ao sistema a que se referiam. Toda organização
que audita as próprias exceções acha algumas que ninguém consegue explicar. Os hábitos abaixo existem
porque as falhas que eles evitam são as comuns.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l12-timeline\" aria-label=\"Uma linha do tempo de abril de 2026 a outubro de 2027. RA-002, aceitando a T06, decidido em 2 de abril de 2026, revisão para 2 de outubro de 2026, atrasada em 7 de outubro. RA-001, aceitando a T14, decidido em 1º de outubro de 2026, revisão para 1º de abril de 2027. DR-001, o segundo fator, decidido em 30 de setembro de 2026, revisão para 30 de setembro de 2027.\"><path d=\"M60.0 170.0 L690.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 170.0 L60.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">abr 2026</text><path d=\"M165.0 170.0 L165.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"165.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jul 2026</text><path d=\"M270.0 170.0 L270.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out 2026</text><path d=\"M375.0 170.0 L375.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jan 2027</text><path d=\"M480.0 170.0 L480.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"480.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">abr 2027</text><path d=\"M585.0 170.0 L585.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"585.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jul 2027</text><path d=\"M690.0 170.0 L690.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out 2027</text><rect x=\"61.2\" y=\"32.0\" width=\"210.0\" height=\"16.0\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"53.2\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RA-002</text><circle cx=\"271.2\" cy=\"40.0\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"268.8\" y=\"72.0\" width=\"420.0\" height=\"16.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"260.8\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">DR-001</text><circle cx=\"688.8\" cy=\"80.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><rect x=\"270.0\" y=\"112.0\" width=\"210.0\" height=\"16.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RA-001</text><circle cx=\"480.0\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M277.0 24.0 L277.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M277.0 90.0 L277.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M277.0 130.0 L277.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"283.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">7 out 2026: RA-002 atrasado</text></svg>", "caption": "Cada barra é uma decisão do dia em que foi tomada ao dia em que precisa ser revista. A linha tracejada é o dia em que o acceptances.py rodou."}
```

### Quatro jeitos de um aceite estragar

| falha | como aparece | o hábito que evita |
|---|---|---|
| **sem prazo** | "aceito" sem data, renovado por ninguém, verdade para sempre | todo aceite tem data de revisão, e um programa lista os atrasados |
| **o dono saiu** | quem assinou foi embora; ninguém é dono da revisão | quando alguém sai, as decisões dessa pessoa são reatribuídas no mesmo dia em que as contas dela são fechadas |
| **o risco cresceu** | aceito em R$ 9.000 por ano; o sistema mudou e agora é dez vezes isso | gatilhos no registro, e uma revisão sempre que o modelo muda o elemento a que ele se refere |
| **as compensações caducaram** | "a equipe só abre exames no console" era verdade em outubro e ninguém conferiu em março | os controles compensatórios são conferidos na revisão, e não só o risco |

A segunda linha é a que surpreende. O dono de uma decisão é uma pessoa, e pessoas mudam de emprego. A
checklist de saída da Vereda, a mesma de que o R06 depende para as contas da equipe, tem uma linha
para isso: *reatribuir as decisões abertas desta pessoa*. Sem essa linha, o RA-001 seria, a partir do
dia em que o daniel saísse, de ninguém.

### Renovar também é decisão

Quando a revisão chega, renovar um aceite é permitido, e é uma decisão nova com um registro novo: a
estimativa olhada de novo, os controles compensatórios conferidos, uma data nova. O que não é
permitido é mudar a data no arquivo antigo. Uma renovação que é a edição de uma linha vira um hábito
em que ninguém pensa, e um risco aceito por seis meses em 2026 continua aceito em 2030 porque a data
foi andando.

### Contando-os

O número de aceites abertos, e quantos estão atrasados, é uma das medidas mais simples de como um
programa de segurança está indo. Uma contagem que só cresce significa riscos sendo aceitos em vez de
corrigidos. Uma contagem com atrasados significa que as revisões não estão acontecendo. A aula 15 põe
essa contagem na mesma página que as outras medidas do modelo.
