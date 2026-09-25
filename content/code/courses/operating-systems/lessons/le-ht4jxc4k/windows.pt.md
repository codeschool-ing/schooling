---
title: Windows: winget, a Store e instaladores
version: 1
---

O Windows tem os três caminhos, e o primeiro a usar é mais novo do que a maioria das pessoas imagina.

O **`winget`**, o *Gerenciador de Pacotes do Windows*, vem com o Windows 11 e faz no Windows o que o apt
faz no Ubuntu: buscar, instalar, listar, atualizar.

```sh
winget search 7zip                          # what the Windows package manager knows
winget install --id 7zip.7zip               # install, with the publisher's installer
winget list                                 # everything installed, from any source
winget upgrade --all                        # every program winget can update
msiexec /i agent.msi /qn                    # an .msi, silently, as a deployment does
```

**Nada disso foi rodado para esta aula.** Duas diferenças em relação ao apt importam:

- A lista do winget é **um catálogo de onde baixar o instalador do próprio fabricante**, com um checksum
  para cada um. Ele roda esse instalador em silêncio. Então um programa instalado pelo winget é igual a
  um instalado à mão, e o `winget upgrade --all` atualiza programas **seja quem for que os instalou**,
  desde que o winget os reconheça.
- **Não há dependências compartilhadas**: cada instalador traz as dele, como a seção 03 disse.

A **Microsoft Store** instala apps por usuário, muitas vezes sem administrador, e os atualiza sozinha.
Em máquinas de escritório gerenciadas por uma organização, ela pode ser restrita a uma lista aprovada.

Os **instaladores** são de dois tipos. Um **`.msi`** é um pacote do *Windows Installer* com formato
padrão, então pode ser instalado em silêncio (`/qn`) e removido de forma limpa, e é o que os
departamentos de TI empurram para muitas máquinas. Um instalador **`.exe`** é o que o fabricante
escreveu, e cada um tem as próprias opções para instalar em silêncio, se tiver.

Os programas instalados vão para **`C:\Program Files`**, ou `Program Files (x86)` para os de 32 bits,
e são removidos em *Configurações > Aplicativos > Aplicativos instalados*. Programas que se instalam na
pasta `AppData` do próprio usuário, como muitos navegadores e apps de chat, não precisam de
administrador, o que é conveniente e é também como software que ninguém aprovou chega aos PCs do
escritório.
