---
title: De onde vêm os dados, e o que combinar antes
version: 1
---

Os quatro números do time de Billing vieram de dois arquivos limpos. Os de um time real vêm de três ou quatro sistemas que nunca foram projetados para concordar, e a maior parte do trabalho de medir DORA é decidir, uma vez e por escrito, como esses sistemas serão lidos.

## Três fontes

| métrica | de onde vem |
|---|---|
| frequência de deploy | o pipeline de deploy: toda execução que chegou à produção e terminou |
| lead time de mudanças | o sistema de controle de versão para o horário do commit, o pipeline para o horário do deploy |
| taxa de falha de mudanças | o pipeline para os deploys; o sistema de incidentes, ou os registros de rollback, para saber quais falharam |
| tempo para restaurar | o sistema de incidentes, ou o tempo entre um deploy com falha e o que o corrigiu ou reverteu |

**Leia os sistemas; não faça pesquisa com as pessoas.** A pesquisa original usou questionários porque comparava milhares de organizações que não podiam compartilhar seus pipelines. Um único time tem o próprio pipeline, e perguntar às pessoas "com que frequência fazemos deploy?" quando uma máquina registrou cada deploy é pedir uma estimativa de um fato. Existem ferramentas que calculam as quatro a partir de um pipeline e de um sistema de tickets, open source e comerciais; o trabalho abaixo tem de ser feito qualquer que seja a que você use.

## Decida antes de olhar

Cada uma das quatro tem uma escolha dentro dela, como a seção anterior mostrou. Faça essas escolhas **antes** de olhar os números, escreva-as num lugar só, e mude-as apenas com uma nota dizendo quando. As decisões que vale registrar:

- **O que é um deploy?** Por serviço ou por release; se mudanças de configuração e migrações de banco de dados contam.
- **Onde começa o lead time?** No primeiro commit, na abertura do pull request ou no merge.
- **O que é uma falha?** Um rollback, um hotfix, qualquer incidente causado por uma mudança, ou só incidentes acima de certa severidade (aula 13).
- **Quando a restauração começa e termina?** A partir do deploy ou da detecção; até os usuários não serem mais afetados, não até a causa ser corrigida.

Um time que decide isso depois de ver os números vai, sem ninguém pretender, decidir na direção que parece melhor. Isso não é desonestidade; é como as pessoas leem regras ambíguas. A aula 7 é sobre o que essa deriva faz com uma métrica ao longo de alguns trimestres.

## O atalho do merge como commit

Este curso mede o lead time de mudanças a partir do merge, porque os arquivos do time de Billing não têm nada anterior. Isso deixa de fora o tempo que uma mudança passa em revisão, que a aula 2 mostrou ser a maior fila em julho. **Um lead time de mudanças medido a partir do merge não consegue enxergar um gargalo de revisão.** Se o seu pipeline permite medir a partir do primeiro commit, meça; se não permite, diga qual você mediu toda vez que citar o número.
