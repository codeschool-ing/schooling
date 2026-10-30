---
title: Filesystem, um arquivo do plano
version: 1
---

**O Filesystem lê e escreve arquivos em pastas que o sistema dá ao app.** O "Export plan" do planner
escreve o plano inteiro como JSON, depois o lê de volta e informa o tamanho, que é o jeito mais curto
de saber que o arquivo está mesmo lá:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Export plan' --wait 300 | tail -n 3
  - button "Export plan"
  - button "Where am I?"
  - status: exported 599 characters to planner-export.json
```

A opção `directory` é a importante, porque o mesmo caminho quer dizer um lugar diferente em cada uma:

| `Directory` | onde fica | quem consegue ver |
|---|---|---|
| `Data` | a pasta de dados privada do app | só o app; some com ele |
| `Cache` | uma pasta que o sistema pode esvaziar | só o app |
| `Documents` | os documentos da pessoa; no iOS, o app Arquivos pode mostrá-la | a pessoa, e outros apps pelo sistema |
| `External`, `ExternalStorage` | o armazenamento compartilhado do Android | outros apps, com permissões que mudam conforme a versão do Android |

**A `Data` não exige permissão em plataforma nenhuma**, e é por isso que o planner a usa. Escrever onde
outros apps conseguem ler é onde as regras de permissão começam, e a própria documentação do plugin
lista, por versão do Android, qual permissão uma pasta exige. A maioria dos apps nunca precisa delas:
para entregar um arquivo à pessoa, o jeito comum é escrevê-lo no `Cache` e abrir a folha de
compartilhamento do sistema com o plugin `@capacitor/share`, que não exige permissão de armazenamento
nenhuma.

## Na web não é uma pasta

No Chromium, a exportação acima foi para o **IndexedDB**, o banco de dados do navegador, num que o
plugin chama de `Disc`. Não existe arquivo nenhum no disco com aquele nome, e nada fora da página
consegue abri-lo. A chamada funcionou, o tamanho estava certo, e isso é tudo o que a web consegue
mostrar: o comportamento que importa num celular, que o arquivo está numa pasta e sobrevive a uma
atualização do app, não fez parte desta execução.
