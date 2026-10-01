---
title: O documento do survey, e o survey depois da instalação
version: 1
---

Um survey termina num documento escrito, e é nele que a próxima pessoa se apoia quando um usuário diz que
o Wi-Fi está ruim na sala 204. **A função dele é tornar o projeto verificável**: o que foi exigido, o que
foi medido, como, e onde o resultado ficou aquém. Um documento que é só um conjunto de imagens verdes não
responde a nada disso.

O que ele traz, e por que cada parte está ali:

| parte | por que está ali |
|---|---|
| os requisitos: aplicações, alvos, o cliente mais fraco | contra o que toda medição é julgada |
| método, datas e o estado do prédio | preditivo ou medido, e vazio ou ocupado |
| o adaptador ou aparelho, e a diferença dele para os clientes reais | um mapa lido 5 dB otimista é outro projeto |
| plantas com cada AP, a altura de instalação e a antena | como recolocá-lo depois que alguém o mudar |
| o plano de canais e de potência | a conta cocanal da aula 7, por escrito |
| heat maps: primário, secundário, SNR, sobreposição de canal | as visões da seção anterior, não só a primeira |
| o caminho percorrido | quais áreas foram medidas e quais foram pintadas |
| **exceções** | toda área abaixo do alvo, e por que isso foi aceito |

**As exceções são a página mais útil dele.** Uma escada abaixo de −75 dBm porque ninguém faz ligação ali
é uma decisão. A mesma escada sem uma linha no documento é um defeito esperando um chamado.

## Validar depois da instalação

Um projeto preditivo supôs materiais de parede; o prédio tem os de verdade. Os cabos terminam a um metro
de onde a planta dizia, um forro esconde um duto de metal, e uma sala de reunião acaba tendo vidro com
película. **Então o survey é refeito depois que os APs estão no ar**, passivo e ativo, contra os mesmos
requisitos. É o passo mais pulado, porque a rede já funciona para quem a instalou, de pé ao lado dos APs.

O que a validação confere, além dos mapas:

- um teste de roaming com os aparelhos que importam: uma chamada de voz levada pelo caminho mais
  movimentado, com cada queda anotada e localizada, já que um heat map não mostra um roaming;
- as medições ativas nos lugares que os requisitos citaram: o auditório cheio, o depósito no fim dos
  corredores;
- cada exceção, confirmada no lugar que o documento diz e não maior.

Onde algo fica aquém, a correção está no posicionamento, no canal ou na potência, e depois num novo
survey daquela área. **Aumentar a potência é a correção que não funciona**: ela amplia a célula do AP num
sentido só, o que o celular não consegue responder, e acrescenta sobreposição cocanal para todo mundo.

## E de novo, mais tarde

Um survey descreve o prédio no dia em que foi percorrido. **Paredes novas, um vizinho novo nos seus
canais, um depósito abastecido até o teto** mudam a resposta, e o gatilho sensato para um novo survey é
uma mudança no prédio, não uma reclamação. Os números do próprio documento são aquilo com que o novo
survey é comparado, e esse é mais um motivo para escrevê-los.
