---
title: Eventos de aplicação, enviados pelo menos uma vez
version: 1
---

**Um evento de aplicação é um registro que o app envia de propósito, um para cada coisa que uma pessoa
fez, e ele chega pelo menos uma vez em vez de exatamente uma vez.** O banco do app guarda o estado das
coisas: esta viagem está aberta, este cliente tem este cartão. Eventos guardam as ações, inclusive as
que não mudam nada em banco nenhum. Um cliente abriu o mapa, olhou o Batel, não viu bicicleta e fechou o
app. Nenhuma linha em lugar nenhum registra isso, e é exatamente o que Marta quer saber quando pergunta
onde a demanda fica sem atendimento.

Os desenvolvedores do app decidem quais eventos existem e acrescentam uma linha no app para cada um.
Quando algo acontece, o app monta um pequeno objeto JSON e o envia a um coletor, um serviço cujo único
trabalho é receber eventos e anotá-los. Produtos como Snowplow e Segment fazem esse trabalho, e alguns
times constroem o próprio. Uma viagem sendo iniciada fica mais ou menos assim:

```json
{
  "event_id": "5f0c2a9e-3b71-4c55-9d0e-7a1f6c2b8e40",
  "name": "ride_started",
  "occurred_at": "2025-09-15T08:03:12-03:00",
  "customer_id": "C0412",
  "app_version": "3.4.0",
  "properties": {"station": "ST02", "bike_id": "B017"}
}
```

## Nomes combinados antes de serem enviados

A lista de eventos, os nomes deles e os campos que cada um carrega se chama **plano de rastreamento**
(tracking plan), e é um documento que o time de produto e o time de dados combinam antes de uma linha
do app ser escrita. Sem ele, cada desenvolvedor dá nome aos eventos como quiser. A versão 3.3 do app
envia `rideStarted`, a 3.4 envia `ride_started`, e as duas estão nos dados ao mesmo tempo, porque os
clientes não atualizam todos no mesmo dia. Toda contagem de viagens iniciadas fica então errada de um
jeito que depende de quantos celulares ainda estão na 3.3. Um evento tem esquema como uma tabela tem;
ele só está escrito em outro lugar, se estiver escrito, e a aula 5 é sobre onde um esquema mora.

## Por que o mesmo evento chega duas vezes

Um celular envia um evento, o coletor o anota e responde "recebido". Se essa resposta se perde, num
ônibus passando sob um viaduto ou num elevador, o celular não consegue distinguir uma resposta perdida
de um evento perdido, então envia o evento de novo. A alternativa é pior: um celular que nunca
reenviasse nada perderia todo evento enviado para uma conexão morta. Então o app é feito para reenviar
até ouvir a resposta, o que se chama **entrega pelo menos uma vez** (at-least-once), e o preço é que
alguns eventos são anotados duas vezes.

As duas cópias são idênticas, inclusive o `event_id`, um identificador aleatório que o celular deu ao
evento quando o criou. É esse campo que torna a duplicata removível: dois eventos com um id só são um
evento. Sem ele, dois `ride_started` do mesmo cliente com um segundo de diferença podem ser uma nova
tentativa ou um cliente que tocou duas vezes, e ninguém consegue dizer qual. **Peça o id antes do
primeiro evento ser enviado**, porque ele não pode ser acrescentado a eventos já coletados. A aula 8 dá
nome às garantias de entrega e ao que cada uma custa.

## Dois relógios em cada evento

O `occurred_at` vem do relógio do celular. O coletor acrescenta o próprio horário, de quando o evento
chegou. Eles diferem por dois motivos, e os dois são normais:

- **O celular estava sem conexão.** Eventos feitos num túnel ficam guardados no celular e são enviados
  quando ele reconecta, minutos ou dias depois. Um evento de segunda pode chegar na quarta, depois que os
  números de segunda foram publicados.
- **O relógio do celular está errado.** Ele é do cliente, que pode acertá-lo para qualquer coisa. Um
  evento que aconteceu, segundo o celular, em 2031 é uma coisa real que um coletor recebe.

Guarde os dois horários. O do celular é aquele de que a pergunta costuma tratar, e o do coletor é aquele
em que dá para confiar; qual usar, e o que fazer com um evento que chega depois que o dia dele foi
contado, são o assunto da aula 8.
