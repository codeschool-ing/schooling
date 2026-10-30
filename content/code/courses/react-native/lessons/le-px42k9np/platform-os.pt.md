---
title: Perguntando qual é a plataforma
version: 1
---

**O `Platform.OS` diz em que plataforma o código está rodando**: `"ios"`, `"android"` ou `"web"`, e algumas
outras para plataformas fora deste curso. É uma constante durante a vida do app, então lê-la em qualquer
lugar não custa nada, e um desvio por ela é JavaScript comum:

```tsx
import { Platform } from "react-native";

const label = Platform.OS === "ios" ? "Done" : "Save";
```

O `Platform.Version` acrescenta a versão do sistema operacional: o nível de API do Android como número, 36 no
Android 16, ou a versão do iOS como string, como `"18.2"`. Código que depende de um recurso que um sistema
mais novo trouxe confere a versão, o que no Android é comum a ponto de a comparação ter um formato:

```tsx
if (Platform.OS === "android" && Platform.Version >= 33) {
  // Android 13 and later ask for permission before showing notifications: lesson 16
}
```

## Use pouco

**Cada desvio por plataforma é um lugar onde os dois apps diferem, e cada um precisa ser testado duas
vezes.** Quase todo o planner não tem nenhum: as regras, a lista, a barra e as cores são as mesmas nos dois.
Os lugares que diferem com razão são poucos, e são o assunto do resto desta aula: como algo aparece onde as
plataformas desenham diferente, como algo se comporta onde as convenções delas diferem, e uma API que existe
numa e não na outra.

Um desvio que existe só porque algo ficou errado num celular merece um segundo olhar antes de ficar. Muitas
vezes é um leiaute que dependia de um padrão que a outra plataforma não compartilha, e definir o valor
explicitamente conserta as duas sem desvio nenhum.

## A web também é uma plataforma

O build web do planner responde `"web"`. Isso importa de dois jeitos. Um desvio escrito como `Platform.OS ===
"ios" ? a : b` manda a web pelo caminho do Android, o que pode ou não estar certo; e uma biblioteca que
funciona nos dois celulares pode não funcionar num navegador. O `Platform.select` da próxima seção tem um
`default` exatamente para isso, e o planner o usa.
