---
title: A command in Rust
version: 1
---


**Lesson 11 gave the page one door to the computer, `exportPlan`, and Tauri needs the same door, written
in Rust.** A Tauri **command** is a Rust function marked `#[tauri::command]`: the page calls it by name
with `invoke`, Tauri turns the arguments from JSON into Rust values and the answer back into JSON, and
nothing the page sends reaches the computer except through a command somebody wrote. `tauri init` left a
`src-tauri/src/lib.rs` with a log plugin in it and nothing else; this is the planner's, whole:

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

Read it in three parts, top to bottom.

**`write_export` is ordinary Rust**, and it is where the rules are, as in lesson 11: the text must parse as
a JSON object and stay under a million bytes, or it is refused with `"not a plan"`. It takes the folder as
an argument instead of finding it, which is what lets a test call it with no window and no app.

**`export_plan` is the command**, and it is two lines because the work is elsewhere. It asks Tauri for the
app's data folder, `app_data_dir()`, which is named after the identifier of the previous section: on Linux
`~/.local/share/com.example.studyplanner`. A `Result` coming back as `Err` reaches the page as a rejected
promise with the message in it, so a refusal is something the page can show.

**`run` is the template's**, with one line added: `invoke_handler(tauri::generate_handler![export_plan])`
is the list of commands the page may call, and a command missing from it answers the page with an error
naming it. The two tests at the bottom run with `cargo test`, inside `src-tauri`:

```
ana@dev:~/planner/src-tauri$ cargo test --lib 2>&1 | tail -n 6
running 2 tests
test tests::anything_but_a_plan_is_refused ... ok
test tests::an_export_is_written_and_read_back ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

## The page's side

`src/device.ts` gains one import and one line, beside lesson 11's, so the same build of the planner
exports through Electron, through Tauri, or through Capacitor on a phone, depending on where it runs:

```typescript
import { invoke, isTauri } from "@tauri-apps/api/core";
```

```typescript
  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;
  if (isTauri()) return `exported to ${await invoke<string>("export_plan", { text: JSON.stringify(plan) })}`;
```

`isTauri()` is true only inside a Tauri window, in the same way `window.desktop` exists only inside
lesson 11's. **The page still cannot open a file**: there is no Node in it and no `fs`, and `invoke` can
name only the commands in that list.

## Capabilities

Plugins are the other way a page reaches the system, and they are where Tauri asks for permission in
writing. `capabilities/default.json` is what `tauri init` wrote:

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

**A capability grants a list of permissions to a list of windows.** `core:default` is Tauri's own basic
set, for things like the window's title and events; a plugin that reads files or opens a dialog adds
nothing until its permission is named here, such as `fs:allow-read-text-file`, and then only for the
windows listed. The planner's own command needs no line, because the app's own commands are allowed
once they are in `invoke_handler`; the list there is its permission.

One line of `tauri.conf.json` deserves a look before anything ships: `"csp": null`, which means the
template set no Content-Security-Policy of its own. It is the same row as lesson 11's checklist, and the
same string, the policy that lesson wrote for `index.html`, can go under `app.security.csp` instead, where
Tauri adds it to every page it serves. As in lesson 11, it was not added to the planner here.
