---
title: A camada anticorrupção
version: 1
---

No momento em que o serviço novo de qualidade recebe a primeira cópia de um arquivo do laboratório,
ele tem uma escolha a fazer sobre palavras. A Coleta chama uma fazenda de `0413275`, escreve a data
como `1261023` e guarda 1.234,5 litros como `123450`. O serviço novo pode aceitar isso como vem, ou
pode dizer o que aquilo significa nos próprios termos e traduzir na fronteira. **A camada
anticorrupção é a decisão de traduzir, tomada uma vez e mantida num lugar só, para que o sistema
novo não seja construído no formato do antigo.**

Eric Evans deu o nome em *Domain-Driven Design* (2003), na parte do livro sobre como modelos
separados se relacionam. A descrição dele continua a mais clara: uma camada isolante que oferece ao
sistema novo a funcionalidade do sistema antigo nos termos do próprio sistema novo, conversa com o
sistema antigo pelas interfaces que ele já tem e traduz nas duas direções. O Evans também diz do que
ela costuma ser feita: fachadas que simplificam a interface antiga, adaptadores que encaixam um
protocolo no outro e tradutores que transformam os objetos de um modelo nos do outro.

## Por que o caminho fácil corrompe

A ideia comum, e a que um prazo apertado incentiva, é que o sistema novo deveria simplesmente adotar
os códigos e formatos do legado. Todo mundo na Serra Alta conhece os códigos das fazendas, todo
relatório usa esses códigos, e mantê-los significa não ter tradução para escrever. Parece reduzir
risco.

Com o tempo, faz o contrário. Um sistema novo que guarda o código de fazenda da Coleta como chave,
recebe datas no formato da Coleta e acha que uma coleta pertence ao dia em que o caminhão saiu da
fábrica **copiou o modelo da Coleta para um código que deveria durar vinte anos a mais do que ela.**
Cada funcionalidade nova vai ser desenhada em volta dessas escolhas, e quando a Coleta for desligada
elas ficam, agora sem ninguém que lembre o porquê. O legado foi migrado no nome e mantido na forma.

Parte do que precisa ser traduzido é formato, o que é fácil. Parte é significado, o que não é.

| conceito | na Coleta | no modelo novo |
|---|---|---|
| a identidade de uma fazenda | `0413275`: seis dígitos e um dígito verificador calculado em módulo 11 | um identificador opaco; o código da Coleta fica como referência externa |
| uma data | `1261023`: a forma `CYYMMDD` do IBM i, em que o 1 inicial indica os anos 2000 | uma data ISO, `2026-10-23` |
| um volume de leite | `123450`: um número inteiro de centésimos de litro | litros em decimal, `1234.50` |
| contagem de células somáticas | `350`: milhares de células por mililitro | células por mililitro, `350000` |
| o dia de uma coleta | a data em que a rota saiu da fábrica | o momento em que o leite foi bombeado, e a rota em que estava |
| uma fazenda suspensa | status `S` | dois fatos diferentes: suspensa por qualidade, ou com documento faltando |

As quatro primeiras linhas são aritmética. As duas últimas são onde os modelos discordam. A Coleta
data todas as coletas de uma rota pela saída da rota, então o leite bombeado às 00:40 do dia 1º por
um caminhão que saiu às 22:00 do dia 31 pertence ao mês anterior. O serviço novo de coleta registra
quando o leite foi bombeado, porque é isso que as regras de qualidade e o laboratório precisam. E o
`S` significa duas coisas desde 2014, quando fazendas com documento vencido precisaram de um status
e a Coleta não tinha letra sobrando. O único jeito de separar as duas é um campo de observação em
texto livre, que os funcionários preenchem por hábito, quase sempre do mesmo jeito.

