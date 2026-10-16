---
title: O que a arquitetura decide
version: 1
---

A imagem comum é que arquitetura é um diagrama: caixas, setas, uma nuvem no canto, desenhado no
começo de um projeto e emoldurado na parede. **Arquitetura é o conjunto de decisões sobre um sistema
que ficam caras de mudar depois que o sistema existe**, e o diagrama é só uma das formas de anotar
algumas delas.

O teste é o custo de voltar atrás. Renomear uma variável custa um minuto, então não é uma decisão
de arquitetura. Escolher um banco de dados para o sistema todo, dividir o código em serviços que
conversam pela rede, ou decidir que um pedido está confirmado antes de o pagamento ser compensado
custam semanas para desfazer, porque a essa altura outro código, outras equipes e dados reais
dependem deles. São essas as decisões deste curso.

## Para que servem as decisões

Uma decisão nunca é certa em geral. Ela é certa para um conjunto de **atributos de qualidade**, as
propriedades que um sistema precisa ter além de fazer o seu trabalho, e eles puxam uns contra os
outros:

| atributo | a pergunta que ele faz |
| --- | --- |
| disponibilidade | em que fração do tempo ele responde? |
| latência | quanto demora uma requisição? |
| vazão | quantas requisições ele aguenta por segundo? |
| consistência | todo mundo vê o mesmo dado no mesmo instante? |
| modificabilidade | quanto demora uma mudança, e quantas pessoas precisam concordar com ela? |
| operabilidade | quantas coisas precisam ser vigiadas, implantadas e consertadas às três da manhã? |
| custo | quanto custa manter, em máquinas e em pessoas? |

Quase toda aula deste curso é uma troca entre duas linhas dessa tabela. Dividir um programa em
serviços compra modificabilidade para equipes separadas e paga em latência e operabilidade
(aula 2). Replicar dados compra disponibilidade e paga em consistência (aulas 8 e 9). Um retry
compra disponibilidade e pode pagar em vazão, às vezes toda ela (aula 11).

## O formato do curso

| aulas | assunto |
| --- | --- |
| 1 a 4 | o formato de um sistema: monólito, serviços, SOA, serverless, malha, e os doze fatores |
| 5 a 7 | como os serviços conversam: chamadas síncronas, filas e logs, e o que "entregue" quer dizer |
| 8 a 10 | o dado entre eles: CAP, consistência eventual, replicação e sharding |
| 11 e 12 | ficar de pé quando uma parte falha: retries, circuit breakers, bulkheads, back pressure |
| 13 a 16 | padrões dos catálogos de projeto em nuvem: CQRS, event sourcing, saga, estrangulador, sidecar, e os antipadrões |
| 17 a 19 | busca, tempo real, descoberta e o gateway |
| 20 | anotar as decisões para que possam ser defendidas |

**Um exemplo atravessa tudo: a Quitanda**, uma mercearia que vende tomate, café e queijo para
entrega. Ela começa nesta aula como um programa só, e cada aula seguinte constrói a parte dela de
que precisa, na sua própria máquina, a partir de arquivos que a aula mostra inteiros.

`scale`, o curso depois deste na trilha `backend`, leva os mesmos padrões aos limites: medir carga,
observar um sistema através de serviços, e planejar capacidade. Este curso dá nome a eles e mostra
cada um funcionando.
