---
title: Um comando em Rust
version: 1
---

**A aula 11 deu à página uma porta para o computador, `exportPlan`, e o Tauri precisa da mesma porta,
escrita em Rust.** Um **comando** do Tauri é uma função Rust marcada com `#[tauri::command]`: a página a
chama pelo nome com `invoke`, o Tauri converte os argumentos de JSON em valores Rust e a resposta de volta
em JSON, e nada do que a página manda chega ao computador a não ser por um comando que alguém escreveu. O
`tauri init` deixou um `src-tauri/src/lib.rs` com um plugin de log e mais nada; este é o do planner,
inteiro:

```
// src-tauri/src/lib.rs: the Rust core. Like Electron's main process, it owns the window and the files.
use std::fs;
use std::path::{Path, PathBuf};
use tauri::Manager;

/// Write an export of the plan into `dir`, and say where it went. Anything that is not
/// a JSON object, or is larger than a plan could be, is refused.
pub fn write_export(dir: &Path, text: &str) -> Result<PathBuf, String> {
  let is_object = matches!(serde_json::from_str(text), Ok(serde_json::Value::Object(_)));
  if text.len() > 1_000_000 || !is_object {
    return Err("not a plan".into());
  }
  fs::create_dir_all(dir).map_err(|e| e.to_string())?;
  let file = dir.join("planner-export.json");
  fs::write(&file, text).map_err(|e| e.to_string())?;
  Ok(file)
}

/// The one command the page may call, as `invoke("export_plan", { text })`.
#[tauri::command]
fn export_plan(app: tauri::AppHandle, text: String) -> Result<String, String> {
  let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
  write_export(&dir, &text).map(|file| file.display().to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      Ok(())
    })
    .invoke_handler(tauri::generate_handler![export_plan])
    .run(tauri::generate_context!())
    .expect("error while building tauri application");
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn an_export_is_written_and_read_back() {
    let dir = std::env::temp_dir().join("planner-export-test");
    let plan = r#"{"courses":[],"sessions":[]}"#;
    let file = write_export(&dir, plan).unwrap();
    assert_eq!(fs::read_to_string(file).unwrap(), plan);
  }

  #[test]
  fn anything_but_a_plan_is_refused() {
    let dir = std::env::temp_dir().join("planner-export-test");
    assert_eq!(write_export(&dir, "123").unwrap_err(), "not a plan");
    assert_eq!(write_export(&dir, "[1, 2]").unwrap_err(), "not a plan");
  }
}
```

Leia em três partes, de cima para baixo.

**`write_export` é Rust comum**, e é onde ficam as regras, como na aula 11: o texto precisa ser um objeto
JSON válido e ficar abaixo de um milhão de bytes, ou é recusado com `"not a plan"`. Ela recebe a pasta como
argumento em vez de encontrá-la, e é isso que permite a um teste chamá-la sem janela e sem app.

**`export_plan` é o comando**, e tem duas linhas porque o trabalho está em outro lugar. Ele pede ao Tauri a
pasta de dados do app, `app_data_dir()`, que leva o nome do identificador da seção anterior: no Linux,
`~/.local/share/com.example.studyplanner`. Um `Result` que volta como `Err` chega à página como uma promise
rejeitada com a mensagem dentro, então uma recusa é algo que a página pode mostrar.

**`run` é o do modelo**, com uma linha a mais: `invoke_handler(tauri::generate_handler![export_plan])` é a
lista de comandos que a página pode chamar, e um comando que falta nela responde à página com um erro que o
nomeia. Os dois testes no fim rodam com `cargo test`, dentro de `src-tauri`:

```
ana@dev:~/planner/src-tauri$ cargo test --lib 2>&1 | tail -n 6
running 2 tests
test tests::anything_but_a_plan_is_refused ... ok
test tests::an_export_is_written_and_read_back ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

## O lado da página

O `src/device.ts` ganha um import e uma linha, ao lado das da aula 11, então o mesmo build do planner
exporta pelo Electron, pelo Tauri ou pelo Capacitor num celular, conforme onde roda:

```typescript
import { invoke, isTauri } from "@tauri-apps/api/core";
```

```typescript
  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;
  if (isTauri()) return `exported to ${await invoke<string>("export_plan", { text: JSON.stringify(plan) })}`;
```

`isTauri()` só é verdadeiro dentro de uma janela do Tauri, do mesmo jeito que o `window.desktop` só existe
dentro da janela da aula 11. **A página continua sem poder abrir um arquivo**: não há Node nela nem `fs`, e o
`invoke` só consegue nomear os comandos daquela lista.

## Capabilities

Plugins são o outro caminho de uma página até o sistema, e é neles que o Tauri pede permissão por escrito.
O `capabilities/default.json` é o que o `tauri init` escreveu:

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "enables the default permissions",
  "windows": [
    "main"
  ],
  "permissions": [
    "core:default"
  ]
}
```

**Uma capability concede uma lista de permissões a uma lista de janelas.** `core:default` é o conjunto básico
do próprio Tauri, para coisas como o título da janela e os eventos; um plugin que lê arquivos ou abre um
diálogo não acrescenta nada até a permissão dele ser citada aqui, como `fs:allow-read-text-file`, e aí só
para as janelas listadas. O comando do próprio planner não precisa de linha, porque os comandos do app são
permitidos quando estão no `invoke_handler`; a lista ali é a permissão dele.

Uma linha do `tauri.conf.json` merece um olhar antes de qualquer coisa ser distribuída: `"csp": null`, que
quer dizer que o modelo não definiu uma Content-Security-Policy própria. É a mesma linha do checklist da
aula 11, e a mesma string, a política que aquela aula escreveu para o `index.html`, pode ir em
`app.security.csp`, onde o Tauri a acrescenta a toda página que serve. Como na aula 11, ela não foi
acrescentada ao planner aqui.
