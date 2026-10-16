---
title: Três produtos, duas histórias
version: 1
---

A aula 7 montou o trabalho à mão. Esta aula é sobre os produtos que o vendem, e a primeira coisa a saber
sobre eles é que não começaram no mesmo lugar.

**Hightouch e Census começaram como reverse ETL.** Cada um lia um modelo do warehouse e o escrevia em
ferramentas de operação: a seta da aula 7, com um catálogo de destinos atrás. O Census foi comprado pela
Fivetran em 2025 e hoje é vendido como **Fivetran Activations**; a documentação dele mora na da
Fivetran, e você vai encontrar os dois nomes por um tempo. O Hightouch continua independente, e hoje
chama o que vende de *composable CDP*, que esta aula explica.

**O Segment começou na outra ponta.** Era um jeito de coletar eventos — uma visita, uma visualização de
produto, uma compra — de um site ou de um app uma vez só, e repassá-los a toda ferramenta que os
quisesse, em vez de instalar o trecho de código de cada ferramenta. A Twilio o comprou em 2020, e a
documentação dele agora está no site da Twilio. O Segment acrescentou Reverse ETL depois, então hoje faz
as duas coisas: coleta eventos na entrada e manda modelos do warehouse na saída.

| | começou como | a seta que desenha |
|---|---|---|
| Hightouch | reverse ETL | warehouse → ferramentas |
| Census (Fivetran Activations) | reverse ETL | warehouse → ferramentas |
| Segment (Twilio) | coleta de eventos | app → warehouse e ferramentas, e desde então warehouse → ferramentas |

Nenhum dos três roda na sua máquina, e cada um precisa de uma conta, de um warehouse que ele alcance
pela internet e de um destino com chave de API. **Nada desta aula sobre as telas deles foi rodado
aqui**: o que ela diz deles vem da própria documentação, lida em 2026, e cita o termo documentado para
você poder encontrá-lo. O que foi rodado é o SQL, contra o mesmo banco `lantern` de todas as outras
aulas.

O motivo de pô-los ao lado da aula 7 não é escolher um. É que cada decisão que você tomou à mão virou
uma configuração nas telas deles, e **uma configuração que você nunca precisou decidir é uma que você não
consegue julgar**.
