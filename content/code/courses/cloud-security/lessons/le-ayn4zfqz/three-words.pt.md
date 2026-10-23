---
title: Conformidade, residência e soberania são três perguntas diferentes
version: 1
---

**Três palavras são usadas como se quisessem dizer a mesma coisa, e cada uma responde a uma pergunta
diferente. Residência pergunta onde o dado está. Soberania pergunta qual lei consegue alcançá-lo.
Conformidade pergunta se você cumpre um conjunto de regras, e se consegue provar.** Uma clínica
consegue acertar uma e errar as outras duas na mesma tarde.

A imagem errada comum é um interruptor só: escolha a região de São Paulo e o dado fica brasileiro,
legal e protegido. Escolher `sa-east-1` resolve a primeira pergunta para as cópias que você põe lá.
Não diz nada sobre o backup que alguém fez em outra região, nada sobre quais governos podem obrigar o
provedor a entregar dados, e nada sobre se a clínica consegue mostrar a um auditor que sabe de tudo
isso.

| | a pergunta | o que a responde | onde esta aula trata dela |
|---|---|---|---|
| **residência** | em que país cada cópia é guardada e processada? | a região de cada recurso, lida pela API | a seção sobre achar o dado, e a proteção depois dela |
| **soberania** | as leis e os tribunais de quem podem exigir acesso a ele? | onde o dado está **e** quem é o provedor | a última seção |
| **conformidade** | a clínica cumpre as regras que valem para ela, como a LGPD, e consegue provar? | evidência: inventários, logs, políticas, relatórios | a próxima seção e a última |

## Por que elas se separam

**Residência é um fato sobre um recurso.** Um bucket está em exatamente uma região, e a API diz qual.
É a única das três que você confere com um comando, e o scanner da aula 16 poderia carregá-la como
regra.

**Soberania é um fato sobre uma relação.** Os prontuários da clínica podem estar em São Paulo, em
discos no Brasil, e ainda assim nas mãos de uma empresa constituída nos Estados Unidos, que a lei dos
Estados Unidos pode obrigar a entregar o que ela controla. Onde os bytes estão e quem responde por
eles são coisas separadas, e a segunda não muda quando você escolhe uma região.

**Conformidade é um fato sobre evidência.** Uma regra que ninguém consegue mostrar sendo seguida é,
para um auditor, uma regra que não é seguida. Os certificados do provedor provam a metade dele da
linha da aula 2; a metade da clínica é provada pela clínica, e o curso vem produzindo essa evidência
desde o começo — um inventário na aula 1, um relatório de credenciais na aula 6, uma varredura na
aula 16.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l17-reach\" aria-label=\"Residência contra soberania, para a clínica. Duas regiões: São Paulo, sa-east-1, guarda clinic-records e clinic-exports; Norte da Virgínia, us-east-1, guarda clinic-backups-us. Residência é onde cada cópia está: duas no Brasil, uma nos Estados Unidos. Soberania é qual lei as alcança. A lei brasileira, a LGPD, alcança a clínica e portanto toda cópia que ela controla. A lei dos Estados Unidos, pelo CLOUD Act, alcança o provedor, uma empresa americana, e portanto toda cópia que ele guarda, nas duas regiões.\"><rect x=\"40.0\" y=\"20.0\" width=\"640.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lei brasileira (LGPD): alcança a clínica, logo toda cópia que ela controla</text><rect x=\"40.0\" y=\"64.0\" width=\"640.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">lei dos EUA (CLOUD Act): alcança o provedor, logo toda cópia que ele guarda</text><rect x=\"40.0\" y=\"128.0\" width=\"300.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo — Brasil</text><text x=\"190.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"80.0\" y=\"182.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-records</text><rect x=\"80.0\" y=\"220.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-exports</text><rect x=\"380.0\" y=\"128.0\" width=\"300.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"530.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Norte da Virgínia — Estados Unidos</text><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">us-east-1</text><rect x=\"420.0\" y=\"182.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-backups-us</text><text x=\"360.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">residência: onde cada cópia está — duas no Brasil, uma fora</text></svg>", "caption": "Escolher a região decide a residência, a parte de baixo do desenho. Não decide a de cima: as duas leis alcançam a cópia em São Paulo, porque uma segue a clínica e a outra segue o provedor."}
```

A aula 17 do curso `security-fundamentals` mostrou o que a LGPD protege e por que dado de saúde é
*sensível*. Esta aula pega a única parte disso que a nuvem torna urgente: dado que sai do país, às
vezes sem ninguém decidir que ele deveria sair.
