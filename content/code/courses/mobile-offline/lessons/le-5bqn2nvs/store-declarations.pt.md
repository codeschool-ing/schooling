---
title: O que as lojas obrigam a declarar
version: 1
---

**As duas lojas exigem uma declaração do que o app coleta, e a declaração precisa bater com o que o
app e cada biblioteca dentro dele de fato fazem.** É um formulário, e a tentação é preenchê-lo como
um formulário: marcar o que parece certo e seguir. As duas lojas tratam uma resposta errada como
violação de política, e as duas contam o dado coletado por uma biblioteca que você adicionou como
dado que o seu app coleta.

*Esta seção foi escrita a partir da documentação do Google e da Apple como estava em outubro de
2026. Nenhum formulário foi preenchido e nenhum app foi enviado para este curso: os dois exigem uma
conta de desenvolvedor paga, que este curso não pede. Os formulários mudam; leia as páginas atuais
antes de enviar.*

## O que conta como coletar

As duas lojas concordam na linha que mais importa aqui: **dado processado só no aparelho e que
nunca sai dele não é coletado.** Um planner offline-first ganha com isso diretamente. Sessões
guardadas no banco local e nunca sincronizadas não seriam declaradas. No momento em que a caixa de
saída as envia ao servidor do planner, elas são coletadas, e entram no formulário.

## Google Play: a seção Segurança dos dados

Todo app no Google Play tem uma seção de Segurança dos dados na página da loja, preenchida por um
formulário no Play Console. Para cada **tipo de dado** que o app coleta ou compartilha, de uma lista
fixa (informações pessoais, saúde e condicionamento físico, atividade no app, IDs do dispositivo ou
outros, e o resto), o formulário pergunta:

- se ele é **coletado** (enviado para fora do aparelho) ou **compartilhado** (passado a um
  terceiro);
- se a coleta é **obrigatória ou opcional** para a pessoa;
- as **finalidades**: funcionalidade do app, análise, personalização, gestão da conta, e outras;
- duas práticas de segurança: se o dado é **cifrado em trânsito**, e se a pessoa pode pedir que ele
  seja **apagado**.

O Google também exige que um app que deixa as pessoas criarem conta deixe que elas a **apaguem**, de
dentro do app e por uma página da web, e o formulário pede o endereço dessa página.

## Apple: os detalhes de Privacidade do app e o manifesto de privacidade

Na App Store, os mesmos fatos aparecem como os detalhes de **Privacidade do app**, o "rótulo
nutricional de privacidade", preenchidos no App Store Connect. As categorias da Apple são parecidas
(informações de contato, saúde e condicionamento físico, conteúdo do usuário, identificadores, dados
de uso, diagnóstico), e para cada uma ela faz mais duas perguntas: se o dado fica **vinculado à
identidade da pessoa**, e se é usado para **rastreamento**, a palavra da Apple para combiná-lo com
dados de outras empresas para publicidade.

Desde maio de 2024 um app também leva um **manifesto de privacidade**, um arquivo chamado
`PrivacyInfo.xcprivacy`. Ele declara os mesmos tipos de dado coletado num formato que o Xcode
consegue conferir, e dá um motivo para cada **API de motivo obrigatório** que o app chama:
interfaces que poderiam ser usadas para identificar um aparelho. Duas delas estão neste curso: o
`UserDefaults`, da aula 2, e o espaço livre em disco que o planner conferiu na aula 18. O manifesto
de um planner teria entradas como estas:

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>CA92.1</string></array>
  </dict>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>E174.1</string></array>
  </dict>
</array>
```

`CA92.1` é o motivo "o app lê os padrões que ele mesmo gravou", e `E174.1` é "conferir se há espaço
antes de gravar arquivos", que é exatamente o que o `statfs` da aula 18 fez. *Os códigos de motivo
foram copiados da lista de APIs de motivo obrigatório da Apple; o manifesto não foi construído nem
validado aqui.* A Apple também pede um jeito, dentro do app, de apagar a conta, pela diretriz de
revisão 5.1.1(v).

## Preenchendo com honestidade

Os formulários ficam mais fáceis, e mais honestos, quando são preenchidos a partir de uma lista em
vez da memória. A tabela da seção anterior é essa lista para o planner: o que ele guarda, e se
precisa. Cada biblioteca que o app acrescenta ganha a mesma linha, tirada da documentação dela,
porque um relatório de falhas que envia o modelo do aparelho, ou um kit de análise que envia um
identificador, está coletando em nome do app. E a lista é revista a cada versão, já que uma
biblioteca nova pode tornar falsas as respostas do mês passado.
