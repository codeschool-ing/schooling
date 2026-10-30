---
title: As recusas comuns, e a que se repete
version: 1
---

**A maioria das recusas não é sobre regras sutis; é sobre um revisor que não conseguiu fazer o que
a ficha prometia.** A Apple diz que **mais de 40% das pendências não resolvidas são da diretriz 2.1,
App Completeness**: crashes, conteúdo provisório, informação incompleta. Essa é a recusa que se
repete, release após release, equipe após equipe, e quase sempre dá para evitá-la.

## Os motivos de sempre na Apple

| diretriz | o que significa na prática |
|---|---|
| **2.1 App Completeness** | o app quebrou, um link estava morto, o revisor não conseguiu entrar, ou o servidor estava desligado |
| **2.3 Accurate Metadata** | capturas que mostram a tela de abertura ou de login, uma descrição que promete um recurso que o build não tem, preços no nome |
| **4.2 Minimum Functionality** | um site embrulhado num app, sem nada que um app acrescente |
| **5.1.1 Data Collection and Storage** | uma purpose string vaga, um login exigido sem motivo, nenhum jeito de excluir a conta (lição 5) |
| **3.1.1 In-App Purchase** | conteúdo digital vendido no app por qualquer coisa que não o sistema de compras da Apple |

A primeira linha merece uma frase das próprias diretrizes: *inclua as informações de uma conta de
demonstração (e ligue o seu back-end!) se o app tem login.* **O revisor não consegue se cadastrar
com um telefone de verdade, não recebe o seu código por SMS e não sabe que o seu servidor de
homologação fica desligado aos domingos.** Se o planner precisa de conta, as notas de revisão levam
uma conta de demonstração que funciona, com dados que mostram cada tela com alguma coisa dentro.

## Os motivos de sempre no Google

As recusas do Google têm forma de política, e não de diretriz numerada: **permissões** que os
recursos do app não justificam (lição 5), **respostas de Segurança dos dados** que não batem com o
que o app manda, **comportamento enganoso** como uma ficha de recursos que o app não tem, e
**funcionalidade quebrada** encontrada pelos testes automáticos dele. Uma recusa nomeia a política,
e o Play Console mostra a versão e o motivo.

## A que se repete

Uma recusa que volta no release seguinte nunca é azar. É um passo feito de memória: a conta de
demonstração cuja senha alguém mudou, a captura que ninguém gerou de novo, a resposta de
privacidade que ninguém revisitou depois de uma biblioteca nova. **O que foi recusado uma vez vira
uma linha numa checagem que roda antes de todo envio**, que é a próxima seção.

## As outras duas plataformas

Apps React Native são revisados exatamente como os nativos, e uma diretriz os afeta mais: a
**2.5.2** diz que um app não pode *baixar, instalar ou executar código que introduza ou mude
recursos ou funcionalidades do app*. Atualizações over-the-air do bundle JavaScript, como as do
Expo, ficam por isso, nas equipes cuidadosas, restritas a correções que mantêm os recursos
revisados como estavam; um recurso novo passa pela revisão num build novo. A lição 19 volta a isso.
