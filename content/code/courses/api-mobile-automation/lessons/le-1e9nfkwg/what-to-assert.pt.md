---
title: O que um teste numa rede ruim deve afirmar
version: 1
---

**Um teste numa rede ruim não está testando se a requisição dá certo. Ele foi montado para que ela
não desse.** Ele testa o que a pessoa vê enquanto ela falha e o que o servidor guarda depois. Afirmar
`200` por um proxy que derruba respostas produz um teste que falha sempre que uma perda cai nele, e não
ensina nada. Afirmar a tela e os lugares produz um teste que vale sejam quais forem as respostas
perdidas.

## Os casos, e o que cada um precisa mostrar

| caso | afirmar | onde esta lição ou uma anterior confere |
|---|---|---|
| **sem rede, com cópia salva** | a cópia na tela, e a faixa dizendo que é uma cópia e de quando | o `OfflineTest` da lição 16 |
| **sem rede, nada salvo** | a linha de erro, que diz o que fazer: *Check the connection and press Refresh* | o `OfflineTest` da lição 16 |
| **lenta, dentro do limite** | uma lista nova e nenhuma faixa | `SlowNetworkTest`, seção 05 |
| **lenta, além do limite** | a cópia salva, identificada | `SlowNetworkTest`, seção 05 |
| **uma resposta perdida depois de uma compra** | um pedido no servidor, lido do próprio servidor | `tests/poor-network.test.mjs`, seção 04 |
| **a rede volta** | Atualizar traz uma lista nova e a faixa some | abaixo |
| **a espera** | quanto tempo a tela pode ficar parada, e o que ela mostra enquanto isso | um número a combinar, abaixo |

## Quando a rede volta

**A recuperação é o caso mais esquecido**, porque a falha foi testada e o teste termina ali. No
Tickets ela é um botão. O `display` esconde a faixa e a linha de erro primeiro, na linha 50 da
`MainActivity` da lição 14, então uma carga nova depois de uma offline não deve deixar nenhuma das duas. Um
terceiro teste para o `SlowNetworkTest` confere isso com o proxy lento e o próprio boxoffice.
Acrescentá-lo à classe fica com você:

```kotlin
Shows.baseUrl = SLOWER_THAN_THE_TIMEOUT
onView(withId(R.id.refresh)).perform(click())
onView(withId(R.id.banner)).check(matches(isDisplayed()))
Shows.baseUrl = boxoffice
onView(withId(R.id.refresh)).perform(click())
onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
```

Nada no Tickets atualiza sozinho quando a rede volta. A pessoa precisa apertar o botão. Se deveria é
uma questão de produto, e o teste honesto afirma o que o app promete hoje.

## A espera que uma pessoa aguenta

**Não existe número certo de segundos**, e um plano de testes que finge que existe pegou um
emprestado. O que quem testa pode fazer é medir o pior caso e pô-lo na frente de quem decide. O do
Tickets é maior do que os dois limites de cinco segundos sugerem. Uma conexão aceita em quatro
segundos e depois em silêncio por mais quatro leva oito. Uma resposta que pinga mais devagar que um
pedaço a cada cinco segundos nunca dá timeout. Durante tudo isso, a seção 05 viu, a tela não mostra
nada que diga que está esperando. **"A tela diz alguma coisa em um segundo" é uma asserção melhor que
qualquer timeout**, e é a que o Tickets reprovaria hoje.

## O que não afirmar

- Durações exatas. Uma requisição por `DELAY=800` leva um pouco mais de 800 ms, nunca exatamente.
  Afirme uma janela, como a lição 13 fez para o timeout do pagamento: pelo menos o atraso, e bem
  abaixo do próximo limite.
- Qual requisição se perde, a menos que o teste tenha fixado a semente. Com a `SEED` definida, o
  proxy perde as mesmas respostas em toda execução, e é isso que permite ao `poor-network.test.mjs`
  esperar um replay. Com uma semente aleatória, afirme só o que vale sejam quais forem as requisições
  perdidas, que é a contagem de lugares.
- Que o Android diz que o celular está offline. O Wi-Fi de café da seção 02 está conectado e não
  serve para nada. O app precisa lidar com o que as requisições dele fazem, não com o que a barra de
  status mostra.

## O que esta lição encontrou

Quatro coisas para o relatório, cada uma com a evidência em que se apoia. Duas vêm das execuções. **Um link
lento para o provedor de pagamento cobra um cliente por um pedido que o boxoffice chama de falho**,
que é o defeito da lição 13 alcançado sem provedor lento. **Um cliente que tenta de novo uma compra
sem chave de idempotência compra um ingresso para cada resposta perdida**, e isso pertence ao
relatório do time do cliente e não ao do boxoffice. Duas vêm do código do Tickets, a confirmar no seu
emulador: nenhum sinal de carga em andamento, e "Offline" mostrado para uma rede que só está lenta.
