---
title: Quando vale a pena
version: 1
---

A seção 06 mostrou que custo raramente é o motivo para uma equipe pequena rodar o próprio modelo. Os
motivos que se sustentam são sobre **coisas que uma API não pode vender a você**, e vale listá-los para
que uma proposta de auto-hospedar possa ser conferida contra eles.

| motivo | o que significa | o caso da ana |
|---|---|---|
| **os dados não podem sair** | uma lei, um contrato ou um cliente proíbe mandar o texto a terceiros | hoje não: uma API para empresas numa região escolhida atende aos termos dela |
| **controle do tempo** | o modelo não pode mudar até você decidir (aula 2 seção 06) | em parte: um identificador datado fixado dá a ela quase tudo isso |
| **sem rede** | o modelo precisa funcionar offline, num aparelho, numa fábrica, no mar | não |
| **volume** | carga constante na casa das centenas de milhares de requisições por dia | não: 400 por dia |
| **um modelo que ninguém vende** | um modelo com fine-tuning, ou um modelo aberto que nenhum host oferece | ainda não: a aula 1 seção 11 diz que fine-tuning vem por último |
| **latência ao lado dos dados** | o modelo precisa ficar no mesmo prédio de quem o chama | não |

Leia a tabela como um filtro, não como uma nota. **Uma linha que se aplica de verdade pode bastar**:
um hospital cujos prontuários não podem sair do prédio auto-hospeda seja qual for a conta, e o
trabalho da seção 07 passa a ser o preço de uma exigência, não de uma escolha.

## Dois caminhos do meio

Entre "uma API do autor" e "uma máquina nossa" ficam duas opções que guardam um pouco de cada:

- **Um modelo aberto num host** (aula 2 seção 05). Paga por token, nenhuma máquina para cuidar, e a
  liberdade de levar os mesmos pesos para outro host, ou para dentro de casa, depois. Os dados vão
  para o host.
- **Uma implantação dedicada na sua própria conta de nuvem.** As grandes nuvens alugam endpoints de
  modelo que rodam dentro da sua conta e região. A máquina é trabalho de outra pessoa; os dados ficam
  numa conta que você controla; a conta é por hora.

## O que a ana anota

Para a Lantern Books a decisão é curta, e ela a registra no projeto para poder revisitá-la quando uma
das premissas mudar:

1. **Não auto-hospedar**, porque nenhuma linha da tabela se aplica.
2. **Revisitar** se um contrato ou uma lei passar a proibir mandar e-mail para fora, se o volume
   passar de cem mil por dia, ou se a aula 5 descobrir que só um modelo com fine-tuning passa.
3. **Manter a opção aberta**: preferir candidatos com pesos disponíveis, em igualdade de condições,
   para que uma mudança futura para dentro de casa não signifique recomeçar a avaliação.