## O que a camada faz, nas duas direções

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-acl\" aria-label=\"Três colunas. À esquerda, o contexto novo: o serviço de coleta e o serviço de qualidade, que falam o modelo novo. No meio, a camada anticorrupção, do time novo, com um tradutor de entrada e um tradutor de saída. À direita, a Coleta, com o seu journal e o carregador de laboratório das 22:00. Na entrada, as linhas do journal viajam por captura de mudanças até o tradutor de entrada, que transforma 0413275 numa fazenda com id opaco, 1261023 em 2026-10-23, 123450 em 1234,50 litros, e o status S mais uma observação em suspensa por qualidade ou documento pendente, antes de chegarem aos serviços novos. Na saída, os resultados de laboratório, cujo dono é o serviço de qualidade, vão ao tradutor de saída, que os grava como um arquivo no layout antigo do laboratório, em milhares de células por mililitro, para o carregador da Coleta. O que a camada não consegue classificar vai para uma fila, para uma pessoa olhar.\"><defs><marker id=\"l13-acl-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-acl-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"100.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">contexto novo</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">camada anticorrupção</text><text x=\"625.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><rect x=\"230.0\" y=\"36.0\" width=\"260.0\" height=\"262.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"20.0\" y=\"75.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviço de coleta</text><rect x=\"20.0\" y=\"205.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviço de qualidade</text><rect x=\"550.0\" y=\"75.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">journal</text><rect x=\"550.0\" y=\"205.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carregador das 22:00</text><rect x=\"242.0\" y=\"49.0\" width=\"236.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tradutor de entrada</text><text x=\"252.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0413275</text><text x=\"338.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fazenda, id opaco</text><text x=\"252.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1261023</text><text x=\"338.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026-10-23</text><text x=\"252.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">123450</text><text x=\"338.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1234,50 litros</text><text x=\"252.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">S + observação</text><text x=\"338.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">qualidade ou documento</text><path d=\"M550.0 95.0 L480.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-amber)\"></path><text x=\"515.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CDC</text><path d=\"M242.0 95.0 L182.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><rect x=\"260.0\" y=\"200.0\" width=\"200.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tradutor de saída</text><text x=\"360.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">células por mL ÷ 1000, layout antigo</text><path d=\"M182.0 225.0 L258.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><path d=\"M462.0 225.0 L548.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><text x=\"520.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivo</text><rect x=\"275.0\" y=\"154.0\" width=\"170.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"360.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fila para uma pessoa</text><path d=\"M360.0 141.0 L360.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-amber)\"></path><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">os formatos do legado aparecem aqui e em nenhum outro lugar</text></svg>", "caption": "A camada é do lado novo e traduz nas duas direções: o que a Coleta sabe vira fato no modelo novo, e o que o lado novo controla volta escrito nas formas da própria Coleta.", "same": ["Coleta", "journal"]}
```

A figura mostra as duas direções em que a camada trabalha na Serra Alta. Na entrada, ela pega o que
a Coleta sabe (as linhas de journal que o CDC publica, as respostas dos fluxos do barramento) e
transforma nos conceitos do modelo novo. Uma linha cujo status mudou para `S` com uma observação que
menciona um documento vira "documento pendente" para aquela fazenda; a mesma mudança com qualquer
outra observação vira "suspensa por qualidade". Na saída, ela pega o que o sistema novo controla e
grava na forma que a Coleta espera. O serviço novo de qualidade é o dono dos resultados de
laboratório, e toda noite a camada os grava como um arquivo no layout antigo do laboratório, em
milhares de células por mililitro, para o programa das 22:00 da Coleta carregar. O cálculo de
pagamento que ainda roda na Coleta encontra os resultados exatamente onde sempre encontrou.

**A camada pertence ao time do sistema novo e fica do lado do sistema novo.** Ninguém pede que a
Coleta mude, e é esse o ponto: o dono dela está indo embora e toda mudança nela é um risco. O lado
novo paga pela tradução porque é ele que quer continuar limpo.

## Quatro regras que a mantêm honesta

**É o único lugar onde aparecem as palavras do legado.** Se `CYYMMDD` ou as letras de status
aparecerem no código do próprio serviço de coleta, a camada vazou. O time da Joana garante isso do
jeito barato: os formatos do legado são interpretados num módulo só, e um teste falha se qualquer
coisa fora desse módulo fizer referência a eles.

**Cada regra é um teste escrito com valores reais.** O dígito verificador em módulo 11, a data nos
anos 1900 e nos anos 2000, a rota que cruza a meia-noite no fim de um mês, o `S` com cada tipo de
observação: cada um é um teste cuja entrada foi copiada da Coleta. Esses testes são a documentação
mais valiosa da Coleta que vai existir, porque são as regras escritas numa forma que falha quando
deixa de ser verdade.

**Ela recusa o que não entende.** Um código de fazenda cujo dígito verificador não confere, uma letra
de status que ninguém viu, uma observação que a regra não consegue classificar: a camada põe o
registro numa fila para uma pessoa olhar e avisa, em vez de adivinhar. Uma camada que adivinhasse
poria um fato errado no sistema novo com o formato certinho, o que é pior do que um erro visível.

**Ela é temporária, e partes dela não são.** Quando a Coleta sair, o código que lê os journals dela e
grava nas tabelas dela sai junto. O código de fazenda da Coleta sobrevive como atributo da fazenda,
porque os produtores falam esse número ao telefone e trinta anos de papéis o carregam, mas é um
atributo e nunca uma chave.

## O Sebastião e os testes

As regras de tradução vêm, no fim das contas, de uma fonte só. O manual é velho, os funcionários
sabem o que veem na tela, e o Sebastião sabe o que o código faz e por quê. **A camada anticorrupção é
onde o conhecimento dele vira algo que não se aposenta.** O plano da Joana dá a ele uma tarde por
semana com o time pelo resto do tempo dele na Serra Alta, e o resultado de cada tarde é um conjunto
de testes: uma regra que ele explica, escrita como uma entrada e a resposta que a Coleta dá.

Foi numa dessas tardes que surgiu a virada do mês. Ninguém no time novo tinha pensado numa rota que
sai antes da meia-noite do último dia do mês. O Sebastião tinha escrito a regra em 1997, depois da
reclamação de um produtor, e ela não estava em documento nenhum. O teste entrou no mesmo dia. Se o
sistema novo deve seguir a regra da Coleta ou a dele é uma decisão de negócio, e a próxima seção
mostra decisões desse tipo sendo tomadas com números na frente de quem decide.
