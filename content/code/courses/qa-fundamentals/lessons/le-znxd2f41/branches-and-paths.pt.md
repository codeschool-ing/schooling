---
title: Desvios, e os caminhos entre eles
version: 1
---

**A cobertura de comandos pergunta se cada linha rodou. A cobertura de desvios pergunta se cada decisão
foi para os dois lados.** A diferença importa em todo `if` que não faz nada quando é falso: a linha de
dentro pode rodar toda vez, e ninguém nunca confere o que acontece quando ela não roda.

## Cobertura de desvios dos sete casos

O `price` toma seis decisões. Com os sete casos da seção anterior, cada uma vai para os dois lados pelo
menos uma vez:

| decisão | verdadeira em | falsa em |
|---|---|---|
| `time < "17:00"` | o caso das 16:59 | os outros |
| `student` | o estudante de 20 | os outros |
| `age > 60` | o de sessenta e um | os outros |
| `age < 12` | a criança de 11 | os outros |
| `day == "wed"` | o adulto da quarta | os outros |
| `half` | o estudante, a criança, o de sessenta e um | os outros |

**Cobertura de desvios completa**, então. Toda decisão foi verdadeira e falsa, então toda seta saindo de
todo `if` foi seguida. E mesmo assim os dois defeitos das aulas 1 e 6 estão no código, intocados.

## Caminhos

Um **caminho** é uma rota pela função inteira, da primeira decisão até um `return`. Cada decisão tomada
para um lado ou para o outro manda o programa por um caminho diferente, e os defeitos do `price` não moram
em nenhuma decisão isolada, e sim em **combinações** delas.

Conte os caminhos que podem acontecer. A sessão é matinê ou não: dois. O cliente é estudante ou não: dois.
A idade o torna criança, adulto ou maior de sessenta: três. É quarta ou não: dois. São duas vezes duas
vezes três vezes duas, **vinte e quatro combinações**, cada uma um caminho diferente ou uma mistura
diferente de descontos pelos mesmos caminhos. Os sete casos percorrem seis delas; dois dos sete, o adulto
de 35 à noite e o de doze anos, percorrem a mesma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 230\" role=\"img\" data-fig=\"l07-paths\" aria-label=\"Uma grade de clientes contra sessões. Linhas: adulto, criança, mais de sessenta. Colunas: matinê, noite, matinê de quarta, noite de quarta. Os sete casos percorrem cinco dessas células: adulto na matinê, adulto à noite, criança à noite, mais de sessenta à noite, adulto numa noite de quarta. As quatro células que combinam uma criança ou alguém com mais de sessenta com uma quarta estão destacadas como nunca percorridas.\"><text x=\"216.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">matinê</text><text x=\"328.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">noite</text><text x=\"440.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">matinê de quarta</text><text x=\"552.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">noite de quarta</text><text x=\"150.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">adulto</text><rect x=\"163.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"216.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">percorrido</text><rect x=\"275.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">percorrido</text><rect x=\"387.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"440.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca percorrido</text><rect x=\"499.0\" y=\"47.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"552.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">percorrido</text><text x=\"150.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">criança</text><rect x=\"163.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"216.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca percorrido</text><rect x=\"275.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">percorrido</text><rect x=\"387.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"440.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca percorrido</text><rect x=\"499.0\" y=\"91.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"552.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca percorrido</text><text x=\"150.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mais de sessenta</text><rect x=\"163.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\" stroke-dasharray=\"3 3\"></rect><text x=\"216.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca percorrido</text><rect x=\"275.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"328.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">percorrido</text><rect x=\"387.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"440.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca percorrido</text><rect x=\"499.0\" y=\"135.0\" width=\"106.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"552.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca percorrido</text><text x=\"496.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">desconto e quarta: nunca percorrido</text></svg>", "caption": "Os estudantes ficaram de fora para caber; o caso do estudante fica na coluna da noite, e nenhum estudante numa quarta foi rodado também. As células destacadas são onde mora o defeito da soma de descontos."}
```

A figura deixa os estudantes de fora, para caber, e põe três tipos de cliente contra quatro tipos de
sessão. Cinco dos seis caminhos percorridos estão nela. Olhe onde eles ficam, e onde ficam os vazios.
**Todo caminho que combina um desconto com uma quarta está vazio.** É exatamente onde a aula 6 achou o
defeito da soma de descontos, de fora, perguntando o que a regra não dizia. De dentro, a mesma lacuna
aparece como uma região de caminhos que ninguém percorreu.

## Por que ninguém busca cobertura completa de caminhos

Vinte e quatro caminhos é administrável para uma função de seis decisões. Cada decisão independente nova
dobra a conta. Uma função com vinte `if`s independentes tem mais de um milhão de caminhos, e um laço que
pode rodar qualquer número de vezes tem mais caminhos do que se pode contar. Cobertura completa de
caminhos, em programas reais, não é uma meta que alguém alcance.

O que o raciocínio por caminhos dá a quem testa é um **jeito de perguntar onde olhar**: que decisões
interagem, de modo que suas combinações importam, e que combinações nenhum teste tentou. Aqui a resposta
foi "descontos e quarta", que é exatamente o par de decisões que mexem no preço. Quem testa não precisa
enumerar vinte e quatro caminhos para ver isso; precisa olhar o código e perguntar que `if`s mexem no mesmo
valor.

Essa é a versão de caixa branca do hábito que a aula 6 ensinou de fora: **para cada par de condições,
pergunte o que acontece quando as duas valem.** A caixa preta acha os pares na regra. A caixa branca os
acha no código, inclusive pares que a regra nunca menciona, porque eles existem no código tenha alguém os
escrito ou não.
