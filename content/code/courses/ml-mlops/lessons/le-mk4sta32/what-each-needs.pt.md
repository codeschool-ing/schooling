---
title: O que cada tarefa pede da plataforma
version: 1
---

Os quatro programas desta lição se parecem: ler a loja, montar uma tabela, ajustar, imprimir.
**Colocados em produção, eles pedem quatro coisas diferentes à plataforma**, e as diferenças são as
que um engenheiro de dados precisa planejar antes que alguém treine qualquer coisa.

| | afastamento (classificação) | gasto (regressão) | tipos de leitor (agrupamento) | próximo título (recomendação) |
| --- | --- | --- | --- | --- |
| **quando a resposta certa fica conhecida** | 90 dias depois da predição | 90 dias depois | nunca: não há resposta certa | quando o membro compra de novo, se comprar |
| **qual a chave de uma resposta guardada** | membro e corte | membro e corte | membro, corte e a rodada que fez os grupos | membro, título e corte |
| **quantas respostas por noite** | uma por membro ativo: 3.130 em 30 de novembro | o mesmo | uma por membro com cinco livros | até oitenta por membro |
| **quão novos os atributos precisam ser** | um dia de idade serve | um dia de idade serve | um mês de idade serve | a última compra importa, então minutos |

Cada linha é uma decisão que as lições seguintes tornam concreta.

**Quando a resposta certa fica conhecida** decide como um modelo pode ser testado antes de ir ao ar
(lição 3) e como a qualidade dele é acompanhada depois (lição 9). Para o afastamento, ninguém sabe
se uma predição feita hoje acertou até maio.

**Qual a chave de uma resposta guardada** é a diferença entre uma tabela que você consegue juntar e
uma que não consegue. Uma nota sem o corte ao lado não pode ser comparada com o desfecho, e um id de
grupo sem a rodada ao lado não pode ser comparado com nada (lições 5 e 7).

**Quantas respostas** decide se elas são calculadas de madrugada para todos ou sob pedido para um
(lição 8).

**Quão novos os atributos precisam ser** decide se a plataforma precisa de uma tabela noturna ou de
um armazenamento que responde em milissegundos, que é para o que serve a feature store da lição 6. O
recomendador é o caso em que uma compra feita às 10h02 deveria mudar o que o site mostra às 10h05.

Nada disso está no algoritmo. Tudo isso está nos dados.
