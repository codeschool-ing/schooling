---
title: O que você pratica aqui, o que você lê e o que custa dinheiro
version: 1
---

**Este curso trata de tudo o que acontece depois que o build passa**: assiná-lo, publicá-lo em
duas lojas, passar pela revisão, liberá-lo alguns por cento de cada vez, ler o que quebrou e
decidir se alguém voltou. Ele vem depois da bifurcação da trilha, então você chega tendo construído
um app em Kotlin, em Swift ou em React Native. Onde os três diferem, o curso mostra os três lado a
lado, de forma breve, e os exemplos que você roda não dependem de plataforma.

**As duas lojas cobram antes que você possa praticar a metade delas, e isso é dito aqui, antes que
o curso peça qualquer coisa.** Uma conta de desenvolvedor no Google Play tem uma taxa de registro
paga uma vez, e o programa de desenvolvedores da Apple custa 99 dólares americanos por ano, ou o
preço local onde a Apple define um. A lição 3 trata exatamente dessas contas. Nada neste curso
exige que você abra uma: todo exercício e toda transcrição funcionam sem conta, sem cartão e sem
celular.

## A linha, lição por lição

| lição | o que você faz no seu computador | o que você lê |
|---|---|---|
| 1, assinatura no Android | **praticado**: um keystore, um APK assinado, um app bundle e a reassinatura que o Play faz | as telas do Play Console |
| 2, assinatura no iOS | **metade**: um script que avisa antes de um certificado vencer | Xcode, certificados e perfis, tudo num Mac |
| 3 a 7, as lojas | **metade**: uma ficha, um inventário de privacidade e uma checagem pré-envio, como arquivos e scripts | os consoles, a revisão e as faixas de teste |
| 8 e 9, liberação e versões | **praticado**: uma liberação em etapas simulada, e números de versão conferidos | os controles de liberação |
| 10 e 11, CI e Fastlane | **metade**: assinatura dentro de um pipeline, e as lanes do Fastlane no Linux | o Mac hospedado e a metade iOS |
| 12 a 15, crashes e desempenho | **praticado**: um coletor de crashes, uma pilha minificada tornada legível, um watchdog, percentis de campo | Crashlytics, Sentry e os painéis das lojas |
| 16 e 17, analytics | **praticado**: eventos, um funil e retenção no SQLite | os produtos de analytics |
| 18 a 20, tamanho e versões soltas no mundo | **praticado**: um app bundle medido, configuração remota, uma flag e um teste de contrato | as páginas das lojas |

A metade iOS é lida do começo ao fim. Assinar um app de iPhone, rodar o Xcode e abrir o simulador
exigem um Mac, e o Mac não é opcional: as ferramentas de build da Apple só rodam no macOS. Se você
tem um, cada listagem em Swift do curso cabe no app que você construiu antes da bifurcação. Nada no
curso depende de você ter um.

## O que este curso não conseguiu rodar

O curso foi gravado num computador Linux. Ele instalou as ferramentas de build do Android e, com
elas, gerou, assinou, verificou e mediu pacotes Android. **Ele não tinha Mac, nem emulador
Android, nem celular.** Então nenhum build iOS foi assinado, nenhum app foi instalado em aparelho
algum e nenhum console de loja foi aberto. Cada passo desses é citado da documentação da própria
plataforma, com o mês em que foi lida, e marcado onde aparece.

**As regras das lojas neste curso foram lidas em outubro de 2026, e mudam sem aviso.** Taxas,
regras de revisão, formulários de privacidade e limites de tamanho mudam todo ano. Onde uma lição
cita um número da documentação de uma loja, ela diz isso, e o link no seu console é a versão que
vale.

Todo comando numa transcrição foi rodado, e a saída está colada como voltou.
