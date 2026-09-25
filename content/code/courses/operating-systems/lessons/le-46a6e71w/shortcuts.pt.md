---
title: Os atalhos que valem nos três
version: 1
---

Alguns atalhos economizam mais tempo no suporte do que quaisquer outros, porque funcionam no computador
de um estranho sem precisar achar nada antes.

| para | Windows | macOS | Ubuntu (GNOME) |
|---|---|---|---|
| buscar e abrir qualquer coisa | **Win**, digitar | **Cmd-Espaço**, digitar | **Super**, digitar |
| alternar entre apps | **Alt+Tab** | **Cmd-Tab** | **Alt+Tab** |
| bloquear a tela | **Win+L** | **Ctrl-Cmd-Q** | **Super+L** |
| capturar uma área da tela | **Win+Shift+S** | **Cmd-Shift-4** | **Print Screen** |
| parar um app travado | **Ctrl+Shift+Esc** | **Cmd-Option-Esc** | Monitor do sistema |
| abrir o gerenciador de arquivos | **Win+E** | Finder no Dock | **Super**, "Arquivos" |
| digitar um caminho nele | **Alt+D** | **Cmd-Shift-G** | **Ctrl+L** |
| mostrar arquivos ocultos | *Exibir > Mostrar* | **Cmd-Shift-.** | **Ctrl+H** |
| abrir as configurações | **Win+I** | **Cmd-Espaço**, "Ajustes" | **Super**, "Configurações" |

**Bloqueie a tela toda vez que sair de uma mesa**, inclusive a de outra pessoa em que você está
trabalhando. É o hábito de segurança mais barato que existe, e o que as pessoas mais pulam.

## Pelo terminal

Cada sistema também abre o gerenciador de arquivos ou as configurações pela linha de comando, o que
ajuda quando você já está numa:

```sh
explorer .              # Windows: File Explorer in the current folder
start ms-settings:      # Windows: the Settings app
open .                  # macOS: Finder in the current folder
open -a "System Settings"
xdg-open .              # Linux desktop: the default file manager here
```

**Nenhum destes foi rodado para esta aula.** A última linha precisa de um desktop, e o servidor da aula
3 não tem nenhum: num servidor, o `xdg-open` não tem o que abrir.
