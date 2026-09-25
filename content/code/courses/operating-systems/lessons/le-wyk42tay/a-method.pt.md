---
title: Um método, seja qual for o sistema
version: 1
---

As ferramentas mudam entre sistemas; a ordem das perguntas não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Um diagnóstico como seis passos em ciclo. O que acontece, exatamente? Desde quando, e o que mudou? O que os logs dizem? Testar uma explicação. Consertar a menor coisa. Confirmar, e anotar. Se o teste falhar, voltar aos logs com a próxima explicação.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que acontece, exatamente?</text><rect x=\"250\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desde quando, e o que mudou?</text><rect x=\"480\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que os logs dizem?</text><rect x=\"480\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">testar uma explicação</text><rect x=\"250\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consertar a menor coisa</text><rect x=\"20\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confirmar, e anotar</text><path d=\"M232 38 L248 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M462 38 L478 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M585 58 L585 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M478 102 L462 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M248 102 L232 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"700\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">errado? de volta aos logs</text></svg>", "caption": "A segunda pergunta resolve mais problemas que qualquer ferramenta: a maioria das falhas começa no dia em que algo mudou, uma atualização, um programa novo, um cabo mexido."}
```

1. **O que acontece, exatamente?** O texto do erro, palavra por palavra, ou uma captura de tela, o hábito
   da aula 7. "Não funciona" não é um sintoma.
2. **Desde quando, e o que mudou?** Uma atualização, um programa novo, um cabo mexido, uma troca de senha.
   O `history.log` da aula 11, o histórico de atualizações da aula 16 e o Monitor de Confiabilidade
   respondem com datas.
3. **O que os logs dizem?** Em volta da hora em que começou, filtrados pelo programa envolvido.
4. **Teste uma explicação.** Mude uma coisa, e veja se o sintoma muda. Duas mudanças de uma vez deixam
   você sem saber qual funcionou.
5. **Conserte a menor coisa** que remove a causa, e prefira o conserto que pode ser desfeito, a regra da
   aula 15.
6. **Confirme, e anote.** Confira a saída, como a seção 03 fez com o arquivo do relatório, e registre o
   que aconteceu, o que resolveu e como você soube. A próxima pessoa com esse problema pode ser você,
   daqui a um ano.

Este curso termina aqui, com os três sistemas instalados, entendidos e funcionando. O curso de *suporte
técnico* leva o método adiante, com a pessoa do outro lado do chamado; o de *virtualização* roda os
três sistemas lado a lado numa máquina só.
