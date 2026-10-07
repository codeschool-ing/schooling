---
title: STRIDE por interação
version: 1
---

O **STRIDE por interação** aplica as letras a um fluxo junto com os dois elementos das pontas, e só
a fluxos que cruzam uma fronteira de confiança. É a variante por trás da Threat Modeling Tool
gratuita da Microsoft, e combina com o jeito como as ameaças de fato acontecem: através de uma
linha, entre um remetente e um destinatário que confiam um no outro de jeitos diferentes.

Para cada travessia, as perguntas vêm numa ordem fixa, do lado de quem manda para o lado de quem
recebe:

| | sobre | pergunta |
|---|---|---|
| **S** | a origem | quem manda é quem diz ser? |
| **T, I** | o fluxo | o dado pode ser mudado ou lido no caminho? |
| **D** | o fluxo e o destino | o destino pode ser inundado, ou o fluxo cortado? |
| **E** | o destino | o destino pode ser levado a fazer algo que quem manda não pode pedir? |
| **R** | os dois | se quem mandou negar depois, existe registro? |

### O fluxo 7, interação por interação

O webhook de pagamento vai do gateway (zona dos fornecedores) para o portal (nuvem da Vereda), e
muda um agendamento de não pago para pago.

- S, a origem: o pedido é do gateway? O portal não confere. **Esta é a T01**, e é a ameaça de
  onde a aula 1 partiu. O gateway assina cada chamada; a correção é verificar a assinatura.
- T, o fluxo: o valor ou o id do agendamento poderiam ser mudados no caminho? Ele viaja por
  HTTPS a partir do gateway, então no caminho, não. Quando qualquer um pode mandar o pedido, a
  pergunta perde o sentido: ele escreve o que quiser.
- I, o fluxo: o webhook carrega um id de agendamento e um status, nada que valha a pena ler.
- D: uma enxurrada de webhooks falsos poderia carregar o portal; a mesma resposta de qualquer
  endereço público.
- E, o destino: marcar um agendamento como pago é mais do que um pedido anônimo deveria
  conseguir fazer. São S e E descrevendo a mesma falha pelas duas pontas.
- R: se o gateway e o portal discordarem sobre uma sessão ter sido paga, a Vereda guarda o
  webhook original? Ninguém sabe, e isso já vale anotar.

Seis perguntas, uma ameaça séria, dois "conferir isto" e três respondidas. Essa proporção é normal.
O valor de percorrer as letras em ordem é que **a única ameaça séria não pôde se esconder numa
categoria que ninguém perguntou.**

### Qual variante usar

Por elemento numa primeira passada pelo sistema inteiro, porque é rápido e cobre tudo. Por
interação nos fluxos que cruzam as fronteiras que mais importam, porque é lá que as ameaças sérias
se concentram. A maioria dos modelos reais usa as duas, nessa ordem.
