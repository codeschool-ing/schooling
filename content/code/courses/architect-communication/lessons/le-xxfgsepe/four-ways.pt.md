---
title: A mesma decisão, escrita de quatro jeitos
version: 1
---

**O teste de adaptar uma mensagem é escrever a mesma decisão para cada leitor e comparar o que
mudou.** Aqui está a decisão da réplica, da aula 2, depois de aprovada em 19 de março, do jeito que
Lívia a anunciou a cada um dos quatro públicos.

## Para o conselho, no relatório mensal de Otávio

> As falhas de checkout das noites de sexta, cerca de 180 pagamentos que falham por semana, serão
> corrigidas em abril, por seis semanas-engenheiro e R$ 4.000 por mês. A correção também elimina o
> risco de o checkout parar por completo no pico, que foi o que causou a queda de 32 minutos em 6
> de março.

Duas frases. A unidade é pagamentos e reais. A queda é citada porque o conselho já ouviu falar
dela; a réplica não é, porque ninguém no conselho vai decidir nada sobre ela.

## Para Renata, diretora de produto

> O trabalho da réplica foi aprovado e leva seis semanas-engenheiro do time de plataforma em abril.
> Com isso, o fluxo de substituição passa de abril para as duas primeiras semanas de maio; nada
> mais no roadmap muda. Em troca, as falhas de checkout de sexta devem cair de cerca de 180 por
> semana para quase zero, e o suporte para de receber as reclamações de sexta à noite que o time de
> Sofia registra toda semana. Confirmo a data de maio em 30 de abril, quando a troca estiver feita.

O que mudou: **o que sai do lugar** está na segunda frase, e o benefício aparece em efeitos que ela
já acompanha, checkouts que falham e reclamações no suporte. Há uma data para a próxima
atualização, porque produto planeja em torno de datas.

## Para o time de engenharia, no canal de plataforma

> Aprovado: em abril o planejador de rotas passa a usar uma réplica de leitura do banco de pedidos
> (proposta no link). Plataforma é dona da réplica; logística é dona da troca do planejador de
> rotas. Duas coisas que afetam outros times: a réplica pode ficar alguns segundos atrás do
> primário, então **não leiam dela nada que vocês vão escrever de volta**; e, conforme a RFC de
> conexões, a partir de 1º de maio cada serviço tem uma cota fixa de conexões no primário.
> Perguntas na thread, por favor, não no privado, para que as respostas possam ser encontradas.

A versão mais longa, com a restrição que importa para outros engenheiros em negrito, os donos
nomeados e uma regra sobre onde vão as perguntas. **O motivo da réplica não é repetido**: está na
proposta do link, e o time vai lê-lo lá.

## Para Tânia, diretora de operações da Boa Praça

A Boa Praça é uma rede de supermercados cujas entregas a Marola opera, e Tânia é a pessoa de lá que
responde aos próprios diretores quando as entregas dão errado.

> Tânia, na noite de sexta, 24 de abril, entre 23:00 e 23:30, vamos trocar uma parte do nosso
> sistema de planejamento de entregas. Pedidos já feitos não são afetados, e suas lojas não
> precisam fazer nada. Se notar qualquer coisa estranha nessa noite, me ligue direto no número que
> você tem. — Lívia

Nada sobre bancos de dados, réplicas ou o incidente. **O que muda para ela, quando, o que ela
precisa fazer (nada) e para quem ligar.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Quatro barras, as contagens de palavras da mesma decisão escrita para quatro leitores. O conselho: 44 palavras, em pagamentos e reais. Renata: 76 palavras, sobre o que muda no roadmap. O time: 87 palavras, com donos, restrições e regras. Tânia: 53 palavras, sobre o que muda para as lojas dela.\"><defs><marker id=\"lengths-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o conselho</text><rect x=\"130\" y=\"22\" width=\"176\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"314\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">44</text><text x=\"346\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pagamentos, reais</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Renata</text><rect x=\"130\" y=\"68\" width=\"304\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"442\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">76</text><text x=\"474\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que muda no roadmap</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o time</text><rect x=\"130\" y=\"114\" width=\"348\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"486\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87</text><text x=\"518\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">donos, restrições, regras</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tânia</text><rect x=\"130\" y=\"160\" width=\"212\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"350\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">53</text><text x=\"382\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que muda para as lojas dela</text><text x=\"130\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">palavras em cada versão da mesma decisão</text></svg>", "caption": "Contagem de palavras das versões em inglês. O tamanho acompanha o que o leitor decide, não a importância dele: o conselho recebe a mais curta.", "same": ["Renata", "Tânia"]}
```

## O que ficou igual

Toda versão que dá um número dá o mesmo: 180 falhas por semana, seis semanas-engenheiro, R$ 4.000
por mês, abril. **Os fatos são fixos, e tudo em volta deles se adapta.** Se uma das quatro tivesse
dito "algumas falhas" e outra "180", um leitor com as duas na mão teria motivo para se perguntar
qual dos dois estava sendo manobrado.
