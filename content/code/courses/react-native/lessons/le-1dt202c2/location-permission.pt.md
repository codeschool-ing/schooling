---
title: Primeiro plano ou segundo plano, precisa ou aproximada
version: 1
---

**Localização é a permissão que as pessoas mais recusam, e elas fazem bem em pensar.** Uma lista de onde
alguém esteve, e quando, diz onde a pessoa mora, onde trabalha, quem visita e quando não está em casa.
Então as duas plataformas dividem a pergunta em duas escolhas separadas, e a pessoa faz cada uma.

## Quando: enquanto o app está em uso, ou sempre

- **Primeiro plano**, "durante o uso do app": o app recebe posições enquanto está na tela, e por um
  tempinho depois. É do que a maioria dos apps precisa, e o planner não pede nada além disso.
- **Segundo plano**, "sempre": o app recebe posições enquanto está fechado. As duas plataformas pedem
  isso como um segundo passo, separado, depois de o primeiro plano ser concedido, e as duas lojas pedem
  que o desenvolvedor justifique. A última seção desta aula é sobre isso.

## Com que precisão: ao metro, ou ao bairro

- **O Android 12 em diante** mostra uma escolha no próprio diálogo: *precisa* ou *aproximada*. Aproximada
  é uma posição com margem de alguns quilômetros, e o app fica sabendo qual recebeu.
- **O iOS** tem uma chave de *Localização Precisa* no mesmo diálogo, e um app pode pedir *precisão
  reduzida* desde o começo, e nesse caso a chave já chega desligada.

**O planner pede aproximada, e depois a deixa mais grossa ainda.** Ele precisa saber que duas sessões
foram feitas no mesmo lugar, não em qual mesa. Ele arredonda toda posição para duas casas decimais, cerca
de um quilômetro, antes de o diário vê-la, então o diário nunca contém nada mais preciso que um bairro,
seja o que for que o celular entregou. Essa é a regra de privacidade mais forte que existe: **o que nunca
é guardado não pode vazar.**

## Quando pedir

Como na aula 13, no momento em que é preciso. Para o planner, esse momento é quando a pessoa liga uma
chave chamada *Note where I study* em *This week*. Ligá-la pede; uma recusa a deixa desligada e diz o que
isso quer dizer; e enquanto ela está desligada, o planner nem encosta na localização.
