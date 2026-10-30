---
title: Seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e esta seção o prepara.** Você precisa de três
coisas: **Node.js 22**, que roda o TypeScript do curso; **um kit de desenvolvimento Java**, para as
ferramentas de chave que a assinatura Android usa; e **as ferramentas de build de linha de comando
do Android**, que assinam e conferem um pacote sem o Android Studio. Uma pasta, `~/planner`, guarda
os programas do curso. Nada disso precisa de celular ou de emulador.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | as ferramentas no computador que você já usa | cerca de 1 GB de disco: 205 MB para o Node.js, 330 MB para o JDK, 450 MB para as ferramentas Android | batem como impressas no Linux; perto disso no Windows e no macOS |
| uma máquina virtual | Ubuntu Server 24.04, separado do seu sistema | 5 GB de disco ou mais, e 2 GB de memória enquanto roda | batem como impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma franquia mensal | perto, não exatas |

**Instale no computador que você usa.** O Node e as ferramentas Android vão para pastas no seu
diretório pessoal e não mexem em mais nada. No **Linux** os comandos abaixo funcionam como
impressos. No **Windows**, todo comando é digitado no WSL, o Linux que vem com o Windows:
`wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, uma reinicialização, e
então o Ubuntu no menu Iniciar. Num **Mac**, pegue o Node.js 22 em nodejs.org, um JDK 21 na
Adoptium (o build Temurin) e o zip para macOS das ferramentas de linha de comando do Android; o
resto é digitado no app Terminal. Os caminhos de Windows e de Mac não foram rodados para este
curso, então um caminho numa transcrição pode ser diferente do seu.

**Uma máquina virtual** é o mesmo passo a passo do Linux dentro de uma máquina própria: VirtualBox
no Windows ou no Linux, UTM num Mac com chip Apple, e Ubuntu Server 24.04 LTS como convidado. Nada
aqui abre uma janela, então um servidor sem área de trabalho basta.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal numa aba do navegador. O GitHub
dá às contas pessoais uma franquia mensal de horas e cobra o que passar dela, em termos que ele
define e pode mudar. Esse caminho não foi rodado para este curso.

## Node.js e o JDK

O curso `javascript` instala o Node.js na lição 1, e este curso usa essa instalação: versão
22.22.0, de nodejs.org, em `~/.local/node`. Se você fez `kotlin` ou `android-apps`, já tem o JDK;
caso contrário, o pacote do Ubuntu é o usado aqui:

```sh
sudo apt install openjdk-21-jdk-headless unzip
```

## As ferramentas de linha de comando do Android

O Google publica as ferramentas como um zip. Descompacte em `~/android`, com o nome de pasta que
as ferramentas esperam, e deixe o `sdkmanager` delas buscar os dois pacotes que este curso usa: as
build tools, que trazem `apksigner`, `zipalign` e `aapt2`, e uma plataforma, que o `aapt2` precisa
ler. A última linha baixa o `bundletool`, o programa que o próprio Google Play usa para transformar
um app bundle em APKs:

```sh
mkdir -p ~/android/cmdline-tools && cd ~/android/cmdline-tools
curl -fLO https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
unzip -q commandlinetools-linux-13114758_latest.zip && mv cmdline-tools latest
~/android/cmdline-tools/latest/bin/sdkmanager --licenses
~/android/cmdline-tools/latest/bin/sdkmanager "build-tools;36.0.0" "platforms;android-36"
curl -fL -o ~/android/bundletool.jar \
  https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar
```

`--licenses` mostra os termos de licença do Google e espera que você digite `y` para cada um. Depois
acrescente duas linhas ao fim do `~/.profile`, para que todo terminal novo encontre as ferramentas,
e abra um terminal novo:

```sh
export ANDROID_HOME="$HOME/android"
PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/36.0.0:$PATH"
```

Agora peça a cada ferramenta que responda:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@dev:~$ apksigner --version
0.9
ana@dev:~$ java -jar ~/android/bundletool.jar version
1.18.3
ana@dev:~$ sdkmanager --list_installed
Installed packages:
  Path                 | Version | Description                | Location            
  -------              | ------- | -------                    | -------             
  build-tools;36.0.0   | 36.0.0  | Android SDK Build-Tools 36 | build-tools/36.0.0  
  platforms;android-36 | 2       | Android SDK Platform 36    | platforms/android-36
```

O `apksigner` informa a versão dele mesmo, 0.9, e não a 36.0.0 das build tools; as duas estão
certas.

## A pasta do planner

O exemplo do curso é um **planner de estudos**, o app que a trilha `frontend` constrói e que os
cursos de plataforma constroem de novo num celular: a pessoa lista os cursos, adiciona sessões de
estudo com data e duração, marca as que fez e vê o total da semana. Aqui você o publica, então o
código dele importa menos do que tudo em volta. Crie a pasta e dê a ela um `package.json`. O
`private` impede o npm de oferecer publicá-la, e o `"type": "module"` deixa todo arquivo usar
`import`. Salve isto como `package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

Salve isto como `check.ts`. Ele procura a biblioteca de banco de dados que as lições 16 e 17 usam,
e as duas ferramentas de assinatura:

```typescript
// check.ts: does every tool this course uses answer?
import Database from "better-sqlite3";
import { execFileSync } from "node:child_process";

const db = new Database(":memory:");
const row = db.prepare("select sqlite_version() as version").get() as { version: string };
console.log("node     ", process.version);
console.log("sqlite   ", row.version);
for (const [name, args] of [["keytool", ["-help"]], ["apksigner", ["--version"]]] as const) {
  try {
    execFileSync(name, args, { stdio: "ignore" });
    console.log(name.padEnd(9), "answers");
  } catch {
    console.log(name.padEnd(9), "MISSING");
  }
}
```

Instale a biblioteca com `-E`, que grava a versão exata no `package.json` em vez de uma faixa, e
rode a checagem. O Node 22 roda um arquivo `.ts` direto, removendo as anotações de tipo, então não
há passo de build:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 1s
ana@dev:~/planner$ node check.ts
node      v22.22.0
sqlite    3.53.4
keytool   answers
apksigner answers
```
