---
title: Requisitos no backlog
version: 1
---

Um requisito num arquivo CSV é uma promessa. **Ele vira trabalho quando chega ao lugar de onde a
equipe planeja o trabalho**, e esse lugar é o backlog, com as mesmas regras de prioridade de
qualquer outro item. Requisitos de segurança que moram num documento separado são feitos num tempo
separado, o que na prática quer dizer depois de todo o resto.

### Três formas que um requisito toma lá

| forma | quando cabe | na Vereda |
|---|---|---|
| **uma história própria** | o requisito é uma funcionalidade que alguém vai usar | R17, pacientes veem e encerram as sessões abertas |
| **critério de aceite numa história existente** | o requisito restringe uma funcionalidade que está sendo construída de qualquer jeito | R13 na história que redesenha a página de upload |
| **uma regra na definição de pronto** | o requisito vale para toda história de um tipo | a verificação de dono do R10, para toda história que devolve dados de um paciente |

A terceira forma é a mais poderosa e a menos usada. Uma regra na definição de pronto é conferida em
toda história sem ninguém precisar lembrar a ameaça por trás dela: "todo endpoint novo que devolve
dados de paciente confere que os dados pertencem ao paciente logado, e tem um teste que pede os de
outra pessoa".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l08-backlog-shapes\" aria-label=\"Três formas que um requisito toma no backlog. Uma história própria, para uma funcionalidade que alguém usa: o R17, pacientes veem e encerram as sessões abertas. Critérios de aceite numa história que vai ser construída de qualquer jeito: o R13 na história que refaz a página de upload. Uma regra na definição de pronto, aplicada a toda história de um tipo: a verificação de dono do R10 em toda história que devolve dado de paciente.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma história própria</text><text x=\"120.0\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">R17: ver e encerrar</text><text x=\"120.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sessões abertas</text><rect x=\"260.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a história da página</text><rect x=\"275.0\" y=\"110.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"128.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">critérios: R13,</text><text x=\"360.0\" y=\"141.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20 MB, só PDF</text><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">critérios de aceite</text><rect x=\"510.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"574.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"638.0\" y=\"60.0\" width=\"56.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pronto: R10 em cada</text><text x=\"600.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">definição de pronto</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a terceira forma é conferida em toda história, sem ninguém lembrar a ameaça</text></svg>", "caption": "Um requisito vira trabalho; um vai junto de um trabalho já planejado; um vira hábito da equipe."}
```

### Mantendo o fio

Cada item do backlog leva o id do requisito, e o requisito leva o da ameaça. É tudo de que o fio
precisa. Quando o daniel pergunta por que uma história sobre números de telefone está acima de uma
história sobre o calendário de agendamentos, a resposta é o R19, que responde à T17, que é o caso de
abuso em que um ex-parceiro toma a conta de um paciente. Uma prioridade com motivo por trás
sobrevive à reunião de planejamento melhor que uma sem motivo.

### Quem decide a ordem

O dono do produto ordena o backlog, e itens de segurança não são exceção. O que o modelo de ameaças
contribui é a informação para ordená-los bem: qual objetivo cada ameaça põe em risco, do estágio 1
do PASTA, e de que tamanho é o risco, que as aulas 9 a 11 transformam em números. Quem é de segurança
e quer um requisito feito primeiro deveria conseguir dizer por quê nesses termos. Se não conseguir, a
ordem que o dono do produto escolheu provavelmente está certa.
