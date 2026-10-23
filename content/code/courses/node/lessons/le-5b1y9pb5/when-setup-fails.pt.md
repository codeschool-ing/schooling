---
title: Quando a instalação falha
version: 1
---

Instalar uma linguagem é onde muita gente para, diante de uma mensagem de erro sobre algo que ainda
não aprendeu. Estas são as falhas que acontecem com esta instalação, com o que cada uma significa e
a transcrição dela acontecendo.

## `node: command not found`

Você viu esta de propósito na seção anterior. Num terminal seu a mensagem pode ser mais longa, e no
Ubuntu ela pode sugerir `sudo apt install nodejs`. Não aceite a sugestão: esse é o segundo Node da
seção abaixo. O shell decide o `PATH` quando abre, e `~/.local/bin` só está nele se a pasta já
existia naquela hora. **Abra um terminal novo.** Se um terminal novo continuar dizendo isso,
`ls ~/.local/bin` deve listar `node`, `npm` e `npx`; se não listar nada, a linha do `ln -s` não
rodou. No Mac a pasta não está no `PATH` de jeito nenhum até que
`export PATH="$HOME/.local/bin:$PATH"` seja acrescentado ao `~/.zprofile`.

## O processador errado

Um arquivo para o processador errado se descompacta sem reclamar e se recusa a rodar. Este é o build
`arm64` descompactado num computador `x86_64`:

```
ana@dev:~$ mkdir ~/wrong && cd ~/wrong
ana@dev:~/wrong$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~/wrong$ tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1
ana@dev:~/wrong$ ./bin/node --version
bash: line 9: ./bin/node: cannot execute binary file: Exec format error
```

**`Exec format error` significa que o programa é para outro processador.** Apague a pasta, confira
o `uname -m` de novo e pegue o outro arquivo. Um Mac com chip da Apple e muitos notebooks Windows
recentes com Snapdragon são `arm64`; a maioria dos outros computadores é `x86_64`.

## Dois Nodes no mesmo `PATH`

O Ubuntu tem um Node próprio no seu repositório, e instalá-lo, ou instalar um programa que depende
dele, põe um segundo `node` em `/usr/bin`. Esta máquina estava com o pacote `nodejs` do Ubuntu
instalado ao lado do Node do curso:

```
ana@dev:~$ which -a node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ /usr/bin/node --version
v18.19.1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O shell procurando o comando node. Ele tenta as pastas do PATH da esquerda para a direita: ~/.local/bin, que tem um link para o Node 22 do curso, depois /usr/sbin, /usr/bin, que tem o Node 18 do Ubuntu, /sbin e /bin. Ele para na primeira pasta que tem um node, então quem responde é o Node 22.\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$ node --version</text><rect x=\"20\" y=\"50\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">~/.local/bin</text><text x=\"95.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">node → v22</text><rect x=\"182\" y=\"50\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"242.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/usr/sbin</text><rect x=\"314\" y=\"50\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"374.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/usr/bin</text><text x=\"374.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">node: v18</text><rect x=\"446\" y=\"50\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/sbin</text><rect x=\"578\" y=\"50\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/bin</text><text x=\"638.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">= /usr/bin</text><line x1=\"20\" y1=\"145\" x2=\"700\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,145.0 692.6,148.1 692.6,141.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a ordem em que o shell as tenta: o PATH, da esquerda para a direita</text><text x=\"95\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">primeiro achado: para aqui</text></svg>", "caption": "Dois Nodes num PATH: decide a primeira pasta que tem um, e o outro nunca é consultado."}
```

`which -a` lista todo `node` que estiver no `PATH`, na ordem em que o shell os tenta. **O primeiro
vence**, e aqui ele ainda é o seu, porque o `~/.profile` do Ubuntu põe `~/.local/bin` na frente.
`/usr/bin/node` e `/bin/node` são o mesmo arquivo, já que `/bin` é um link para `/usr/bin` no
Ubuntu, e ele é o Node 18, quatro versões principais atrás. Um script que chama `/usr/bin/node` pelo
caminho completo, ou um terminal que não lê o `~/.profile`, pega esse. Se `node --version` imprimir
qualquer coisa que não seja 22, `which -a node` diz com qual você está falando; `sudo apt remove
nodejs` remove o do Ubuntu.

## `npm install -g` diz `EACCES`

Nada neste curso instala algo globalmente, então você não deve encontrar este erro. Você vai
encontrar o conselho de resolvê-lo com `sudo npm install -g`, e ele está errado: roda os scripts de
instalação de um pacote como root, e a aula 21 do javascript mostrou que isso é código que outra
pessoa escreveu. Com o Node no seu diretório home, como aqui, o `-g` escreve em `~/.local/node` e
não precisa de `sudo` nenhum.

## O download falha

O `curl` imprimindo `Could not resolve host` significa que o computador não tem DNS; dentro de uma
máquina virtual isso costuma ser uma VPN no hospedeiro atrapalhando. Uma mensagem sobre certificado
significa que algo entre você e a internet está inspecionando a conexão, como fazem algumas redes de
empresa e de escola. **Nunca responda a isso desligando a verificação de certificado.** Peça o
certificado a quem cuida da rede, ou instale de uma rede que não faça isso.

## E quando nada mais funciona

Apague e faça de novo. `rm -rf ~/.local/node ~/.local/bin/node ~/.local/bin/npm ~/.local/bin/npx`
remove este Node por completo, e a seção anterior o põe de volta em cerca de um minuto. Parece
desistir, e é o que quem faz isso profissionalmente faz com uma máquina cujo estado ninguém mais
consegue explicar.
