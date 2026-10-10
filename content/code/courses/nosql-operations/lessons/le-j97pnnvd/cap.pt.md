---
title: O que o CAP diz, e a versão que todo mundo repete
version: 1
---

A versão que todo mundo já ouviu é um cardápio: **consistência, disponibilidade, tolerância a
partição, escolha duas.** É curta, soa como engenharia e não descreve nenhum sistema que alguém
consiga construir. Duas das três escolhas não são escolha nenhuma.

## As três palavras, como a prova as usa

Eric Brewer apresentou a ideia em 2000, e Seth Gilbert e Nancy Lynch a provaram em 2002. A prova
precisa que cada palavra signifique uma coisa precisa, e nenhuma das três significa o que significa
na conversa do dia a dia:

| | no teorema | não confundir com |
|---|---|---|
| **C**onsistência | toda leitura devolve a escrita confirmada mais recente, como se houvesse uma cópia só do dado | o C do ACID, que trata de uma transação respeitar as regras do esquema |
| **A** (disponibilidade) | todo pedido que chega a um nó que não falhou recebe uma resposta que não é erro | "o site fica no ar quase sempre" |
| **P**artição | a rede entre as cópias perde mensagens, pelo tempo que quiser | um nó caindo, que é outro problema, e mais fácil |

A consistência do teorema tem nome próprio, **linearizabilidade**, e é uma promessa forte: depois
que qualquer cliente ouviu que uma escrita deu certo, nenhum cliente em lugar nenhum pode ler o
valor de antes dela.

## Por que "escolha dois" está errado

Um banco com uma única cópia dos dados não tem partição para tolerar, e é consistente e disponível
até a máquina morrer. O teorema fala do momento em que você mantém **mais de uma cópia**, em mais de
uma máquina, ligadas por uma rede. E uma rede entre máquinas não é algo que pode ou não particionar.
Cabos são cortados, switches reiniciam, uma zona de nuvem perde o link de saída, uma pausa longa de
coleta de lixo deixa um nó em silêncio até os outros concluírem que ele sumiu. Partições acontecem
com um sistema quer seus projetistas as tenham escolhido, quer não.

Então o P não está no cardápio. **A afirmação verdadeira é condicional: quando a rede entre as
cópias está quebrada, cada cópia isolada precisa ou se recusar a responder ou responder sem saber
da escrita mais recente.** Recusou, manteve a consistência e abriu mão da disponibilidade.
Respondeu, manteve a disponibilidade e abriu mão da consistência. Não há terceira opção, porque a
cópia não tem como saber o que não consegue ouvir.

## Uma partição, as duas respostas

Pegue a loja do `sql-databases`, agora rodando em dois lugares para que clientes dos dois lados do
Atlântico tenham uma página rápida: uma cópia do banco em São Paulo e outra em Lisboa. O monitor de
27 polegadas tem **uma unidade sobrando**. O link entre as duas cidades cai e, no mesmo minuto, um
cliente em cada cidade põe esse monitor na cesta e paga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Duas cópias do banco da loja, São Paulo à esquerda e Lisboa à direita, cada uma com um monitor em estoque. O link entre elas está cortado. Um cliente em cada cidade tenta comprar o monitor. Embaixo, os dois desfechos que o teorema permite: manter a consistência, e pelo menos uma cópia recusa a venda; manter a disponibilidade, e as duas cópias vendem a mesma unidade.\"><defs><marker id=\"cap1-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"52.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia em São Paulo</text><text x=\"130.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">monitores em estoque: 1</text><rect x=\"470\" y=\"30\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"52.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia em Lisboa</text><text x=\"570.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">monitores em estoque: 1</text><line x1=\"230\" y1=\"60\" x2=\"330\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><line x1=\"370\" y1=\"60\" x2=\"470\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">×</text><text x=\"350\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">link cortado</text><rect x=\"55\" y=\"120\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente compra</text><rect x=\"495\" y=\"120\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente compra</text><line x1=\"130\" y1=\"120\" x2=\"130\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cap1-ah-paper-dim)\"></line><line x1=\"570\" y1=\"120\" x2=\"570\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cap1-ah-paper-dim)\"></line><rect x=\"30\" y=\"190\" width=\"300\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">manter a consistência</text><text x=\"180.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a cópia que não consegue confirmar recusa:</text><text x=\"180.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma página de erro, e nenhuma unidade vendida duas vezes</text><rect x=\"370\" y=\"190\" width=\"300\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">manter a disponibilidade</text><text x=\"520.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">as duas cópias vendem:</text><text x=\"520.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">duas confirmações para uma unidade</text></svg>", "caption": "Uma partição deixa a cada cópia dois movimentos. Nenhuma das duas fica sabendo da venda da outra até o link voltar."}
```

Cada cópia tem exatamente os dois movimentos que o teorema permite:

- **Manter a consistência.** A cópia que não consegue confirmar com o outro lado recusa a venda, ou
  recusa toda escrita até o link voltar. Ninguém compra um monitor que não existe; os clientes de
  uma cidade, ou das duas, veem uma página de erro.
- **Manter a disponibilidade.** As duas cópias vendem. Os dois clientes recebem confirmação. Quando
  o link volta, as duas cópias têm duas vendas de uma unidade, e alguém precisa escrever um pedido de
  desculpas e fazer um reembolso.

Nenhum dos dois é bug. Qual é o certo depende do que está sendo vendido, e para um monitor com uma
unidade no depósito a maioria das lojas prefere mostrar um erro a vender vento. Para uma lista de
"vistos recentemente" no mesmo site, o segundo é obviamente melhor: ninguém sai prejudicado por uma
lista um minuto atrasada.

## O que o teorema não diz

Ele não diz nada sobre o tempo em que a rede funciona, que é quase o tempo todo. Não diz que um
sistema é "um banco CP" ou "um banco AP" para sempre: os produtos deste curso deixam você escolher
por operação, e a aula 17 faz o Cassandra agir dos dois jeitos na mesma tabela. E não mede quanto
de cada coisa você recebe: um sistema que recusa escritas por dois segundos durante um failover e
outro que as recusa por duas horas são, os dois, "não disponíveis" no sentido da prova.

A próxima seção trata da primeira dessas lacunas, porque é a que você paga todo dia.
