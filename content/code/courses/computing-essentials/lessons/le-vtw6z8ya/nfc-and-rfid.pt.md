---
title: NFC, onde o alcance curto é a segurança
version: 1
---

O `NFC` — Near Field Communication — funciona a uns **quatro centímetros**, e isso não é uma
limitação que alguém esteja tentando vencer. É o objetivo.

Um pagamento que só funciona com o cartão encostando na maquininha não pode ser lido da mesa ao
lado, e quem impõe isso é a física, e não uma regra que alguém precisa implementar direito.

## Como um cartão sem bateria responde

O leitor emite um campo. Uma etiqueta passiva tem uma bobina dentro; o campo induz uma corrente
pequena nessa bobina, e a etiqueta usa essa corrente para se alimentar pelo tempo suficiente para
responder. **O leitor está energizando a coisa que ele lê.**

É por isso que o alcance é curto — o campo despenca muito rápido — e por isso que um cartão
funciona depois de dez anos na carteira sem nada para carregar.

O `RFID` é a mesma ideia com alcance maior e menos inteligência: as etiquetas antifurto de uma
loja, o rótulo de um palete, o chip de um animal. O NFC é um subconjunto dele, de perto, com
comunicação de mão dupla.

## Para que serve

| | o que acontece |
|---|---|
| **pagamento por aproximação** | o cartão ou o celular assina um número descartável, não o seu |
| **cartões de transporte** | um saldo guardado, ou uma ficha que a catraca confere |
| **pareamento** | encostar numa caixa entrega os dados de Bluetooth e você pula os menus |
| **etiquetas e adesivos** | um endereço ou uma instrução curta, legíveis por qualquer celular |
| **acesso a prédios** | um crachá com um identificador que a porta consulta |

A linha do pagamento é a importante. **Um pagamento por aproximação não manda o número do seu
cartão.** O chip produz um criptograma — um valor de uso único derivado de uma chave que nunca sai
do cartão — de modo que uma transação capturada não pode ser repetida e o comerciante nunca fica
com nada reutilizável.

Isso é genuinamente mais privado que entregar a um garçom um cartão com o número impresso nele.

## Os riscos honestos, que são pequenos e não são zero

- **Ataques de retransmissão** são reais e difíceis: dois cúmplices, um ao lado do seu bolso e um
  na maquininha, passando o sinal adiante em tempo real. Os limites dos bancos para aproximação
  existem por causa disso.
- **Ler uma etiqueta sem querer** — um adesivo num cartaz que abre uma página. Seu celular
  pergunta antes, e essa pergunta é a defesa.
- **Clonar um crachá de prédio** costuma ser fácil, porque muitos sistemas de acesso ainda usam
  um tipo antigo de etiqueta que só anuncia um número. Isso é propriedade do sistema do prédio, e
  não do NFC.

**Uma carteira que bloqueia rádio é vendida para o primeiro risco.** Ela funciona, e o risco que
ela trata já é limitado pelo valor que o banco permite. Compre uma se isso te acalma; não é ela
que está entre você e uma fraude.

## Aonde ele não vai

O NFC não vai transferir um arquivo de tamanho algum — `424 kb/s`, a quatro centímetros, com duas
coisas encostadas. Ele entrega os dados para um rádio mais rápido assumir, que é exatamente o
serviço em que ele é bom, e a razão de encostar dois celulares começar uma transferência por
Bluetooth ou Wi-Fi em vez de fazer uma.
