---
title: Guardando a foto nos arquivos do próprio app
version: 1
---

**Todo app tem pastas próprias, que nenhum outro app consegue ler**, e o `expo-file-system` chama as duas
que importam de `Paths.cache` e `Paths.document`. O cache é onde o seletor deixa a cópia dele, e o sistema
pode esvaziá-lo sempre que o celular precisa de espaço. A pasta de documentos fica até o app ser
desinstalado, e no iOS entra no backup do celular. Uma foto que a pessoa escolheu guardar pertence a ela.

Salve o `src/keepPhoto.ts`:

```ts
// src/keepPhoto.ts: copy a picked photo out of the cache, into the app's own documents, where the
// system does not clear it. One photo per course: a new one replaces the old.
import { Directory, File, Paths } from "expo-file-system";

export function keepPhoto(uri: string, course: string): string {
  const notes = new Directory(Paths.document, "notes");
  if (!notes.exists) notes.create();
  const kept = new File(notes, `${course}.jpg`);
  if (kept.exists) kept.delete();
  new File(uri).copy(kept);
  return kept.uri;
}
```

`Directory` e `File` são referências a caminhos, e criar uma não toca em nada no disco. `exists`,
`create`, `delete` e `copy` fazem o trabalho, e são síncronos: a cópia de uma foto é rápida o bastante para
acontecer dentro do toque que a causou. O arquivo leva o nome do curso, então uma segunda foto substitui a
primeira em vez de se acumular.

## E na web

Um navegador não tem uma pasta de documentos onde uma página possa escrever, e o `expo-file-system` não
roda lá. Na web o seletor devolve um endereço `blob:`, que aponta para o arquivo na memória do navegador
enquanto a página estiver aberta. Os arquivos por plataforma da aula 6 resolvem: ao lado do
`keepPhoto.ts`, salve o `src/keepPhoto.web.ts`, que o Metro usa no lugar dele quando constrói para a web:

```ts
// src/keepPhoto.web.ts: a browser has no documents folder to copy into. The picked photo is a
// blob: address that lasts as long as the page, and that is what the web build keeps.
export function keepPhoto(uri: string, _course: string): string {
  return uri;
}
```

**Então o build web não guarda nada depois de recarregar**, o que é honesto sobre o que um navegador
consegue fazer. *A versão do celular foi conferida pelo compilador de TypeScript, contra os tipos que o
`expo-file-system` 58 publica, e não foi executada: não há celular nas gravações deste curso.* O que um
teste consegue conferir é o que a tela faz com o endereço que recebe de volta, e isso é a próxima seção.
