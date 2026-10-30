---
title: "Duas chaves no Google Play, uma chave em todo o resto"
version: 1
---

**No Google Play, a chave que você criou não é a que os celulares veem.** A documentação do Google
sobre assinatura de apps descreve o arranjo que chama de Assinatura de apps do Google Play: você
assina o bundle com a sua **chave de upload**, o Google Play confere essa assinatura para saber que o
envio veio de você, monta os APKs e os assina com a **chave de assinatura do app**, que o Google gera
ou recebe de você e guarda no próprio serviço de gerenciamento de chaves. Configurá-la é obrigatório
para distribuir pelo Google Play, segundo a mesma página, exceto para apps criados antes de agosto de
2021.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l22-keys\" aria-label=\"Dois caminhos de um app até o celular. Pelo Google Play, em cima: você assina o bundle com a sua chave de upload e o envia; o Google Play confere a chave de upload, monta os APKs e os assina com a chave de assinatura do app, que o Google guarda; o celular confere que toda atualização traz a mesma chave de assinatura do app. Uma chave de upload perdida pode ser substituída pedindo ao Google. Distribuição direta, embaixo: você assina o APK com a sua própria chave e o entrega; o celular confere cada atualização contra essa chave; uma chave perdida quer dizer que o app nunca mais pode ser atualizado.\"><defs><marker id=\"l22-keys-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-keys-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o seu computador</text><text x=\"360\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Google Play</text><text x=\"610\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o celular</text><rect x=\"20\" y=\"32\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinado com</text><text x=\"110\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a chave de upload</text><rect x=\"270\" y=\"32\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confere a chave de upload,</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assina com a chave do app</text><rect x=\"520\" y=\"32\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada atualização: mesma</text><text x=\"610\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave de assinatura?</text><path d=\"M200 57 L268 57\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-keys-ah-phosphor)\"></path><text x=\"234\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">envia .aab</text><path d=\"M450 57 L518 57\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-keys-ah-phosphor)\"></path><text x=\"484\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">APKs divididos</text><text x=\"110\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave de upload perdida: o Google a redefine</text><rect x=\"20\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinado com</text><text x=\"110\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a sua própria chave</text><rect x=\"520\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada atualização: mesma</text><text x=\"610\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave da instalada?</text><path d=\"M200 195 L518 195\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-keys-ah-amber)\"></path><text x=\"359\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">entrega .apk</text><text x=\"110\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">chave perdida: nunca mais atualiza</text><path d=\"M20 135 L700 135\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path></svg>", "caption": "No Google Play, duas chaves: a sua prova que o envio veio de você, e a do Google assina o que os celulares instalam. Fora do Play há uma chave só, e ela é o app.", "same": ["Google Play"]}
```

A divisão existe para o pior dia. **Se você perder a chave de upload, ou outra pessoa a obtiver, pode
pedir uma redefinição da chave de upload no Play Console**, e como a chave de assinatura do app nunca
saiu do Google, a próxima atualização ainda se instala sobre a versão antiga em todo celular. A
documentação também faz a comparação: para um app que não usa a Assinatura de apps do Google Play,
perder a chave de assinatura é perder a capacidade de atualizar o app.

## O flavour `direct` não tem essa rede de proteção

O APK `direct` da seção 03 é instalado a partir de um arquivo, e a chave com que ele é assinado é a
única coisa contra a qual toda atualização futura vai ser conferida. **Para esse flavour, a sua chave
é o app.** Perca-a, e o planner no celular de cada estudante nunca mais pode ser atualizado; a única
saída é um app novo, com um nome de pacote novo, que cada estudante precisa encontrar e instalar
enquanto o antigo continua lá, intocado. Guardar uma cópia do keystore e da senha longe do
computador, como a seção 04 pediu, é toda a defesa.

## O que a loja vê, e o que ela pede

O Google Play também usa as impressões digitais dos certificados: o SHA-256 da chave de assinatura
do app, mostrado no Play Console, é a impressão digital que um serviço como um provedor de login ou
uma API de mapas pede para restringir uma chave de API ao seu app. A impressão digital da chave de
upload, a que o `keytool` mostrou na seção 04, é a que você entrega ao Google quando registra a chave
de upload.

**Não executado.** Nada nesta seção foi feito num Play Console: a gravação não tinha conta de
desenvolvedor, e a conta custa dinheiro, como a próxima seção diz antes de qualquer outra coisa. Tudo
aqui vem da página do Google *Sign your app*, lida em 30 de outubro de 2026.
