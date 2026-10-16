---
title: Aprisionamento é custo de troca
version: 1
---

"Devemos evitar aprisionamento a fornecedor" aparece em quase toda revisão de arquitetura, e nunca
ninguém discorda. **Esse é o sinal de que é um slogan.** Soa como prudência e não decide nada, por
dois motivos. Não dá para segui-lo: toda escolha prende você a alguma coisa — uma linguagem, um
banco, um provedor de nuvem e, como a aula 8 mostrou, também um motor de código aberto. E ele não
diz quanto vale evitar o aprisionamento, então não consegue dizer a um time quando parar de pagar
por isso.

## Uma definição que dá para usar

**Aprisionamento é o custo de trocar.** Estar preso a um fornecedor quer dizer que sair custaria
alguma coisa — horas de reescrita, dados a migrar, um contrato a esperar terminar, pessoas a
retreinar. Quanto mais custaria, mais preso você está. Dito assim, o aprisionamento deixa de ser uma
propriedade que um desenho tem ou não tem e vira uma quantidade, que pode ser estimada em horas
como qualquer outro trabalho.

A aula 9 já encontrou esse custo, com outro nome: a linha de saída de um custo total de propriedade
é o custo de troca da opção que você está prestes a escolher. Esta aula pega o mesmo número e
pergunta o que fazer com ele.

## Os dois aprisionamentos da Coreto

O Davi tem dois na lista, apontados por dois times diferentes.

**O banco de documentos gerenciado.** O time de Catálogo guarda o conteúdo da página de cada evento
— descrições, escalações, mídia, o desenho da casa — num banco de documentos operado pelo provedor
de nuvem da Coreto. Ele é rápido, não exige operação e tem uma interface de consulta própria, que o
código do Catálogo chama diretamente em muitos lugares. Sair dele significaria reescrever cada uma
dessas consultas para outro banco, migrar os documentos, testar que nada mudou para os compradores
e rodar os dois durante a mudança. A estimativa do time de Catálogo é de **1.400 horas, R$ 210.000**
a R$ 150 por hora.

**O gateway de pagamento.** Todo pagamento com cartão no checkout passa por um gateway, e o código
de Checkout e de Pagamentos chama a API dele diretamente, do fluxo de compra aos estornos. Sair dele
significaria substituir essas chamadas, recertificar os fluxos de pagamento e migrar os cartões
guardados que deixam o comprador recorrente pagar com um toque. Mateus Araújo, tech lead do
Checkout, estima **900 horas, R$ 135.000**.

O banco é o aprisionamento mais profundo dos dois: R$ 210.000 contra R$ 135.000. A maioria dos times
pararia aí e se preocuparia com o número maior. A próxima seção mostra por que esse é o lugar errado
para parar.

## Quatro tipos de aprisionamento

Um custo de troca tem partes, e nomeá-las é como uma estimativa evita esquecer uma delas. Quatro
cobrem a maioria dos casos:

| tipo | o que encarece a saída | na Coreto |
|---|---|---|
| dados | volume, um formato que só o fornecedor lê, uma exportação lenta ou parcial | os documentos dos eventos; os cartões guardados no gateway |
| interface | código que fala a API ou a linguagem de consulta do fornecedor, em muitos lugares | as consultas do Catálogo; as chamadas ao gateway pelo checkout |
| contrato | aviso prévio, prazo mínimo, multa por sair antes | o prazo do contrato do gateway |
| conhecimento | pessoas cujo saber é específico deste fornecedor | os poucos engenheiros que conhecem o modelo de consulta do banco |

**O tipo interface é o que o time mais controla**, porque é decidido no código, cada vez que alguém
escreve uma chamada. Dados e contrato são decididos uma vez, na assinatura; o conhecimento se acumula
sozinho.

## Quanto custa o slogan

Um time que leva "nada de aprisionamento" ao pé da letra paga por portabilidade em toda parte: uma
camada de abstração sobre o banco, um invólucro sobre cada serviço de nuvem, uma recusa de qualquer
coisa proprietária por mais útil que seja. Cada uma custa horas, toda vez, por trocas que na maioria
dos casos nunca acontecem. E o time não consegue dizer quais valeram a pena, porque nunca pôs um
número nos aprisionamentos que estava evitando.

Com um custo de troca escrito, a pergunta passa a ter resposta: **evitar este aprisionamento sai
mais barato do que o aprisionamento?** Isso exige mais dois números — quão provável é a troca, e
quanto custaria evitar o aprisionamento — e eles são as próximas duas seções.
