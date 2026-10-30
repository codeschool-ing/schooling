---
title: TestFlight, o beta antes da loja
version: 1
---

**O TestFlight é como um build chega às pessoas antes de chegar à loja.** Os testadores instalam o app
gratuito TestFlight da Apple, aceitam um convite por e-mail ou por um link público e instalam o seu
build; eles mandam comentários e capturas de tela de dentro dele, e você vê sessões e falhas no App
Store Connect. Nada aqui foi executado; os números são do *TestFlight overview* da ajuda do App Store
Connect, lido em 30 de outubro de 2026.

## Dois tipos de testador

| | internos | externos |
|---|---|---|
| quem | "up to 100 App Store Connect users with access to your content" | "up to 10,000 people", por e-mail ou link público |
| precisa de revisão antes | não | o primeiro build acrescentado a um grupo "gets sent to App Review" |
| para | o time, todo build, no mesmo dia | usuários reais, antes do lançamento |

**O primeiro build externo é revisado, e os seguintes podem não ser.** O overview diz que "a review is
required only for the first build" e que "subsequent builds may not require a full review". Essa
primeira revisão é um ensaio geral da da seção 06: um planner que trava ao abrir, ou um login que
ninguém passa, falha aqui como falharia lá.

## O que o overview pede que você forneça

- **Informações de teste**: uma descrição do beta, o que testar e um e-mail para comentários. É o que
  os testadores externos leem, e o que o revisor também lê.
- **Conformidade de exportação**: se o app usa criptografia além da que o iOS fornece. O planner fala
  com o servidor por HTTPS pelo `URLSession`, da aula 12, que a documentação da Apple sobre
  conformidade de exportação trata separado da criptografia que um app implementa por conta própria;
  responda a pergunta a partir daquela página, e não de memória.
- **Um build novo o bastante** para os mínimos da seção 02.

## Quanto tempo um build dura

"You can test a build for up to 90 days", diz o overview, e depois "your build becomes unavailable
for testers after 90 days". **Um testador que abre um build vencido não recebe nada**, então um beta
que dura um semestre precisa de um build novo pelo menos a cada três meses. Faça você mesmo um build
vencer quando ele for substituído, ou os testadores continuam usando-o mesmo depois do lançamento,
como o overview também avisa.

A aula 7 de `mobile-delivery` compara o TestFlight com os testes interno, fechado e aberto do Google
Play; a forma é a mesma, e a etapa de revisão é da Apple.
