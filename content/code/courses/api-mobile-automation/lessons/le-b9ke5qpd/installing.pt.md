---
title: Instalando o Appium no projeto
version: 1
---

**O Appium é um pacote npm, e ele entra no projeto boxoffice como o Newman entrou na lição 6**,
para que a versão fique escrita no `package.json` e o `npm ci` de um colega instale a mesma. A
maioria dos guias o instala globalmente com `npm install -g appium`; funciona, e deixa a versão num
comando que alguém digitou uma vez, que é o hábito de que a lição 6 tirou você. A biblioteca
cliente, o WebdriverIO, entra ao lado. Em `~/boxoffice`:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact appium@3.8.0 webdriverio@9.32.0
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated whatwg-encoding@3.1.1: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 583 packages, and audited 584 packages in 23s

122 packages are looking for funding
  run `npm fund` for details

35 vulnerabilities (8 moderate, 20 high, 7 critical)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `--save-exact` fixa os dois, como fixou o Newman: Appium 3.8.0 e WebdriverIO 9.32.0. **As 35
vulnerabilidades são a auditoria do npm sobre a árvore inteira**, incluindo as 19 do Newman da
lição 6, e o raciocínio da lição 6 vale para as novas: são ferramentas que rodam na sua máquina
contra servidores que você iniciou, nunca código que chega a um usuário, então as versões continuam
fixadas e o relatório é lido de novo quando sair uma versão nova. O `npx` acha o programa dentro do
projeto:

```
ana@laptop:~/boxoffice$ npx appium --version
3.8.0
```

## O driver de Android

O Appium chega sem driver nenhum. **Cada driver é um pacote próprio, instalado pelo Appium**, que o
registra no mesmo `package.json` porque percebeu que está instalado num projeto e não globalmente.
O comando imprime uma linha para cada passo enquanto trabalha; as três últimas são o resultado,
então fique com elas:

```
ana@laptop:~/boxoffice$ npx appium driver install uiautomator2@8.7.0 2>&1 | tail -3
i Driver uiautomator2@8.7.0 successfully installed
- automationName: UiAutomator2
- platformNames: ["Android"]
```

Elas dizem a que o driver responde: sessões que pedem `automationName` `UiAutomator2` em
`platformName` `Android`. O `i` na frente é a marca do Appium para informação.

## Perguntando se o computador está pronto

Cada driver traz um **doctor**, uma lista de verificações do que ele precisa no computador. Rode-o
antes de qualquer outra coisa, porque o que ele encontra chegaria de outro modo como uma sessão
falhada muito mais tarde. Ele imprime uma linha por verificação, com um visto ou um xis na frente,
depois um resumo, e por último uma linha de conselho; o `grep` fica aqui com o resumo e o conselho:

```
ana@laptop:~/boxoffice$ npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'
info Doctor ### Diagnostic completed, 2 required fixes needed, 2 optional fixes possible. ###
info Doctor Bye! Run doctor again when all manual fixes have been applied!
```

**2 correções obrigatórias** e 2 opcionais. As verificações, como o doctor as imprimiu na máquina de
gravação, `npx appium driver doctor uiautomator2` sem nada depois:

| a linha do doctor | resultado |
|---|---|
| `ANDROID_HOME is set to: /home/ana/Android/Sdk` | passou |
| `adb, emulator exist in '/home/ana/Android/Sdk'` | passou |
| `JAVA_HOME environment variable is NOT set!` | **falhou, obrigatória** |
| `$JAVA_HOME environment variable must be set` | **falhou, obrigatória** |
| `bundletool.jar cannot be found` | falhou, opcional |
| `ffmpeg exists at '/usr/bin/ffmpeg'` | passou |
| `gst-launch-1.0 and/or gst-inspect-1.0 cannot be found` | falhou, opcional |

As duas primeiras que passaram são o que a lição 14 configurou: o `ANDROID_HOME`, e o `adb` e o
`emulator` dentro dele. Abaixo das verificações o doctor imprime um parágrafo por falha dizendo o
que fazer, e a última linha dele é `Error: × Treatment required`.

**A correção obrigatória é o `JAVA_HOME`**, relatada duas vezes. O driver roda ferramentas Java do
SDK para verificar e assinar os pacotes que instala no aparelho, então precisa saber onde há um
JDK. A lição 7 instalou um; diga ao terminal onde ele está. No Ubuntu, acrescente esta linha ao
`~/.bashrc` e abra um terminal novo:

