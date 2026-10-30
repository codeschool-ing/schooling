---
title: O rótulo de privacidade, a face pública do manifesto
version: 1
---

**A página de todo app na loja mostra que dados ele coleta e se esses dados são ligados à pessoa ou
usados para rastreá-la, e quem preenche é o desenvolvedor.** A Apple chama isso de *App Privacy* no
App Store Connect; as pessoas chamam de rótulo nutricional de privacidade. É uma declaração, e uma
falsa é motivo para remoção. Nada aqui foi executado; foi escrito a partir da página da Apple *App
privacy details on the App Store*, lida em 30 de outubro de 2026.

## O que "coletar" quer dizer

A página define com precisão, e a definição decide a maioria das respostas: "'Collect' refers to
transmitting data off the device in a way that allows you and/or your third-party partners to access
it for a period longer than what is necessary to service the transmitted request in real time." Dado
que fica no telefone não é coletado. Dado mandado a um servidor e descartado assim que o pedido é
respondido também não.

## As respostas do planner

O planner guarda o plano no telefone e, a partir da aula 12, sincroniza o plano com o próprio
servidor, que o armazena. **Então ele coleta um tipo de dado**, e o rótulo diz isso:

| pergunta | a resposta do planner | por quê |
|---|---|---|
| dados coletados | o plano de estudos: cursos e sessões | ele é guardado no servidor, o que é coletar |
| ligados à pessoa | sim | ele é guardado na conta dela, e a página trata dados de conta como ligados |
| usados para rastrear | não | nada é dividido com anunciantes ou corretores de dados, aula 18, seção 05 |
| fotos da câmera | não coletadas | a foto das anotações fica no telefone no desenho deste curso |

A categoria do plano é um julgamento que a página deixa ao desenvolvedor; "Other User Content" é a que
ela descreve para conteúdo que a pessoa faz no app. **Anote por que escolheu cada resposta**: o rótulo
é relido sempre que o app muda o que manda, e quem vai lê-lo da próxima vez é você.

## Dois arquivos, uma história

O **manifesto de privacidade** da aula 18 fica dentro do app, lido pelo Xcode e pelo App Store Connect,
e cobre o que o código e os SDKs fazem. O **rótulo** fica na loja, lido por pessoas, e cobre o que o
app coleta. Eles descrevem o mesmo app por dois lados, e têm de concordar. Um SDK cujo manifesto diz
que coleta identificadores do aparelho, sob um rótulo que diz que nada é coletado, é a discordância
que a App Review procura.
