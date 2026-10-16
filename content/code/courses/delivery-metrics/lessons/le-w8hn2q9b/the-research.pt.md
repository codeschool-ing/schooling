---
title: De onde vêm as quatro métricas
version: 1
---

Durante a maior parte da história do software, quem comandava times acreditava num dilema: **dava para ir rápido ou dava para ir com segurança, e mexer em um significava abrir mão do outro**. Lançar com frequência significava quebrar coisas com frequência; estabilidade significava controle de mudanças, trens de release e congelamentos. A crença era razoável, e nunca foi medida.

As métricas DORA vêm do trabalho que a mediu. A partir de 2014, uma pesquisa anual, o *State of DevOps Report*, perguntou a milhares de pessoas em organizações de tecnologia como seus times entregavam software e como suas organizações se saíam. Foi conduzida primeiro com a Puppet e depois pela DORA, DevOps Research and Assessment, a empresa que Nicole Forsgren, Jez Humble e Gene Kim fundaram. O livro deles de 2018, *Accelerate*, expôs o que quatro anos dessa pesquisa tinham encontrado, e o Google comprou a DORA no fim daquele ano e publica o relatório desde então.

## A descoberta

A surpresa estava na forma dos dados. **Os times não trocavam velocidade por estabilidade. Os times que entregavam com mais frequência eram também aqueles cujas mudanças falhavam menos, e que se recuperavam mais rápido quando falhavam.** Velocidade e estabilidade subiam juntas, e desciam juntas. A explicação que os pesquisadores deram é a que este curso vem construindo desde a aula 1: mudanças pequenas, entregues com frequência, são mais fáceis de testar, mais fáceis de entender quando quebram e mais fáceis de desfazer.

Para mostrar isso, eles precisavam de um jeito de medir a entrega que não dependesse do tipo de software nem do tamanho da empresa. Chegaram a quatro números, dois de velocidade e dois de estabilidade, e essas são as **quatro métricas-chave**:

| métrica | a pergunta que ela responde | tipo |
|---|---|---|
| **frequência de deploy** | com que frequência colocamos mudanças em produção? | velocidade |
| **lead time de mudanças** | quanto tempo de um commit até esse commit rodar em produção? | velocidade |
| **taxa de falha de mudanças** | que fração dos nossos deploys causa uma falha que precisa ser corrigida? | estabilidade |
| **tempo para restaurar** | quando um deploy falha, quanto tempo até o serviço voltar? | estabilidade |

## Elas continuam mudando, um pouco

A pesquisa é anual, e o vocabulário dela mudou ao longo dos anos. A confiabilidade, se um serviço cumpre as próprias metas, foi acrescentada como quinta medida em 2021. O relatório de 2023 renomeou o tempo para restaurar como **tempo de recuperação de deploy com falha**, para dizer com clareza que se trata de se recuperar de um deploy ruim e não de qualquer indisponibilidade. O relatório de 2024 acrescentou uma medida de **retrabalho**, deploys feitos para corrigir deploys anteriores. Cada relatório também agrupa os times em grupos de desempenho com limiares que mudam de ano para ano.

Este curso usa as quatro pelos nomes de longa data e não cita **nenhum limiar**, por um motivo que a aula 6 desenvolve: os limiares descrevem milhares de outras organizações, e um time aprende mais com a própria tendência do que com o seu lugar na tabela de outra pessoa. Quando você ler um relatório da DORA, confira o ano; os números nele são uma citação, não uma constante.
