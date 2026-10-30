---
title: A caixa de areia, e o que mora nela
version: 1
---

**Todo app num celular ganha uma pasta própria, e nada fora dela é dele para ler ou escrever.**
Essa pasta é a **caixa de areia** (*sandbox*). O sistema operacional a cria quando o app é
instalado, entrega a um ID de usuário e a apaga quando o app é removido. Tudo o que este curso
guarda, um banco de dados, uma preferência, uma imagem baixada, um arquivo esperando para ser
enviado, mora dentro dela.

Uma imagem comum é a de que a caixa de areia é um balde só. Não é. Cada plataforma a divide em
alguns lugares, e **o lugar onde um arquivo fica decide três coisas sobre ele**: se o backup o
leva, se o sistema pode apagá-lo para liberar espaço e se a pessoa consegue vê-lo.

## Android

O armazenamento privado de um app fica em `/data/data/<package>/`, a mesma pasta que as versões
mais novas também alcançam como `/data/user/0/<package>/`. O app nunca digita esse caminho; ele
pede cada parte pelo nome.

| pasta | pedida com | o que vai nela |
|---|---|---|
| `files/` | `Context.getFilesDir()` | arquivos que o app criou e de que vai precisar de novo |
| `databases/` | `Context.getDatabasePath()` | arquivos SQLite, que o Room põe aqui |
| `shared_prefs/` | `SharedPreferences` | configurações pequenas, em XML |
| `cache/` | `Context.getCacheDir()` | o que dá para buscar de novo; o sistema pode apagar quando falta espaço |
| `no_backup/` | `Context.getNoBackupFilesDir()` | arquivos que têm de ficar só neste aparelho |

## iOS

O contêiner de um app iOS tem formato próprio, e os nomes dizem para que serve cada parte.

| pasta | o que vai nela |
|---|---|
| `Documents/` | o que a pessoa criou, e que ela pode ver no app Arquivos se o app permitir |
| `Library/Application Support/` | o que o app precisa e a pessoa nunca manuseia, um banco de dados por exemplo |
| `Library/Preferences/` | a lista de propriedades que o `UserDefaults` grava |
| `Library/Caches/` | o que dá para buscar de novo; o sistema pode esvaziar quando o disco está quase cheio |
| `tmp/` | arquivos de rascunho, que o sistema pode apagar quando o app não está rodando |

## React Native

Um app React Native roda num dos dois sistemas acima, então os arquivos dele caem nas mesmas
pastas. As bibliotecas dão nome a elas: o `expo-file-system`, do Expo, oferece um diretório de
documentos e um de cache, que são `files/` e `cache/` no Android e `Documents/` e `Library/Caches/`
no iOS, e um banco aberto com o `expo-sqlite` vai para onde a plataforma guarda os bancos.

**A regra para levar desta seção é curta: um arquivo vai para onde perdê-lo dói na medida certa.**
Uma sessão de estudo que a pessoa digitou precisa sobreviver a uma reinstalação a partir do
backup, então vai para o banco. A imagem de capa de um curso dá para baixar de novo, então vai
para o cache, e perdê-la custa uma requisição. O resto desta aula mede o que essa escolha faz com
um backup.
