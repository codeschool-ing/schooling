---
title: O diagrama de Ishikawa
version: 1
---

**Um diagrama de Ishikawa organiza as causas possíveis de um problema por categoria, para o time olhar em todas as
direções ao mesmo tempo em vez de seguir a primeira cadeia que ocorre a alguém.** Kaoru Ishikawa o desenvolveu em
fábricas japonesas e o espalhou nos anos 1960 pelos círculos de qualidade que defendia; também é chamado de
**diagrama de causa e efeito**, ou **espinha de peixe**, por causa da forma.

O problema vai na cabeça, à direita. Uma coluna corre até ela, e da coluna saem as espinhas, uma por categoria de
causa. Em cada espinha o time escreve as causas que consegue achar naquela categoria, e causas das causas como
espinhas menores saindo delas.

## Categorias para software

As fábricas usam seis categorias, conhecidas como os 6M: máquina, método, material, mão de obra, medição e meio
ambiente. Times de software costumam adaptá-las. O Cine Aurora usa estas seis:

| espinha | a pergunta que faz |
|---|---|
| **requisitos** | a regra dizia o que era preciso, e todo mundo a leu do mesmo jeito? |
| **processo** | que passo que deveria ter pegado o defeito faltou, atrasou ou foi pulado? |
| **pessoas** | o que as pessoas envolvidas sabiam, e o que nunca lhes contaram? |
| **ferramentas** | o que as ferramentas conferiam, e o que deixaram passar sem dizer nada? |
| **ambiente** | em que o mundo real era diferente daquele em que o time construiu e testou? |
| **medição** | o que teria mostrado o defeito, e por que ninguém estava olhando? |

As categorias são lembretes, não caixas a preencher. Uma espinha vazia está bem, desde que alguém tenha perguntado.

## O estudante da quarta

O Cine Aurora desenhou um para o defeito da aula 6, o estudante que pagou R$ 9,00 numa quarta à noite. Ele nunca
chegou a um cliente, mas só porque a Lia explorou antes da entrega, e a retrospectiva não conseguiu concordar numa
cadeia única de porquês para ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l18-fishbone\" aria-label=\"Um diagrama de Ishikawa. Na cabeça, à direita: um estudante paga R$ 9,00 numa quarta. Seis espinhas ligam-se à coluna. Requisitos: nada sobre combinar descontos. Processo: sem casos de combinação, e revisão sozinha, um dia depois. Pessoas: novo em preços. Ferramentas: sem verificação automática de preços. Ambiente: sessões de teste às quintas. Medição: o relatório esconde descontos.\"><path d=\"M20.0 150.0 L540.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"545.0\" y=\"112.0\" width=\"125.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607.5\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">estudante paga</text><text x=\"607.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">R$ 9,00 numa</text><text x=\"607.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">quarta</text><path d=\"M155.0 40.0 L215.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"155.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">requisitos</text><text x=\"171.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nada sobre combinar</text><path d=\"M310.0 40.0 L370.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"310.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">processo</text><text x=\"326.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">sem casos de combinação</text><text x=\"344.9\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">revisão sozinha, um dia depois</text><path d=\"M460.0 40.0 L520.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"460.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">pessoas</text><text x=\"476.4\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">novo em preços</text><path d=\"M155.0 260.0 L215.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"155.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">ferramentas</text><text x=\"171.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">sem verificação automática</text><path d=\"M310.0 260.0 L370.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"310.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">ambiente</text><text x=\"326.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">sessões de teste às quintas</text><path d=\"M460.0 260.0 L520.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"460.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">medição</text><text x=\"476.4\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">relatório esconde descontos</text></svg>", "caption": "Seis categorias, várias causas, um defeito. Tirar qualquer uma delas o teria parado mais cedo."}
```

Leia as espinhas e o defeito deixa de parecer um erro só:

- **requisitos**: as quatro primeiras frases da regra não diziam nada sobre combinar descontos; a quinta frase,
  *meia é o máximo*, só chegou depois do defeito;
- **processo**: ninguém escreveu casos de combinação no planejamento, e o Tomás revisou a mudança sozinho, um dia
  depois de escrita;
- **pessoas**: o Rafael nunca tinha trabalhado com preços, e a Joana supôs que "meia" obviamente não podia ser
  dividida de novo;
- **ferramentas**: não havia verificação automatizada nenhuma de preços, então nada rodava a combinação a cada
  mudança;
- **ambiente**: as sessões de teste eram às quintas, então a regra da quarta nunca foi exercitada junto com outro
  desconto;
- **medição**: o relatório noturno contava assentos por sessão mas não o desconto dado, então ingressos de R$ 9,00
  pareceriam uma venda qualquer.

Várias dessas causas precisaram se alinhar para o defeito chegar onde chegou, e tirar qualquer uma delas o teria
parado mais cedo. Essa é a forma normal de um defeito que escapou, e é para isso que serve o diagrama: **um time que
acha seis causas pode escolher as mais baratas de remover, em vez da primeira que alguém nomeou.**

## Conduzindo a sessão

Uma sessão de espinha de peixe leva uma hora. Muitas vezes quem testa a conduz, porque os hábitos de quem testa,
perguntar o que mais poderia explicar isso, são os hábitos de que ela precisa.

1. Escreva a declaração do problema na cabeça, a precisa, e leia em voz alta.
2. Desenhe as seis espinhas e percorra-as uma de cada vez, fazendo a pergunta de cada uma. Anote toda causa
   oferecida; discuta depois.
3. Para as causas que parecem importantes, pergunte *por quê* de novo e acrescente espinhas menores. É aqui que os
   cinco porquês cabem dentro do diagrama.
4. Marque as causas que o time concorda que contribuíram, e escolha ações para as mais baratas de remover que mais
   preveniriam.

O diagrama é o registro da conversa, e como todo registro neste curso vale guardá-lo onde a próxima análise consiga
achá-lo. Na segunda vez que uma espinha traz a mesma causa, a causa é a coisa a corrigir.
