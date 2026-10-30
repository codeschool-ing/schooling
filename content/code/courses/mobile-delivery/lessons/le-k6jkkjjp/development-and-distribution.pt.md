---
title: Desenvolvimento, ad hoc e a App Store
version: 1
---

**Não existe um único "build iOS assinado": existem vários, e cada um responde a uma pergunta
diferente sobre onde o app pode rodar.** O certificado e o perfil mudam com a resposta.

| | certificado | perfil | roda em |
|---|---|---|---|
| **desenvolvimento** | Apple Development, um por desenvolvedor | desenvolvimento | os aparelhos registrados da equipe, com um depurador ligado |
| **ad hoc** | Apple Distribution, um para a equipe | ad hoc | até 100 aparelhos registrados por família de produto por ano, sem a loja |
| **App Store e TestFlight** | Apple Distribution | App Store | qualquer aparelho, depois que a Apple o reassina |
| **enterprise** | um certificado de distribuição interna | interno | os aparelhos da própria empresa, com um programa separado e mais rígido |

**Um certificado de desenvolvimento pertence a uma pessoa; um certificado de distribuição pertence
à equipe.** O portal da Apple até acrescenta o nome do computador a um certificado de
desenvolvimento, para você distinguir "o MacBook da Ana" do "Mac do escritório da Ana". Uma equipe
tem poucos certificados de distribuição e os compartilha, e é exatamente isso que os torna
perigosos de perder e incômodos de compartilhar.

## Os 100 aparelhos

Builds ad hoc só rodam em aparelhos cujos identificadores estão registrados na conta, e a Apple
permite 100 por família de produto por ano de assinatura: 100 iPhones, 100 iPads, e assim por
diante. **Remover um aparelho não devolve a vaga até o próximo ano de assinatura**, quando o dono
da conta recebe a opção de zerar a lista. Uma equipe que registra todo celular que encontra fica
sem vagas na primavera. O TestFlight da lição 7 existe em boa parte por causa disso: os testadores
ali não precisam de registro nenhum.

## O que o vencimento faz com cada um

A data num certificado importa de um jeito diferente conforme o que foi assinado com ele. A
documentação da Apple é específica, e vale ler palavra por palavra:

- **Um app da App Store continua funcionando quando o certificado de distribuição vence**, desde
  que a assinatura do programa esteja em dia. Você não consegue mais enviar builds novos assinados
  com ele, e builds enviados mas ainda não submetidos podem ser marcados como *Invalid Binary* se o
  certificado foi revogado.
- **Um build ad hoc ou de desenvolvimento para de abrir** quando o perfil dele vence. As cópias dos
  testadores simplesmente se recusam a abrir.
- **Uma assinatura do programa vencida** tira os seus apps da loja; quem já os instalou ainda
  consegue usá-los.

Então o vencimento quase nunca quebra quem usa o seu app. **Ele quebra você**: o build de release
que assinava bem ontem falha hoje de manhã, na véspera de um lançamento.

## As três plataformas lado a lado

| | Android | iOS | React Native |
|---|---|---|---|
| um build para o seu celular | chave de debug, criada automaticamente | certificado e perfil de desenvolvimento | os da plataforma, por plataforma |
| um build para testadores fora da loja | qualquer APK assinado com a sua chave | ad hoc, só aparelhos registrados | por plataforma; o Expo compartilha um build ad hoc por link |
| o build da loja | um `.aab` assinado com a chave de upload | um arquivo assinado com o certificado de distribuição | os dois |
