---
title: Os cinco porquês
version: 1
---

**Os cinco porquês são o método de causa raiz mais simples que existe: declare o problema, pergunte por que ele
aconteceu, depois pergunte por que sobre a resposta, e continue até a resposta ser algo que o time pode mudar.**
Vêm da Toyota, onde Taiichi Ohno os ensinava como parte do mesmo sistema de produção que deu ao Kanban seus cartões;
cinco é uma regra prática de quão fundo a primeira causa útil costuma estar, não uma cota.

## A sessão das 9:30 de domingo

O Cine Aurora os aplicou na retrospectiva depois do defeito da aula 4, partindo da declaração do problema da seção
anterior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 330\" role=\"img\" data-fig=\"l18-whys\" aria-label=\"Os cinco porquês como uma cadeia descendo. O problema: a sessão das 9:30 foi cobrada pelo preço da noite. Porquê um: 9:30 foi comparado com 17:00 como texto. Porquê dois: o Rafael supôs uma hora de dois dígitos. Porquê três: todo exemplo tinha dois dígitos. Porquê quatro: ninguém perguntou à Célia como ela digita os horários. Porquê cinco: o planejamento não pergunta de onde vem cada entrada. A ação: o planejamento pergunta de onde vem cada entrada.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150.0\" y=\"8.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"23.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">sessão das 9:30 cobrada pelo preço da noite</text><text x=\"140.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por quê 1</text><rect x=\"150.0\" y=\"52.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;9:30&quot; comparado com &quot;17:00&quot; como texto</text><path d=\"M310.0 39.0 L310.0 51.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por quê 2</text><rect x=\"150.0\" y=\"98.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">supôs uma hora de dois dígitos</text><path d=\"M310.0 85.0 L310.0 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por quê 3</text><rect x=\"150.0\" y=\"144.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo exemplo tinha dois dígitos</text><path d=\"M310.0 131.0 L310.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por quê 4</text><rect x=\"150.0\" y=\"190.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ninguém perguntou à Célia como ela digita</text><path d=\"M310.0 177.0 L310.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por quê 5</text><rect x=\"150.0\" y=\"236.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o planejamento não pergunta de onde vem cada entrada</text><path d=\"M310.0 223.0 L310.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"110.0\" y=\"292.0\" width=\"400.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"307.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">ação: o planejamento pergunta de onde vem cada entrada</text><path d=\"M310.0 277.0 L310.0 291.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path></svg>", "caption": "Cada resposta vira a próxima pergunta. A cadeia para numa causa que o time pode mudar, e que preveniria mais do que este defeito."}
```

1. **Por que o pedido foi cobrado pelo preço da noite?** Porque `price()` comparou o horário `9:30` com `17:00`
   como texto, e como texto `9:30` vem depois de `17:00`.
2. **Por que comparou os horários como texto?** Porque o Rafael o escreveu supondo que todo horário tinha dois
   dígitos na hora, e com dois dígitos uma comparação de texto por acaso funciona.
3. **Por que ele supôs dois dígitos?** Porque todo exemplo que ele tinha visto tinha: as sessões eram às 15:00, 17:00
   e 20:00, e ninguém tinha mencionado como os horários eram digitados.
4. **Por que ninguém tinha mencionado?** Porque quem digita a programação é a Célia, e ninguém que constrói o sistema
   jamais tinha perguntado a ela como.
5. **Por que ninguém tinha perguntado?** Porque o planejamento nunca perguntava de onde vem cada entrada. O time
   discutia o que o programa faz com um horário, nunca quem escreve o horário e como.

A quinta resposta é uma lacuna no processo, e uma lacuna que o time consegue fechar. A aula 12 registrou a ação que
saiu desta retrospectiva: **para toda entrada nova, o planejamento pergunta de onde ela vem**, e a pessoa que a produz
é consultada sobre como. É uma frase numa lista. Teria prevenido o defeito, e vai prevenir defeitos em entradas em que
ninguém pensou ainda, o que nenhuma correção em `price()` conseguiria.

## Quando parar

Pare quando a resposta for uma causa sobre a qual o time pode agir, e agir sobre ela prevenir este defeito *e outros
parecidos*. A primeira resposta, a comparação de texto, é uma causa, e corrigi-la corrige este defeito. Não previne a
próxima suposição sobre a próxima entrada, e é por isso que a análise não parou ali.

Dois sinais de que foi longe demais: a resposta está fora do alcance do time (*porque o cinema decidiu abrir nas
manhãs de domingo*), ou a resposta é uma pessoa (*porque o Rafael é descuidado*). A primeira não dá para mudar; a
segunda é a culpa contra a qual a seção anterior alertou, e quase sempre é sinal de que um *porquê* foi pulado: *por
que era razoável uma pessoa cuidadosa fazer isso?*

## Onde o método é fraco

Os cinco porquês são populares porque são rápidos, e são fracos do jeito que coisas rápidas são.

- **Seguem uma cadeia só.** A maioria dos defeitos tem várias causas ao mesmo tempo, e a cadeia segue a resposta que
  veio primeiro. Pergunte o segundo *porquê* de outro jeito, *por que a revisão não pegou?*, e outra cadeia cresce do
  mesmo defeito: o Tomás revisou sozinho, um dia depois, sem os exemplos.
- **Só acham o que a sala sabe.** Se ninguém na retrospectiva soubesse que a Célia digita a programação, a cadeia
  teria parado em *o Rafael supôs dois dígitos*, e a ação teria sido *tomar mais cuidado*.
- **Pessoas diferentes chegam a respostas diferentes.** Dois grupos aplicando o método ao mesmo defeito muitas vezes
  terminam em causas raiz diferentes, ambas plausíveis.

Nada disso os torna inúteis. Torna-os uma boa primeira ferramenta, e um motivo para pegar a próxima, o diagrama de
Ishikawa, quando um defeito parece ter mais de uma causa.
