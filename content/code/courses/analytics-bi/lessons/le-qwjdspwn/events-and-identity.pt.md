---
title: "A outra metade do Segment: eventos e identidade"
version: 1
---

Tudo até aqui começou de uma tabela. O trabalho original do Segment começa de uma pessoa clicando: o site
e o app da loja chamam a biblioteca do Segment, que manda uma mensagem por coisa que aconteceu, e o
Segment a repassa ao warehouse e a qualquer ferramenta ligada a ele. A especificação dele tem alguns
tipos de chamada, e três levam a maior parte do tráfego:

| chamada | o que ela diz | o exemplo da Lantern |
|---|---|---|
| `page` (ou `screen` num app) | alguém está olhando esta página | a página de produto de uma luminária |
| `track` | alguém fez isto, com estas propriedades | *add_to_cart*, produto 4, quantidade 1 |
| `identify` | este visitante é esta pessoa | o visitante entrou como o cliente 1500 |

O `web_events` da Lantern é a ponta do warehouse exatamente disso: uma linha por evento, numa sessão. O
que falta nele é a ligação com um cliente, e essa é a parte difícil que todo coletor de eventos precisa
resolver.

## Dois ids para uma pessoa

Antes de alguém entrar na conta, a biblioteca dá ao navegador um **id anônimo** aleatório e o manda com
cada evento. Quando a pessoa entra, o `identify` manda o id anônimo junto com o **user id**, que é o id
de cliente da loja, e daí em diante os dois são reconhecidos como uma pessoa só. Os eventos de antes da
entrada podem então ser contados como desse cliente.

O que dá errado é previsível:

- **A mesma pessoa em dois aparelhos** tem dois ids anônimos, ligados só se ela entrar nos dois.
- **Quem apaga os cookies** volta como um id anônimo novo, e é um visitante novo em toda contagem.
- **O user id precisa ser o id da loja**, nunca um endereço de e-mail, pelo motivo da aula 7: é a única
  chave que não muda.

É também assim que o Segment cobra a coleta de eventos, assunto a que a última seção volta: por
**monthly tracked users**, pessoas vistas num mês, e um visitante anônimo que nunca entra na conta conta
como uma delas.
