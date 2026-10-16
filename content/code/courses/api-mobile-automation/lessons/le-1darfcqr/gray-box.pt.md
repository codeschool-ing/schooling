---
title: Esperando um app ocioso
version: 1
---

**A única ideia do Detox é que um teste nunca deveria precisar esperar por conta própria.** Antes de
cada ação e de cada expectativa, o Detox espera até o app estar ocioso, e só então toca ou olha. A
lição 15 esperava explicitamente, elemento por elemento, de fora; a lição 16 deixou o Espresso esperar
a thread principal e depois precisou ensiná-lo sobre a carga. O Detox vai além dos dois, porque um app
React Native tem mais lugares onde o trabalho se esconde, e o Detox os observa por você.

A imagem errada é a do Detox como um Appium para React Native: um driver de fora, mais rápido de
configurar. Ele está mais perto do Espresso, e no Android é construído sobre o Espresso. O Detox põe
uma pequena biblioteca dentro do app, que fala com o teste por um WebSocket, e a biblioteca consegue
ver o que o app está fazendo.

## O que "ocioso" quer dizer para o Detox

A documentação do Detox lista o que ele espera. Nas duas plataformas, o app está ocupado enquanto
qualquer uma destas coisas for verdade:

| o app está ocupado enquanto | um exemplo no app desta lição |
|---|---|
| a thread principal tem trabalho na fila | a lista sendo desenhada depois de uma resposta |
| uma requisição de rede está em andamento | o `fetch` pedindo os espetáculos ao boxoffice |
| um timer de JavaScript está para disparar | um `setTimeout` esperando para rodar |
| uma animação está rodando | uma lista rolando até o lugar |
| a thread de JavaScript está ocupada, ou o React Native ainda está passando trabalho entre o JavaScript e o lado nativo | a atualização de estado depois que a resposta chega |

A segunda linha é aquela para a qual a lição 16 precisou de um idling resource. **O Detox sabe da rede
sozinho**: a requisição ao boxoffice mantém o app ocupado até a resposta chegar e a lista ser
desenhada, e a spec da seção 05 não tem espera nenhuma.

## Três jeitos de esperar, comparados

| | Appium (lição 15) | Espresso (lição 16) | Detox |
|---|---|---|---|
| **quem espera** | o teste, explicitamente | o Espresso, pela thread principal | o Detox, por tudo o que está acima |
| **o que você escreve** | `waitForDisplayed({ timeout })` em cada elemento | nada, até o trabalho sair da thread principal; aí um idling resource | nada, até o app nunca ficar ocioso; aí a seção 06 |
| **falha quando o app está lento** | um tempo esgotado que nomeia o elemento | um tempo esgotado que nomeia o idling resource | um tempo esgotado que lista o que manteve o app ocupado |
| **falha quando o app nunca se acalma** | nenhuma: o teste não se importa | rara | o teste fica parado até o tempo limite dele |

Leia a última linha com cuidado, porque ela é o preço da ideia. Um teste que espera um app ocioso não
consegue rodar contra um app que nunca fica ocioso, por mais correta que a tela esteja. Esse é o
assunto da seção 06.

**A caixa cinza tem aqui o mesmo preço que na lição 16.** O Detox conhece o app o bastante para
esperá-lo, e um teste pode desligar esse conhecimento, o que a seção 06 precisa fazer. Desligue-o para
a parte do app que nunca se acalma, e nunca para uma suíte inteira porque um teste estava lento.
