---
title: Apontando as suítes para uma nuvem
version: 1
---

**Levar uma suíte para uma nuvem muda onde ela se conecta e o que ela instala, e deixa os próprios
testes em paz.** Um teste Appium se conecta ao servidor da nuvem em vez de `127.0.0.1:4723`; uma
suíte Espresso são dois APKs enviados em vez de instalados pelo Gradle. Tudo o que um teste confere
fica como as lições 15 e 16 o escreveram.

**Nenhuma nuvem de aparelhos foi usada neste curso.** Cada uma exige uma conta, e a máquina de
gravação não tinha nenhuma, então nada abaixo foi rodado e nenhuma saída, relatório ou vídeo de uma
aparece. As opções e os comandos são os que as ferramentas documentam; os detalhes que mudam de um
fornecedor para outro são apontados em vez de adivinhados.

## Appium, no servidor de uma nuvem

Primeiro o APK é enviado, pela página web da nuvem ou pela API de envio dela, e a nuvem responde com
um identificador para ele, que a sessão então nomeia no lugar de um caminho no seu disco. O teste da
lição 15 só muda na chamada a `remote()`:

```js
driver = await remote({
  protocol: 'https',
  hostname: process.env.CLOUD_HOST,
  port: 443,
  path: '/wd/hub',
  user: process.env.CLOUD_USER,
  key: process.env.CLOUD_KEY,
  logLevel: 'warn',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:app': process.env.CLOUD_APP,
    'appium:deviceName': 'Galaxy A15',
    'appium:platformVersion': '14',
  },
});
```

- **`protocol`, `hostname`, `port` e `path`** são o servidor da nuvem, que a documentação dela
  informa; `user` e `key` são o nome da sua conta e a chave de acesso, lidos do ambiente como todo
  segredo desde a lição 3.
- **`appium:app`** é o identificador que o envio devolveu, guardado em `CLOUD_APP`.
- **`appium:deviceName` e `appium:platformVersion`** escolhem uma linha da matriz, o modelo do topo
  da seção 03 na versão dele. Cada nuvem escreve os modelos do seu jeito, então os nomes vêm do
  catálogo dela.
- Qualquer outra coisa que uma nuvem ofereça, como um nome para o build ou se deve gravar vídeo, vai
  num objeto próprio com o prefixo do fornecedor, `bstack:options` no BrowserStack e `sauce:options`
  no Sauce Labs, pela mesma regra do W3C que a lição 15 explicou para `appium:`.

Para rodar a matriz, o mesmo teste roda uma vez por linha com essas duas capacidades trocadas, várias
ao mesmo tempo se o plano permitir. E a linha do teste que perguntava os lugares ao boxoffice agora
precisa perguntar à cópia do servidor que o celular da nuvem alcança, como a seção 05 disse.

## Espresso, no Firebase Test Lab

O Espresso não precisa de servidor: a nuvem instala o app e o APK de teste e roda a instrumentação
ela mesma, como o Gradle fez na lição 16. O Gradle compila os dois a partir da pasta `tickets`, com o
APK de teste ao lado do app em `app/build/outputs/apk/androidTest/debug/`:

```sh
./gradlew assembleDebug assembleDebugAndroidTest
gcloud firebase test android models list
gcloud firebase test android run --type instrumentation \
  --app app/build/outputs/apk/debug/app-debug.apk \
  --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=MODEL_ID,version=34,locale=pt_BR,orientation=portrait \
  --device model=OTHER_MODEL_ID,version=33,locale=en,orientation=portrait
```

O `gcloud` é a ferramenta de linha de comando do Google Cloud, e precisa de um projeto do Google
Cloud com o Test Lab ativado. `models list` imprime o catálogo, com o id de cada modelo e as versões
do Android que ele oferece; `MODEL_ID` e `OTHER_MODEL_ID` representam dois desses ids. Cada
`--device` é uma linha da matriz: modelo, versão do Android, idioma e orientação, então as doze
linhas da seção 04 são doze linhas assim. Os resultados, JUnit XML, um vídeo e o log do aparelho para
cada linha, chegam num bucket do Cloud Storage e no console do Firebase.

`--type robo` roda no lugar o rastreador do Test Lab, que abre o app e vai tocando pelas telas sem
teste escrito nenhum. Ele não substitui uma suíte, já que confere pouco além de falhas fatais, e é
uma primeira olhada barata num app em muitos celulares de uma vez.

## Lendo um resultado de longe

Uma execução na nuvem falha por mais motivos que uma local, então leia em ordem:

1. **Assista ao vídeo** no passo que falhou. Uma tela que nunca carregou, um diálogo do sistema por
   cima do app, um teclado cobrindo o botão: cada um aparece num segundo.
2. **Rode a mesma linha de novo.** Uma falha que não se repete é a rede ou a nuvem; uma que se repete
   é o app naquele celular.
3. **Compare a linha com as vizinhas.** Se o mesmo teste passa nos outros modelos daquela versão e
   falha nos de um fabricante, ele vai para a tabela da lição 19 como defeito que só um aparelho
   mostra, e o relatório diz de que build ele veio.
