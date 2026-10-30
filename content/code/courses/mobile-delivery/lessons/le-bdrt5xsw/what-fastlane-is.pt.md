---
title: O que é o Fastlane
version: 1
---

**O Fastlane é uma ferramenta de linha de comando que roda os passos de um release mobile a partir
de um arquivo, na mesma ordem, em qualquer máquina.** Ele é de código aberto, escrito em Ruby, e tem
uma **action** para quase tudo o que um release faz: gerar com Gradle ou Xcode, tirar capturas de
tela, assinar, enviar um build, enviar a ficha, mandar uma mensagem. Uma **lane** é uma sequência
nomeada de actions, escrita num arquivo chamado `Fastfile`.

## As actions que este curso encontra

| action | o que faz | plataforma | a lição que ela substitui à mão |
|---|---|---|---|
| `gradle` | roda uma tarefa do Gradle, como `bundleRelease` | Android | o build da lição 1 |
| `build_app`, também chamada `gym` | arquiva e exporta um build iOS com o Xcode | iOS | a assinatura da lição 2 |
| `match` | busca os certificados e perfis da equipe num repositório criptografado | iOS | lição 2 |
| `upload_to_play_store`, também chamada `supply` | envia um bundle, a ficha e as notas da versão para uma faixa | Android | lições 4 e 7 |
| `upload_to_app_store`, também chamada `deliver` | envia a ficha, as capturas e um build para revisão | iOS | lições 4 e 6 |
| `upload_to_testflight`, também chamada `pilot` | envia um build ao TestFlight e gerencia testadores | iOS | lição 7 |
| `capture_android_screenshots`, `capture_ios_screenshots` | capturas a partir de testes de UI, por aparelho e idioma | as duas | lição 4 |
| `sh` | roda qualquer comando de shell | as duas | todo o resto |

## Por que uma equipe o usa em vez de um script de shell

Um release poderia ser um script de shell, e o pipeline da lição 10 é quase isso. O Fastlane ganha o
seu lugar de três jeitos: as **actions de loja** falam as APIs das lojas, que um script de shell
teria de chamar à mão; a **organização da ficha**, uma pasta por idioma e um arquivo por campo, é o
formato que as duas actions de envio leem; e as **lanes** rodam igual num notebook e num pipeline,
então o release que uma pessoa consegue rodar é o release que o CI roda.

## Nas três plataformas

Uma equipe de Kotlin usa a metade Android, uma de Swift a metade iOS, e uma de React Native as duas,
num único `Fastfile` com um bloco `platform :android` e um bloco `platform :ios`. Projetos Expo
muitas vezes usam o **EAS Submit** no passo de envio, que faz o mesmo trabalho do `supply` e do
`deliver` a partir dos servidores do Expo; o Fastlane continua a escolha comum para tudo em volta.
