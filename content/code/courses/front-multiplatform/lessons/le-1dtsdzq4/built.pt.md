---
title: Gerado, aberto e medido
version: 1
---

**O `npx tauri build` roda primeiro o `npm run build`, como o `tauri.conf.json` manda, depois compila o
núcleo Rust em modo release e empacota o resultado.** O primeiro build baixa e compila todas as bibliotecas
Rust que o Tauri usa, e levou vários minutos na máquina de gravação; os builds seguintes só compilam o que
mudou. As últimas linhas dele, e depois uma contagem das bibliotecas que o Cargo tinha baixado em
`~/.cargo/registry` até ali:

```
ana@dev:~/planner$ npx tauri build 2>&1 | tail -n 9
        Info Patching /home/ana/planner/src-tauri/target/release/app with bundle type information: rpm
    Bundling planner-0.1.0-1.x86_64.rpm (/home/ana/planner/src-tauri/target/release/bundle/rpm/planner-0.1.0-1.x86_64.rpm)
        Info Patching /home/ana/planner/src-tauri/target/release/app with bundle type information: appimage
    Bundling planner_0.1.0_amd64.AppImage (/home/ana/planner/src-tauri/target/release/bundle/appimage/planner_0.1.0_amd64.AppImage)
    Finished 3 bundles at:
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb (2.85 MiB)
        /home/ana/planner/src-tauri/target/release/bundle/rpm/planner-0.1.0-1.x86_64.rpm (2.86 MiB)
        /home/ana/planner/src-tauri/target/release/bundle/appimage/planner_0.1.0_amd64.AppImage (77.85 MiB)

ana@dev:~/planner$ ls ~/.cargo/registry/src/*/ | wc -l
287
```

**287 bibliotecas é o tamanho do lado Rust**, e quase todas são do Tauri e das bibliotecas em que ele se
apoia; o Rust do próprio planner é o único arquivo da seção anterior. **Três pacotes saíram de um build só**,
porque `"targets": "all"` pede todos os formatos que o Linux tem: um `.deb` para Debian e Ubuntu, um `.rpm`
para o Fedora e os parentes dele, e um **AppImage**, um arquivo único que roda na maioria das distribuições
sem ser instalado. A aula 13 trata desses formatos e do que cada um pede de quem instala. O tamanho do
AppImage chama atenção, e tem um motivo: o `.deb` e o `.rpm` dizem que dependem do WebKitGTK do sistema e
deixam o gerenciador de pacotes instalá-lo, enquanto um AppImage não pode depender de nada, então leva uma
cópia própria.

Enquanto você trabalha, o comando que você roda é o **`npx tauri dev`**: ele inicia o `npm run dev`, abre a
janela no servidor do Vite do `devUrl`, recarrega a página quando você edita o TypeScript, e recompila o Rust
quando um arquivo `.rs` muda. É o lado Tauri do `npm start` da aula 11.

## Do que o programa é feito

O programa que os pacotes levam é `src-tauri/target/release/app`, com o nome do pacote Rust, `app` no
`Cargo.toml`. Ele não contém motor de navegador, e o linker do sistema diz de onde o motor vem:

```
ana@dev:~/planner$ ldd src-tauri/target/release/app | grep -E "webkit|gtk-3" | cut -d" " -f1
	libwebkit2gtk-4.1.so.0
	libgtk-3.so.0
```

**A página é desenhada pela `libwebkit2gtk-4.1`, a biblioteca que a linha de `apt` da seção de instalação pôs
ali**, com o GTK em volta para a janela. Num computador sem WebKitGTK o programa não inicia, e é essa a
dependência que o `.deb` declara. No Windows o mesmo lugar é ocupado pelo WebView2, e no macOS pelo WebKit do
sistema, e nenhum dos dois está no download.

## A janela

A máquina de gravação não tem tela, então a janela abriu no Xvfb, como na aula 11, e a transcrição pergunta à
tela o que ela contém:

```
ana@dev:~/planner$ xvfb-run -a sh -c "src-tauri/target/release/app 2>/dev/null & sleep 5; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1; kill \$!"
Study planner": ("app" "App")  800x600+0+0  +0+0
```

**A janela está lá, com o título que o `tauri.conf.json` deu**, e com 800 por 600 pixels, o tamanho que o
modelo escreveu. O que a máquina de gravação não conseguiu foi olhar dentro dela: o Playwright controla o
Chromium e o Electron, e não tem como entrar numa janela WebKitGTK, então a exportação do planner nunca foi
apertada nesta janela. A metade Rust dela é o que o `cargo test` provou; no seu computador, o `npx tauri dev`
e um clique em **Export** mostram a outra metade, e o caminho que volta fica em
`~/.local/share/com.example.studyplanner`.

## Os tamanhos, lado a lado

```
ana@dev:~/planner$ du -sh src-tauri/target/release/app node_modules/electron/dist
11M	src-tauri/target/release/app
274M	node_modules/electron/dist
```

**O programa Tauri tem 11 MB; só o runtime do Electron, antes de o planner entrar nele, tem 274 MB.** É a
troca da primeira seção em dois números. Os 11 MB levam o núcleo Rust e a `dist/` do planner, comprimida
dentro dele; os 274 MB levam um Chromium inteiro e um Node inteiro, e o mesmo planner por cima. O que o número
pequeno não conta é o próprio WebKitGTK, que já está no computador, e o tempo gasto testando o planner em três
motores diferentes, que fica com você.

O projeto vai para um commit, com o `src-tauri/target`, que guarda o build, deixado de fora pelo `.gitignore`
que o `tauri init` escreveu:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
 M src/device.ts
?? src-tauri/
ana@dev:~/planner$ git add . && git commit -q -m "The planner as a desktop app, with Tauri" && git log --oneline -1
676a8f1 The planner as a desktop app, with Tauri
```
