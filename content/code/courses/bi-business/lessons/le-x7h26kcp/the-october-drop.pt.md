---
title: A queda de outubro, numa planilha
version: 1
---

A árvore disse que a queda está na loja online. Mas uma árvore desenhada à mão pode esconder um
erro. Então a Lívia pôs outubro numa planilha, linha por linha, e fez uma pergunta mais precisa:
**quanto da variação do total cada linha explica?** A resposta é um número por linha que soma os
−0,7%, chamado de contribuição, e é a coluna mais útil do trabalho de diagnóstico.

## A tabela

Acrescente uma aba e digite outubro de 2024 e outubro de 2025 de cada loja e da loja online, em
milhares de reais, a partir de A1:

| | A | B | C |
|---|---|---|---|
| 1 | Linha | Out 2024 | Out 2025 |
| 2 | Savassi | 950 | 993 |
| 3 | Pampulha | 848 | 882 |
| 4 | Contagem | 1036 | 1042 |
| 5 | Betim | 716 | 738 |
| 6 | Nova Lima | 750 | 789 |
| 7 | Sete Lagoas | 545 | 561 |
| 8 | Divinópolis | 520 | 539 |
| 9 | Ipatinga | 562 | 588 |
| 10 | Juiz de Fora | 723 | 748 |
| 11 | Online | 1370 | 1080 |

Em A12 digite `Total`, e as duas somas em B12 e C12:

```localised
=SOMA(B2:B11)      8020
=SOMA(C2:C11)      7960
```

Elas batem com os números mensais da aula 6, que é a primeira conferência de qualquer decomposição:
**as partes somam de volta o total que você está explicando.** Se não somassem, haveria vendas no
total e em nenhuma linha, e o diagnóstico seria sobre o número errado.

## A variação, e a contribuição

Em D1 digite `Variação` e em D2 a variação em reais; em E1 digite `Pontos` e em E2 a variação como
parcela de todo o outubro de 2024:

```localised
=C2-B2      43
=ARRED(D2/B$12*100;1)      0,5
```

Copie as duas até a linha 11, e ponha a variação do total em D12. O `$` mantém toda linha dividida
pelo mesmo total, que é o que faz a coluna somar. Leia a coluna E:

| linha | variação | pontos |
|---|---|---|
| cada loja | entre +6 e +43 | entre +0,1 e +0,5 |
| as nove lojas juntas | +230 | +2,9 |
| online | −290 | −3,6 |
| total | −60 | −0,7 |

**Todas as lojas cresceram, e juntas somaram 2,9 pontos a outubro. A loja online tirou 3,6.** Isso é
a queda inteira, e mais: sem a loja online, o outubro das lojas cresceu 3,5%. Os pontos
arredondados das lojas na coluna E somam 2,8, e não 2,9, pelo mesmo motivo que as parcelas da aula 1
somaram 99,9. Cada um foi arredondado sozinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Barras horizontais, uma por linha da tabela de outubro, mostrando quantos pontos percentuais cada uma somou ou tirou da variação total de −0,7%. Cada uma das nove lojas soma entre 0,1 e 0,5 ponto. A loja online tira 3,6 pontos.\" data-fig=\"l07-points\"><path d=\"M470.0 20.0 L470.0 290.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"150.0\" y=\"42.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Savassi</text><path d=\"M470.0 31.0 H497.9 V47.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"503.9\" y=\"43.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,5</text><text x=\"150.0\" y=\"68.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pampulha</text><path d=\"M470.0 57.0 H492.0 V73.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"498.0\" y=\"69.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,4</text><text x=\"150.0\" y=\"94.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Contagem</text><path d=\"M470.0 83.0 H473.9 V99.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"479.9\" y=\"95.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,1</text><text x=\"150.0\" y=\"120.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Betim</text><path d=\"M470.0 109.0 H484.3 V125.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"490.3\" y=\"121.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,3</text><text x=\"150.0\" y=\"146.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Nova Lima</text><path d=\"M470.0 135.0 H495.3 V151.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"501.3\" y=\"147.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,5</text><text x=\"150.0\" y=\"172.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Sete Lagoas</text><path d=\"M470.0 161.0 H480.4 V177.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"486.4\" y=\"173.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,2</text><text x=\"150.0\" y=\"198.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Divinópolis</text><path d=\"M470.0 187.0 H482.3 V203.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"488.3\" y=\"199.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,2</text><text x=\"150.0\" y=\"224.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ipatinga</text><path d=\"M470.0 213.0 H486.9 V229.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"492.9\" y=\"225.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,3</text><text x=\"150.0\" y=\"250.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Juiz de Fora</text><path d=\"M470.0 239.0 H486.2 V255.0 H470.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"492.2\" y=\"251.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+0,3</text><text x=\"150.0\" y=\"276.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Online</text><path d=\"M282.0 265.0 H470.0 V281.0 H282.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"276.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">−3,6</text><text x=\"470.0\" y=\"314.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pontos percentuais dos −0,7% de outubro</text><text x=\"454.0\" y=\"336.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">lojas juntas: +2,9</text><text x=\"486.0\" y=\"336.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">online: −3,6</text></svg>", "caption": "Onde está a variação de outubro. Cada loja somou um pouco; a loja online tirou mais do que as nove somaram juntas.", "same": ["Betim", "Contagem", "Divinópolis", "Ipatinga", "Juiz de Fora", "Nova Lima", "Online", "Pampulha", "Savassi", "Sete Lagoas"]}
```

## Por que pontos, e não o crescimento de cada linha

O crescimento de cada linha conta outra história. A loja online caiu 21,2% sobre si mesma, e
Contagem cresceu 0,6%; nenhum dos dois números diz quanto aquela linha mexeu na empresa. **O
crescimento de uma linha ignora o tamanho dela; a contribuição o pesa.** Nova Lima cresceu 5,2% e
somou 0,5 ponto. Uma loja com um décimo do tamanho dela crescendo 50% somaria quase o mesmo, e
pareceria dez vezes mais dramática numa coluna de taxas de crescimento.

A contribuição também mantém o diagnóstico honesto sobre o que ele não explicou. Se as linhas
tivessem caído um pouco cada uma, sem nenhuma concentrar a variação, a árvore diria que a causa é algo
que todas compartilham, como o calendário, a economia ou o jeito de contar as vendas. Aqui uma linha
concentra a variação, então o próximo passo é perguntar o que aconteceu com essa linha em outubro de
2025 e não em outubro de 2024. Isso é uma lista de suspeitos.
