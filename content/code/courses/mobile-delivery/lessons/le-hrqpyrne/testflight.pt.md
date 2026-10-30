---
title: TestFlight
version: 1
---

**O TestFlight é o serviço de beta da Apple, e substitui os builds ad hoc da lição 2 em quase
toda equipe.** Os testadores instalam o app TestFlight, aceitam um convite e recebem cada build
novo automaticamente, sem registro de aparelho e sem perfil para vencer no celular deles. *Lido na
documentação do TestFlight da Apple, outubro de 2026; não rodado.*

## Dois tipos de testador

| | testadores internos | testadores externos |
|---|---|---|
| quem | pessoas com um papel na sua equipe do App Store Connect | qualquer pessoa com um e-mail ou um link público |
| quantos | até 100 | até 10.000 |
| revisão | nenhuma | o primeiro build mandado a um grupo vai para o App Review; os seguintes podem não precisar de uma completa |
| para | a equipe, todo build | um público de beta, builds escolhidos |

**Um link público** deixa um grupo externo crescer sem ninguém digitar endereços, e a Apple deixa
você limitar quantas pessoas um link admite, para que um link colado num fórum não preencha os dez
mil lugares numa tarde.

## Builds que acabam

**Um build do TestFlight pode ser testado por 90 dias, e depois para de abrir.** Um testador que
volta das férias para um build que não abre não achou um bug; achou o calendário. Mandar pelo menos
um build por mês aos grupos que importam mantém todo mundo em algo que abre. Builds também podem
ser expirados antes, e é assim que uma equipe retira um beta quebrado.

## O que o TestFlight devolve

Os testadores mandam comentários do próprio app: uma captura com uma nota, ou um relatório de crash
com o comentário deles anexado. Os dois chegam ao App Store Connect ao lado do build de onde vieram.
É o relatório de crash mais barato que você vai receber, porque uma pessoa conta o que estava
fazendo; a lição 12 trata dos crashes que ninguém comenta.

## Para React Native e para Android

O build iOS de um app React Native vai para o TestFlight como qualquer outro; o `eas submit` do
Expo o envia. O build Android vai para as faixas do Play. Não existe serviço de beta
multiplataforma nas lojas, então uma equipe de React Native mantém duas escadas lado a lado, uma
por loja.
