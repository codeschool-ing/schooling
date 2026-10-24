---
title: O Rust, e as bibliotecas do sistema
version: 1
---

**O Tauri precisa de duas coisas que o planner ainda não tem: o Rust, e no Linux os arquivos de
desenvolvimento da WebView do sistema.** O Rust vem do **rustup**, o instalador dele, que põe o compilador
e o Cargo, o gerenciador de pacotes e a ferramenta de build do Rust, na sua pasta pessoal, do jeito que a
aula 1 de `javascript` pôs o Node em `~/.local`.

A linha de costume é a que o rust-lang.org mostra, `curl https://sh.rustup.rs -sSf | sh`, que baixa um
script que baixa o instalador e o executa. A máquina de gravação não conseguia acessar `sh.rustup.rs`, então
buscou o próprio instalador, no endereço que esse script usa, e o executou; os dois caminhos terminam no
mesmo programa:

```
ana@dev:~$ curl -fsSLO https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
ana@dev:~$ chmod +x rustup-init
ana@dev:~$ ./rustup-init -y --profile minimal 2>&1 | grep -E "installed -|is installed"
  stable-x86_64-unknown-linux-gnu installed - rustc 1.99.1 (58cf8f9c3 2026-10-13)
Rust is installed now. Great!
ana@dev:~$ rm rustup-init
```

**Um terminal novo encontra o `rustc` e o `cargo`**, porque o instalador acrescentou `~/.cargo/bin` ao seu
`~/.profile`, a mesma lição sobre o `PATH` da aula 1. O Rust com o compilador ocupou 816 MB na máquina de
gravação, como a aula 1 disse.

```
ana@dev:~$ rustc --version
rustc 1.99.1 (58cf8f9c3 2026-10-13)
ana@dev:~$ cargo --version
cargo 1.99.1 (5f94df478 2026-08-27)
```

## A parte do sistema

No **Linux**, o Tauri compila contra o WebKitGTK e os vizinhos dele, e precisa dos pacotes de
desenvolvimento deles e de um compilador C. A documentação do Tauri os lista para o Ubuntu assim:

```sh
sudo apt install build-essential pkg-config libwebkit2gtk-4.1-dev libxdo-dev libssl-dev \
  libayatana-appindicator3-dev librsvg2-dev file wget
```

No **Windows**, o Tauri precisa das ferramentas de build de C++ da Microsoft e do WebView2, que o Windows 11
já tem; no **macOS**, das ferramentas de linha de comando do Xcode, com `xcode-select --install`. *Esses dois
caminhos não foram executados para este curso; eles vêm da própria página de pré-requisitos do Tauri.*

Depois, a ferramenta de linha de comando e o lado JavaScript da ponte entram no planner, nas versões que
este curso usou, a CLI como ferramenta de desenvolvimento e a API como algo que o app importa:

```
ana@dev:~/planner$ npm install -E -D @tauri-apps/cli@2.12.4 > /dev/null
ana@dev:~/planner$ npm install -E @tauri-apps/api@2.12.4 > /dev/null
ana@dev:~/planner$ npx tauri init --ci --app-name planner --window-title "Study planner" --frontend-dist ../dist --dev-url http://localhost:5173 --before-dev-command "npm run dev" --before-build-command "npm run build"
ana@dev:~/planner$ ls src-tauri src-tauri/src
src-tauri:
Cargo.toml
build.rs
capabilities
icons
src
tauri.conf.json

src-tauri/src:
lib.rs
main.rs
```

O `tauri init` escreveu `src-tauri/`, um projeto Rust dentro do planner. O **`tauri.conf.json`** diz onde
está o site gerado, `../dist`, que comando o gera, e como a janela se chama; o **`Cargo.toml`** é o
`package.json` do projeto Rust; o **`src/main.rs`** inicia o app, e o **`src/lib.rs`** é onde mora o Rust do
app. A pasta `capabilities/` diz o que a página tem permissão de pedir, e a seção depois da próxima explica.
