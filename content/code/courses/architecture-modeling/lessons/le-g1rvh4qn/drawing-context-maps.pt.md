---
title: Desenhando um mapa de contextos
version: 1
---

**Um mapa de contextos desenha os contextos delimitados de um domínio e, para cada par que se
integra, qual lado é upstream e como os dois se relacionam.** O curso `design-patterns` explicou o
que cada relação significa na aula 11; esta seção trata de colocá-las numa página de modo que alguém
que não estava na sessão de modelagem consiga lê-las.

## Não é um diagrama de contêineres

O primeiro erro é tratar o mapa como mais um desenho dos serviços. **Um contexto é um modelo e a
linguagem que vem com ele, não uma coisa implantável.** Um contexto pode ser implementado por três
contêineres, e um contêiner legado pode guardar dois contextos emaranhados. As linhas de um mapa de
contextos não são chamadas: são **dependências entre modelos e entre os times donos deles**. A
pergunta que um mapa responde é *quando este modelo muda, quem tem de se adaptar?*

É por isso que um mapa de contextos é desenhado com outro vocabulário, e por isso vale a pena
desenhá-lo mesmo quando o diagrama de contêineres já existe.

## As convenções

Não existe padrão da OMG para mapas de contextos, mas as convenções do livro de Eric Evans e da
prática de DDD que veio depois são amplamente compartilhadas:

- cada **contexto** é uma caixa ou uma forma arredondada com o nome do contexto, muitas vezes com o
  time dono;
- cada **relação** é uma linha entre dois contextos, com um **U** na ponta upstream e um **D** na
  ponta downstream; as mudanças fluem de U para D;
- o **padrão** é escrito na ponta a que se aplica, em geral abreviado:

| na ponta | abreviação | significado |
| --- | --- | --- |
| upstream | **OHS** | serviço de host aberto: um protocolo documentado para todos os clientes |
| upstream | **PL** | linguagem publicada: um formato compartilhado e documentado, muitas vezes junto com OHS |
| downstream | **ACL** | camada anticorrupção: o downstream traduz o modelo do upstream |
| downstream | **CF** | conformista: o downstream adota o modelo do upstream como ele é |
| ambas | **SK** | núcleo compartilhado: um pedaço pequeno de modelo que pertence aos dois |
| ambas | **P** | parceria: os dois planejam juntos e dão certo ou errado juntos |
| o par | **C/S** | cliente e fornecedor: o upstream planeja levando em conta as necessidades do downstream |

Alguns times desenham a ACL como uma caixinha do lado downstream da linha, como fez
`design-patterns`. As duas formas servem; a legenda diz qual.

## Ler a direção sem setas

Um mapa muitas vezes não tem ponta de seta nenhuma, porque **o U e o D já dizem a direção**, e uma
ponta de seta convidaria à leitura *chama*. O gateway de pagamento é upstream da Carcará mesmo que a
Carcará o chame: o modelo do gateway decide, e a Carcará se adapta. Um webhook do gateway para a
Carcará não muda isso. Upstream diz respeito a qual modelo prevalece, não a quem abre a conexão.

## O que torna um mapa útil

- **Toda linha nomeia um padrão.** Uma linha sem padrão diz apenas *estes conversam*, o que o
  diagrama de contêineres já dizia.
- **A relação que os times têm de fato, não a que gostariam de ter.** Se Preços ignora os pedidos de
  Vendas, a relação é conformista, diga o organograma o que disser sobre clientes. O mapa é antes de
  tudo um diagnóstico.
- **O time dono em cada contexto.** Metade do valor do mapa é saber com quem falar.
