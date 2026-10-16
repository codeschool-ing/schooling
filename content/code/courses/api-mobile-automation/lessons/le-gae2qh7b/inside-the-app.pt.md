---
title: Um teste que roda dentro do app
version: 1
---

**Um teste de Espresso não é um programa que olha para o app; é código rodando no próprio processo
do app.** O Gradle empacota os testes num segundo APK, o *APK de teste*, instala-o no aparelho ao
lado do app, e pede ao Android que inicie o app sob o controle da **instrumentação** do APK de
teste, um executor que o Android tem exatamente para isso. A partir desse momento o teste e o app
dividem um processo, uma memória e uma thread principal. A lição 14 chamou isso de *teste
instrumentado*; o Espresso é a biblioteca do Google para escrever o tipo que mexe na tela.

A primeira imagem costuma ser a do Espresso como um Appium escrito em Kotlin: outro jeito de tocar
em botões por fora. Tudo o que o faz diferente vem de estar dentro:

| | Appium (lição 15) | Espresso |
|---|---|---|
| **onde o teste roda** | no seu computador, num processo próprio | no aparelho, no processo do app |
| **como acha uma view** | pergunta à árvore de acessibilidade, por um driver | segura as views do app e busca nelas diretamente |
| **o que consegue nomear** | o que a tela mostra | isso, e as classes do próprio app: `R.id.refresh`, os objetos `Show` por trás da lista, `Shows.baseUrl` |
| **linguagem** | qualquer uma com cliente | Kotlin ou Java, a do próprio app |
| **outros apps** | sim: um diálogo de permissão, a tela de configurações | não: só as janelas deste app (lição 21) |
| **espera** | o teste espera, explicitamente | o Espresso espera a thread principal antes de cada passo |

## Caixa cinza

Um teste que só vê a tela se chama *caixa preta*; um que lê o código é *caixa branca*. O Espresso é
**caixa cinza**: ele age pela tela como uma pessoa, tocando e lendo o que está desenhado, e também
pode entrar no app quando isso melhora o teste. Os testes desta lição fazem isso duas vezes. Um
escolhe uma linha da lista pelo objeto `Show` que ela guarda, e não pela posição na tela. Outro
aponta o `Shows.baseUrl` para um endereço que ninguém responde, o que nenhuma pessoa com o celular na
mão poderia fazer, para ver o que o app faz quando o boxoffice sumiu.

Esse alcance tem um preço. Um teste que conhece as classes do app quebra quando elas são
renomeadas, e pode pôr o app num estado a que nenhum usuário chegaria e então relatar um defeito que
ninguém jamais encontraria. **Use-o para montar uma situação em que uma pessoa poderia estar, nunca
para pular a tela que está sendo testada.**

## O que o Espresso espera, e o que não espera

O Android desenha tudo numa só thread, a **thread principal**, que trata os toques, roda o código da
activity e redesenha a tela, uma mensagem por vez. Antes de cada ação e de cada verificação, o
Espresso espera até a fila dessa thread não ter mais nada a fazer. Um toque que abre uma tela nova,
uma lista que a thread principal ainda está preenchendo: o Espresso espera por eles sem ninguém
pedir, e é por isso que um teste de Espresso raramente precisa de uma espera escrita nele.

**Ele espera a thread principal e nada mais** do que é seu. (Ele também observa o grupo de
trabalhadores em segundo plano que a velha classe `AsyncTask` do Android usava, que código novo não
usa mais.) Trabalho que roda numa thread que o próprio app iniciou é invisível para ele. O Tickets
carrega os espetáculos numa thread própria, porque o Android proíbe chamadas de rede na thread
principal (lição 14), então enquanto a requisição está fora a thread principal está ociosa e o
Espresso considera o app pronto. A seção 05 trata do que isso faz com um teste, e de como corrigir.
