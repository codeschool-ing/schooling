---
title: Três opções, e quem escolhe
version: 1
---

As arquitetas caem num de dois hábitos quando qualidade, prazo e custo puxam para lados diferentes.
Um é decidir quão boa a engenharia tem de ser e defender isso contra o negócio. O outro é aceitar
qualquer data que chegue e absorver a diferença em silêncio. **O negócio decide a troca entre
qualidade, prazo e custo. A arquiteta torna as consequências de cada escolha explícitas o bastante
para que essa decisão seja informada, e escreve o que foi combinado.** Nenhum dos dois hábitos faz
nenhuma das duas metades.

## Por que três opções

Uma opção é um pedido de aprovação: quem decide pode dizer sim ou não, e não aprende nada sobre o
que mais era possível. Duas opções convidam a "dividir a diferença", o que muitas vezes é pior que
qualquer uma delas. **Três opções, uma delas a mais barata que ainda é aceitável, dão a quem decide
uma escolha de verdade e mostram que a arquiteta olhou.** A aula 14 acrescenta "não fazer nada" à
comparação como uma quarta alternativa que vale precificar. Para o leiaute do CT-e, não fazer nada
não estava disponível, porque depois da data todo CT-e no leiaute antigo é recusado, e dizer isso com
clareza fez parte da apresentação.

## As três da Carreto

O escopo para a data ficou definido na seção anterior. O que continuava em aberto era como construí-lo,
e em especial se valia reestruturar o gerador de CT-e antes. O financeiro da Carreto planeja com um
custo carregado de R$ 6.500 por semana-engenheiro, número que esta aula usa e nenhuma outra. Renata e
Bruno chegaram a três opções.

