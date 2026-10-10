---
title: A camada abaixo da tela
version: 1
---

**Uma tela mostra o que um servidor decidiu.** Quando um app de ingressos diz *"restam 2 lugares"*,
o celular não contou nada: perguntou a um servidor, o servidor respondeu com um pedacinho de texto e
o app desenhou esse texto. Se a contagem está errada, o defeito está na resposta, e a tela só a
repete. Todo app deste curso funciona assim, e também a maioria dos apps que você ainda vai testar.

A conversa entre os dois tem nome. Uma **API**, interface de programação de aplicações, é o conjunto
de perguntas que um programa aceita responder e a forma de cada resposta. As que este curso testa
falam HTTP, o protocolo da web: o app manda uma requisição a um endereço, o servidor devolve uma
resposta. Nada nisso é visual, e é exatamente por isso que vale a pena testá-la sozinha.

## Por que testar ali primeiro

Três motivos, e cada um é uma medida, não um gosto.

- **É mais rápido.** Uma requisição a uma API responde em milissegundos: a seção 06 cronometra uma
  em menos de um centésimo de segundo. A mesma verificação pelo app exige abri-lo, esperar uma tela,
  achar um botão e ler um rótulo, o que leva segundos mesmo quando uma máquina faz.
- **É mais estável.** Um teste de tela falha por motivos que nada têm a ver com o defeito: uma
  animação que não terminou, um teclado cobrindo o botão, um celular que dormiu. A lição 19 lista as
  formas como um emulador engana. Uma requisição não tem nada disso; quando falha, falhou porque a
  resposta estava errada.
- **Alcança o que a tela esconde.** Um app que nunca envia sete lugares não pode mostrar o que o
  servidor faz com sete. A API pode ser perguntada diretamente, e um servidor que aceita sete quando a
  regra diz seis é um defeito que nenhum teste de tela ia achar.

Nada disso dispensa os testes do próprio app. Um servidor pode responder perfeitamente e o app ainda
desenhar o número errado, perder a resposta quando o celular gira ou travar numa conexão lenta. Isso
são as lições 14 a 22. **O curso tem duas metades de propósito**: as lições 1 a 13 testam a API, as
lições 14 a 22 testam o app num celular, e a lição 14 diz onde fica a linha entre elas.

## O que é um teste de API

Os casos de teste que você desenhou à mão em `manual-testing` continuam valendo no raciocínio: uma
entrada, um resultado esperado, um motivo. O que muda é quem os executa. Um teste de API é um
programa que manda uma requisição e confere a resposta contra o esperado:

| | um caso manual | o mesmo caso contra a API |
|---|---|---|
| **passo** | escolher 3 lugares para a sessão de 8 de novembro e tocar em *Comprar* | `POST /v1/orders` com `{"show_id": "sh-103", "seats": 3}` |
| **esperado** | uma confirmação com o total, R$ 195,00 | status `201`, e `"total_cents": 19500` no corpo |
| **evidência** | uma captura de tela | a resposta, guardada como texto |

A segunda coluna pode rodar mil vezes por dia numa máquina, e as lições 4 a 8 fazem exatamente isso
com quatro ferramentas diferentes. Antes de qualquer uma delas, você precisa ler uma resposta com os
próprios olhos, e é para isso que serve o resto desta lição.
