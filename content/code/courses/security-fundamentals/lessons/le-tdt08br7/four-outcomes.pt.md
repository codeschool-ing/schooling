---
title: Quatro resultados
version: 1
---

A aula 10 terminou com uma detecção que não tinha como funcionar, porque o log não tinha hora. Suponha
que tivesse. Uma detecção é uma regra que olha eventos e decide, para cada um, se gera um alerta. Toda
decisão dessas está certa ou errada, e o alerta é gerado ou não, então existem exatamente quatro
resultados:

```schooling-figure
{"svg": "<svg id=\"sf-confusion\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma matriz de confusão. Colunas: o que de fato aconteceu, um ataque ou nada de ruim. Linhas: o que o detector disse, alerta ou sem alerta. Alerta e ataque é verdadeiro positivo. Alerta e nada de ruim é falso positivo. Sem alerta e ataque é falso negativo. Sem alerta e nada de ruim é verdadeiro negativo.\"><text x=\"440\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o que de fato aconteceu</text><text x=\"330\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um ataque</text><text x=\"550\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nada de ruim</text><text x=\"20\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o que o</text><text x=\"20\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">detector disse</text><text x=\"210\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alerta</text><text x=\"210\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sem alerta</text><rect x=\"230\" y=\"60\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">TP</text><text x=\"330\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">verdadeiro positivo</text><rect x=\"450\" y=\"60\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">FP</text><text x=\"550\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">falso positivo</text><rect x=\"230\" y=\"150\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">FN</text><text x=\"330\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">falso negativo</text><rect x=\"450\" y=\"150\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">TN</text><text x=\"550\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">verdadeiro negativo</text></svg>", "caption": "A segunda palavra: o que o detector disse. A primeira: se ele acertou."}
```

| resultado | o alerta | o que de fato aconteceu | na livraria |
|---|---|---|---|
| **verdadeiro positivo (TP)** | gerado | algo ruim | o alerta dispara com alguém adivinhando senhas |
| **falso positivo (FP)** | gerado | nada de ruim | o alerta dispara com um backup de senha antiga |
| **falso negativo (FN)** | não gerado | algo ruim | alguém adivinha devagar o bastante para ficar abaixo da regra |
| **verdadeiro negativo (TN)** | não gerado | nada de ruim | alguém da equipe erra a senha uma vez e entra na segunda |

Os nomes são feitos de duas palavras, e lê-los assim torna impossível confundi-los. A segunda palavra,
**positivo** ou **negativo**, é o que o detector disse: alerta ou sem alerta. A primeira, **verdadeiro**
ou **falso**, é se ele acertou. Um falso negativo é um "sem alerta" que estava errado: a coisa ruim
aconteceu e nada disse isso. As siglas vêm do inglês (*true positive*, *false positive*, *false
negative*, *true negative*) e é assim que aparecem nas ferramentas.

A grade também tem nome: **matriz de confusão**, porque mostra exatamente onde o detector confunde uma
coisa com outra.

### Qual erro é pior

Nenhum, em geral. Depende do que cada um custa, e eles custam coisas diferentes:

- um **falso positivo** custa **tempo e atenção**. Alguém precisa olhar, decidir que não é nada e
  seguir. Um custa minutos. Milhares custam a confiança da equipe nos alertas, que é o assunto da
  última seção desta aula.
- um **falso negativo** custa **o que o ataque conseguir**, e custa em silêncio. Ninguém olha, porque
  nada pediu que olhassem.

Um detector de fumaça é ajustado para aceitar falsos positivos (torrada queimada) porque um falso
negativo é um incêndio. Um filtro de spam é ajustado ao contrário, porque um e-mail de verdade perdido
no spam é pior que uma propaganda de vez em quando na caixa de entrada. Detecções de segurança ficam
em algum lugar entre os dois, e onde exatamente é uma decisão sobre custo, e é por isso que o
raciocínio de risco da aula 3 vale também para a detecção.

As mesmas quatro palavras aparecem bem longe da segurança: em exames médicos, em controle de
qualidade, na avaliação de qualquer classificador. O `statistics` e os cursos de aprendizado de máquina
as usam com o mesmo sentido.
