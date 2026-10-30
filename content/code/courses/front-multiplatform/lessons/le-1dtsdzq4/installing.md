---
title: Rust, and the system's libraries
version: 1
---

**Tauri needs two things the planner does not have yet: Rust, and on Linux the development files of the
system's WebView.** Rust comes from **rustup**, its installer, which puts the compiler and Cargo, Rust's
package manager and build tool, in your home folder, the way lesson 1 of `javascript` put Node in
`~/.local`.

The usual line is the one rust-lang.org shows, `curl https://sh.rustup.rs -sSf | sh`, which downloads a
script that downloads the installer and runs it. The recording machine could not reach `sh.rustup.rs`, so
it fetched the installer itself, from the address that script uses, and ran it; both routes end with the
same program:

```
ana@dev:~$ curl -fsSLO https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
ana@dev:~$ chmod +x rustup-init
ana@dev:~$ ./rustup-init -y --profile minimal 2>&1 | grep -E "installed -|is installed"
  stable-x86_64-unknown-linux-gnu installed - rustc 1.99.1 (58cf8f9c3 2026-10-13)
Rust is installed now. Great!
ana@dev:~$ rm rustup-init
```

**A new terminal finds `rustc` and `cargo`**, because the installer added `~/.cargo/bin` to your
`~/.profile`, the same lesson about `PATH` as lesson 1. Rust with its compiler took 816 MB on the
recording machine, as lesson 1 said.

```
ana@dev:~$ rustc --version
rustc 1.99.1 (58cf8f9c3 2026-10-13)
ana@dev:~$ cargo --version
cargo 1.99.1 (5f94df478 2026-08-27)
```

## The system's part

On **Linux**, Tauri compiles against WebKitGTK and its neighbours, and needs their development packages
and a C compiler. Tauri's documentation lists them for Ubuntu as:

```sh
sudo apt install build-essential pkg-config libwebkit2gtk-4.1-dev libxdo-dev libssl-dev \
  libayatana-appindicator3-dev librsvg2-dev file wget
```

On **Windows**, Tauri needs Microsoft's C++ build tools and WebView2, which Windows 11 already has; on
**macOS**, Xcode's command-line tools, from `xcode-select --install`. *Those two paths were not run for
this course; they come from Tauri's own prerequisites page.*

Then the command-line tool and the JavaScript side of the bridge go into the planner, at the versions
this course used, the CLI as a development tool and the API as something the app imports:

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

`tauri init` wrote `src-tauri/`, a Rust project inside the planner. **`tauri.conf.json`** says where the
built site is, `../dist`, which command builds it, and what the window is called; **`Cargo.toml`** is the
Rust project's own `package.json`; **`src/main.rs`** starts the app, and **`src/lib.rs`** is where the
app's Rust lives. `capabilities/` says what the page is allowed to ask for, and the next section but one
explains it.
