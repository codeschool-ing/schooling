---
title: A pirâmide da dor
version: 1
---

Em 2013, David Bianco desenhou a ideia como uma pirâmide. Cada camada é um tipo de indicador, ordenado por
**quanto custa ao adversário quando um defensor o detecta e ele precisa mudá-lo**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A pirâmide da dor, seis camadas de cima para baixo: TTPs, difícil para o adversário mudar; ferramentas, desafiador; artefatos de rede e de host, incômodo; nomes de domínio, simples; endereços IP, fácil; valores de hash, trivial. Quanto mais alta a camada que o defensor detecta, mais caro fica para o adversário escapar.\"><rect x=\"270.0\" y=\"10\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"23\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">TTPs</text><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">difícil</text><rect x=\"230.0\" y=\"54\" width=\"260\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desafiador</text><rect x=\"190.0\" y=\"98\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">artefatos de rede e de host</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">incômodo</text><rect x=\"150.0\" y=\"142\" width=\"420\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nomes de domínio</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">simples</text><rect x=\"110.0\" y=\"186\" width=\"500\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">endereços IP</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fácil</text><rect x=\"70.0\" y=\"230\" width=\"580\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">valores de hash</text><text x=\"360\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trivial</text></svg>", "caption": "Quanto custa ao adversário mudar cada tipo de indicador, segundo a pirâmide da dor de David Bianco.", "same": ["TTPs", "trivial"]}
```

Na base, um hash novo não custa nada: recompilar, reempacotar, mudar um byte. Um endereço IP custa alguns
minutos e um pouco de dinheiro. Um domínio, um pouco mais. **Artefatos de rede e de host**, como um user agent
característico ou um arquivo deixado sempre na mesma pasta, significam mudar o comportamento das ferramentas.
**Ferramentas** significam trocá-las ou reescrevê-las. E no topo, **TTPs** (táticas, técnicas e
procedimentos) são o jeito de trabalhar do adversário: mudá-los significa aprender um jeito novo de fazer o
serviço.

Duas coisas decorrem para um SOC. Detecções feitas nas camadas de baixo são baratas de escrever e baratas de
contornar; **invista no topo**, onde uma detecção sobrevive ao próximo endereço do adversário. E **use as
camadas de baixo para o que fazem bem**: confirmar, depressa e com certeza, que uma coisa conhecida está
aqui. A correspondência da aula 8 com `203.0.113.200` foi exatamente isso.

A quinta tem exemplos em três alturas. `203.0.113.66` é um endereço: bloqueie-o e a próxima tentativa vem de
outro. O hábito de tentar nomes tirados do próprio site da empresa está mais perto de um **procedimento**. E
"adivinhar muitas contas, entrar, ir ao servidor de arquivos, mandar um arquivo grande para fora" é a forma
da cadeia de **técnicas** que as últimas seções desta aula nomeiam.