```sh
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

Se você pulou a lição 7, o Android Studio traz um JDK próprio, numa pasta chamada `jbr` dentro do
lugar onde está instalado: `/Applications/Android Studio.app/Contents/jbr/Contents/Home` num Mac, e
`C:\Program Files\Android\Android Studio\jbr` no Windows, onde ele vai numa variável de usuário
chamada `JAVA_HOME`. Depois, o doctor de novo:

```
ana@laptop:~/boxoffice$ npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'
info Doctor ### Diagnostic completed, 0 required fixes needed, 2 optional fixes possible. ###
info Doctor Bye! All issues have been fixed!
```

A saída completa agora tem `JAVA_HOME is set to: /usr/lib/jvm/java-21-openjdk-amd64` como aprovada,
e uma segunda verificação de que `bin/java` existe dentro dele. **Restam dois avisos, e os dois são
opcionais**: o bundletool, para apps distribuídos como Android App Bundle em vez de APK, e o
GStreamer, para transmitir a tela do aparelho ao computador. O Tickets é um APK e nada neste curso
transmite tela, então deixe-os. O `ffmpeg` foi encontrado porque a máquina de gravação por acaso o
tem; na sua essa linha pode ser um terceiro aviso opcional, para gravar a tela em vídeo, e a mesma
resposta vale.

## O servidor

O `npx appium` inicia o servidor. Iniciado do jeito que vem, ele diz onde está escutando:

```
ana@laptop:~/boxoffice$ npx appium
[Appium] Appium REST http interface listener started on http://0.0.0.0:4723
	http://127.0.0.1:4723/ (only accessible from the same host)
	http://192.0.2.2:4723/
```

**`0.0.0.0` quer dizer todas as interfaces de rede do computador**, e o segundo endereço da lista é
o endereço da própria máquina de gravação na rede dela. Qualquer pessoa que alcance esse endereço
na porta 4723, no mesmo Wi-Fi do escritório ou do café, pode abrir uma sessão no seu servidor:
instalar um app no celular conectado, ler a tela dele, tirar uma captura de tela. Um servidor que
comanda aparelhos merece pelo menos o cuidado de um que vende ingressos, então pare-o com Ctrl-C e
**inicie-o só no endereço de loopback**, num terminal só para ele, em `~/boxoffice`, e deixe-o
rodando enquanto trabalha:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1
dbug Appium Creating hash file directory: /home/ana/boxoffice/node_modules/.cache/appium
[Appium] Welcome to Appium v3.8.0
[Appium] Non-default server args:
[Appium] { address: '127.0.0.1' }
[Appium] The autodetected Appium home path: /home/ana/boxoffice
[Appium] Attempting to load driver uiautomator2...
[Appium] Requiring driver at /home/ana/boxoffice/node_modules/appium-uiautomator2-driver/build/lib/index.js
[Appium] AndroidUiautomator2Driver has been successfully loaded in 0.592s
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
[Appium] Available drivers:
[Appium]   - uiautomator2@8.7.0 (automationName 'UiAutomator2')
[Appium] No plugins have been installed. Use the "appium plugin" command to install the one(s) you want to use.
```

`Non-default server args` repete a única escolha que você fez. O resto diz onde o Appium guarda os
drivers (o projeto, que ele detectou), quais drivers carregou, e que agora escuta em `127.0.0.1`,
que só programas do seu próprio computador alcançam. A linha `dbug` é contabilidade do Appium: ele
guarda uma impressão digital do `package.json` numa pasta de cache, para perceber quando a lista de
drivers muda, e a maioria dos comandos do Appium imprime uma. Faça a ele, de outro terminal, a
pergunta que todo teste faz primeiro:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/status | jq
{
  "value": {
    "ready": true,
    "message": "The server is ready to accept new connections",
    "build": {
      "version": "3.8.0"
    }
  }
}
```

`ready: true` e a versão: o servidor está de pé e disposto a iniciar uma sessão. Ele não diz que há
um aparelho conectado, e nem poderia: o servidor só fica sabendo para qual aparelho é uma sessão
quando a sessão pede.
