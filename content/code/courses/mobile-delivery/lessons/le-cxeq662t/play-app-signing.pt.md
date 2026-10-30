---
title: Play App Signing, e as duas chaves
version: 1
---

**O Google Play assina o seu app por você, com uma chave que ele guarda, e você assina só o que
envia.** Isso é o **Play App Signing**, e para todo app criado desde agosto de 2021 ele não é
opcional: o Google Play aceita um app novo só como **Android App Bundle**, um `.aab`, e gera a
partir dele os APKs que os celulares instalam. Gerá-los significa assiná-los, então o Google
precisa da chave que os assina.

Então há duas chaves, e elas fazem trabalhos diferentes.

| | a **chave de assinatura do app** | a **chave de upload** |
|---|---|---|
| quem a guarda | o Google, no cofre de chaves dele | você |
| o que ela assina | todo APK que um celular instala | o bundle que você envia |
| quem a confere | todo celular, em toda atualização | o Google Play, em todo envio |
| se ela se perde | o Google não pode lhe dar uma cópia; o app nunca mais pode ser atualizado | você pede ao Google uma redefinição |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-two-keys\" aria-label=\"Três estações da esquerda para a direita. Você assina o app bundle com a chave de upload e o envia. O Google Play confere a assinatura de upload com o certificado de upload que guarda, gera os APKs e os assina com a chave de assinatura do app, que fica com ele. O celular confere a chave de assinatura do app, na primeira instalação e em cada atualização. Uma chave de upload perdida pode ser redefinida; uma chave de assinatura do app perdida, não.\"><defs><marker id=\"l01-two-keys-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">você</text><rect x=\"265\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Google Play</text><rect x=\"510\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">o celular</text><rect x=\"40\" y=\"56\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">chave de upload</text><text x=\"115\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assina o .aab</text><rect x=\"285\" y=\"56\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">chave de assinatura do app</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">confere a assinatura</text><text x=\"360\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de upload, gera</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e assina os APKs</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confere a</text><text x=\"605\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">chave de assinatura do app</text><text x=\"605\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">confere em cada</text><text x=\"605\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">instalação e atualização</text><path d=\"M210 80 L263 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-keys-ah-paper-dim)\"></path><path d=\"M455 80 L508 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-keys-ah-paper-dim)\"></path><text x=\"237\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">.aab</text><text x=\"482\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">.apk</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"115\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">perdida: o Google redefine</text><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">perdida: nunca se recupera</text></svg>", "caption": "A chave de upload só encontra o Google. A chave que os celulares veem é a que o Google guarda, e é por isso que ela sobrevive ao seu notebook e ninguém consegue devolvê-la.", "same": ["Google Play"]}
```

**A chave de upload é a que você pode perder e sobreviver.** Se ela vazar ou sumir, o dono da
conta pede uma **redefinição da chave de upload** no Play Console, registra um certificado de
upload novo e segue em frente. Os celulares nunca souberam que a chave de upload existia: eles só
viram a do Google. *Os passos no console estão na Central de Ajuda do Play Console e não foram
rodados para este curso.*

## Fazendo o que o Play faz, na sua mesa

As ferramentas que o Google roda são as que você instalou. O `bundletool build-bundle` monta um
app bundle a partir de um módulo, o `jarsigner` o assina com a sua chave de upload, e o
`bundletool build-apks` faz o que o Google Play faz depois do envio: corta o bundle nos APKs que
um celular baixa e os assina. Aqui o módulo vem do mesmo manifesto, compilado pelo `aapt2` no
formato próprio do bundle; esse passo é um comando longo e não muda nada na assinatura, então fica
fora da transcrição. Depois, o bundle, e a sua assinatura de upload nele:

```
ana@dev:~/signing$ java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab
ana@dev:~/signing$ jarsigner -keystore upload.jks -storepass:env UPLOAD_PASS planner.aab upload
jar signed.

Warning: 
The signer's certificate is self-signed.
ana@dev:~/signing$ jarsigner -verify planner.aab

jar verified.

Warning: 
This jar contains entries whose certificate chain is invalid. Reason: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
This jar contains entries whose signer certificate is self-signed.
This jar contains signatures that do not include a timestamp. Without a timestamp, users may not be able to validate this jar after any of the signer certificates expire (as early as 2054-03-17).

Re-run with the -verbose and -certs options for more details.
```

**Os avisos são esperados, e não são sobre o seu app.** O `jarsigner` foi feito para bibliotecas
Java, onde um certificado deveria ser emitido por uma autoridade e a assinatura carimbada com um
horário. Uma chave de upload é autoassinada de propósito, e o Google Play só lê a assinatura para
compará-la com o certificado de upload que guarda para você, então nenhum dos três avisos importa
aqui.

A segunda chave faz o papel da do Google. **Ela não é a chave do Google, e nada no seu computador
jamais será**; ela é criada aqui para que a reassinatura possa ser vista:

```
ana@dev:~/signing$ keytool -genkeypair -keystore play-stand-in.jks -storetype PKCS12 -alias app -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Play stand-in, C=US" -storepass:env PLAY_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Play stand-in, C=US
ana@dev:~/signing$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/signing$ unzip -o -q planner.apks -d from-play && ls from-play/splits
base-master.apk
base-master_2.apk
ana@dev:~/signing$ apksigner verify --print-certs from-play/splits/base-master.apk | grep DN
Signer #1 certificate DN: CN=Play stand-in, C=US
ana@dev:~/signing$ apksigner verify --print-certs planner.apk | grep DN
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
```

O `bundletool` gerou duas variantes da mesma base, uma assinada para versões mais antigas do
Android e outra para as mais novas; um celular baixa só a que serve para ele. O `--ks-pass` dele
recebe a senha como `pass:` seguido do texto, então a variável é expandida pelo shell e o seu
histórico guarda `$PLAY_PASS` e não a senha.

As duas últimas linhas são o ponto da lição. O APK que você mesmo assinou nomeia o seu
certificado. O APK gerado a partir do seu bundle nomeia o outro, porque quem gera os APKs os
assina. **Os celulares conferem a chave da última linha, e você nunca a teve.**

## O que guardar, e onde

- **O keystore de upload e a senha dele, em dois lugares que não falham juntos**: um gerenciador
  de senhas para a senha, e um backup criptografado do arquivo `.jks` longe do computador que o
  criou. Um notebook roubado deveria lhe custar uma redefinição, não uma semana.
- **Nunca no repositório.** Um keystore commitado no git está em todo clone para sempre, inclusive
  nos feitos antes de você perceber. A lição 10 o coloca num pipeline como um segredo
  criptografado.
- **As impressões digitais SHA-256 dos dois certificados.** O Play Console mostra a do
  certificado de assinatura do app; serviços como o Firebase precisam dessa, e não da sua, para o
  build de release.

## As outras duas plataformas

**O iOS não tem equivalente da chave de upload.** A Apple reassina todo app que distribui, e o seu
próprio certificado de distribuição é uma credencial anual que a Apple pode emitir de novo. A lição
2 o desmonta. O **React Native** produz um projeto Android normal, então as mesmas duas chaves
valem: a configuração de release em `android/app/build.gradle` aponta o keystore de upload, e o
serviço de build do Expo, o EAS Build, pode gerar e guardar a chave de upload para você, se você
deixar.