| | A: remendar o gerador | B: reconstruir com leiautes versionados | C: remendar agora, reconstruir no próximo trimestre |
|---|---|---|---|
| trabalho antes da data | 12 semanas-engenheiro: 3 pessoas, 4 semanas | 27 semanas-engenheiro: 3 pessoas, 9 semanas | 12 semanas-engenheiro: 3 pessoas, 4 semanas |
| trabalho depois | nada planejado | nenhum | 15 semanas-engenheiro no próximo trimestre |
| custo | R$ 78.000 | R$ 175.500 | R$ 78.000 agora e R$ 97.500 no próximo trimestre |
| folga antes da data | 6 semanas | 1 semana | 6 semanas |
| risco principal | nenhum no dia; toda mudança de leiaute depois custa cerca do dobro | código novo chega à produção uma semana antes de uma data que ninguém move | nenhum no dia; um trimestre carregando o remendo |
| o que deixa | condicionais de dois leiautes num gerador só | um gerador em que um leiaute novo é um mapeamento novo | o mesmo que B, um trimestre depois |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma linha do tempo em semanas, com uma linha tracejada na data regulatória, semana 10, e o começo do próximo trimestre depois dela. Opção A, remendar: uma barra da semana 0 à semana 4, deixando 6 semanas de folga. Opção B, reconstruir antes: uma barra da semana 0 à semana 9, deixando 1 semana. Opção C, remendar e refazer depois: uma barra da semana 0 à semana 4, deixando 6 semanas de folga, e uma barra tracejada para a reestruturação no começo do próximo trimestre.\"><defs><marker id=\"options-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hoje</text><text x=\"380\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a data, semana 10</text><text x=\"446\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">próximo trimestre</text><path d=\"M380 34 L380 220\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><path d=\"M440 56 L440 220\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><text x=\"14\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">A  remendar</text><rect x=\"180\" y=\"70\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M264 82 L376 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"320.0\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6 semanas de folga</text><text x=\"14\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">B  reconstruir antes</text><rect x=\"180\" y=\"122\" width=\"180\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"388\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1 semana</text><text x=\"14\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">C  remendar, refazer depois</text><rect x=\"180\" y=\"174\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M264 186 L376 186\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"320.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6 semanas de folga</text><rect x=\"442\" y=\"174\" width=\"100\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"550\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reestruturação</text></svg>", "caption": "As mesmas três opções contra o calendário. B e C custam o mesmo no total; o que muda é onde fica o trabalho arriscado em relação à única data que não se move."}
```

**C custa exatamente o mesmo que B, R$ 175.500 no total.** Não compra economia. Compra tempo: a
reestruturação arriscada sai de perto da única data que não pode escorregar, e em troca a Carreto
carrega um gerador remendado por um trimestre. É esse tipo de troca que uma tabela assim existe para
mostrar, porque "B é a solução correta" e "C é a segura" são as duas verdadeiras e nenhuma diz quanto
a escolha custa.

## Apresentando

Renata levou a tabela a Tomás Viana, Helena Prado e Sílvio Matos numa reunião de trinta minutos. Não
estava lá para ganhar a B, que os engenheiros preferiam. A nota de uma página dela dizia cinco coisas,
nesta ordem: a data e por que ela não se move; o escopo tratado à mão por algumas semanas; as três
opções; a recomendação dela, C, com o motivo; e **o que cada opção tirava do roadmap de Helena**, que
são nove semanas dos três engenheiros do CT-e na B e quatro semanas na A ou na C. Essa última linha
era a que Helena precisava, porque as mesmas três pessoas iam começar o trabalho das cargas de
retorno.

Sílvio fez a pergunta certa: as quinze semanas-engenheiro iam mesmo acontecer no próximo trimestre,
ou seriam engolidas pela próxima funcionalidade? A resposta de Renata foi uma condição. "Isso entra
no roadmap agora, com dono e data, ou eu recomendo a B." Escolheram a C, com a reestruturação escrita
no plano de Payments para o trimestre seguinte.

**A arquiteta recomenda, com motivos; quem é dono do tempo e do dinheiro decide.** Tornar as
consequências explícitas quis dizer pôr cada opção nos termos de quem decide: semanas de roadmap,
reais e a chance de um caminhão não sair. O ofício dessa conversa é ensinado em outro lugar, na aula 4
de `architect-communication`, sobre traduzir risco técnico em risco de negócio, e na aula 13 dele,
sobre negociar prazo, escopo, qualidade e dívida.

## Escrevendo a dívida

A opção C é dívida deliberada e prudente, e só continua prudente se for registrada. Renata escreveu um
ADR para a decisão (aula 5) e acrescentou uma entrada ao registro de dívidas da Carreto:

> **O que tomamos emprestado:** o novo leiaute do CT-e é suportado com condicionais acrescentadas ao
> gerador atual, não com um mapeamento versionado.
>
> **Por quê:** uma data regulatória a dez semanas; reestruturar antes deixava uma semana de folga.
>
> **Juros:** até o pagamento, qualquer mudança na geração do CT-e leva cerca do dobro do tempo. Uma
> segunda mudança de leiaute antes do pagamento levaria cerca de seis semanas em vez de três.
>
> **Pagamento:** extrair um mapeamento de leiaute versionado, 15 semanas-engenheiro, dono Bruno
> Farias, no plano do próximo trimestre.
>
> **Revisitar se:** a autoridade fiscal anunciar outra versão de leiaute antes do pagamento. Aí, pagar
> primeiro.

A entrada dá à dívida um dono, um custo e uma data, que é o que separa um empréstimo deliberado de uma
bagunça. A linha "revisitar se" importa tanto quanto o resto: ela nomeia o evento que faria os juros
saltarem, para que ninguém precise lembrar o raciocínio para agir. Precificar a dívida direito, como
juros pagos sprint a sprint, é a aula 5 de `tech-strategy`.

O novo leiaute entrou em produção com cinco semanas de sobra, uma a menos que o planejado, e a
reestruturação saiu na sexta semana do trimestre seguinte. **Todo número desta seção é um ponto
único**, 4 semanas, 9 semanas, 15 semanas-engenheiro, e estimativas reais não são pontos. A aula 14 os
transforma em faixas e mostra o que isso muda na folga da tabela acima.
