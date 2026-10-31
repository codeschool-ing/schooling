---
title: Cada tela um endereço
version: 1
---

**Um deep link é um endereço que abre uma tela específica**: `planner://course/guitar` vindo de uma
notificação, de outro app ou de uma página web, ou `https://…/course/guitar` num navegador. O React
Navigation transforma endereços em estado de navegação, e vice-versa, com o objeto `linking` no fim do
`src/navigation.tsx`:

| parte | significado |
|---|---|
| `prefixes: ["planner://"]` | o esquema que o celular entrega a este app |
| `Courses: ""` | o caminho vazio é a aba *Courses* |
| `Week: "week"` | `/week` é a aba *This week* |
| `Course: "course/:id"` | `/course/guitar` é a tela Course, com `id` valendo `guitar` |

O segundo teste da seção anterior perguntou ao `getStateFromPath` do próprio React Navigation o que
`course/statistics` quer dizer, e recebeu a rota Course com `{ id: "statistics" }`: um endereço conferido sem
tela nenhuma.

## Abrindo endereços no navegador

Na web, a barra de endereço é o link. **Um app de página única precisa de um servidor que responda a todo
caminho com o `index.html`**, para que `/course/guitar` carregue o app, que então lê o caminho. O `npx expo
serve` responde a caminhos desconhecidos com *404*, que foi o que a primeira gravação desta seção recebeu,
então a exportação é servida aqui com o `serve`, um pequeno servidor estático cuja opção `--single` faz
exatamente isso:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/guitar?today=2026-10-21'
- heading "Guitar" [level=1]
- heading "2026-10-21" [level=2]
- text: 20 min
- heading "2026-10-28" [level=2]
- text: 20 min
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/week?today=2026-10-21'
- heading "This week" [level=1]
- heading "2026-10-19" [level=2]
- text: 30 min, done
- heading "2026-10-20" [level=2]
- text: 45 min, done
- heading "2026-10-21" [level=2]
- text: 20 min
- heading "2026-10-22" [level=2]
- text: 30 min
- tablist:
  - tab "Courses"
  - tab "This week" [selected]
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/chemistry'
- heading "Not found" [level=1]
- text: There is no course called chemistry.
```

**Três endereços, três telas, nenhum toque.** O `/course/guitar` abriu o curso, com o título no cabeçalho como
título de nível 1 e os dias embaixo. O `/week` abriu a segunda aba, marcada como `selected`. O
`/course/chemistry` citou um curso que não existe e recebeu a resposta simples da tela, com *Not found* como
título.

O curso aberto pelo endereço não tem link de voltar: não havia nada embaixo dele. O React Navigation pode ser
instruído a pôr as abas por baixo de uma tela aberta por deep link, o que costuma estar certo para um app
aberto por uma notificação, e a documentação dele chama isso de `initialRouteName` na configuração de linking.

## Num celular

O esquema vem do `app.json`: o Expo usa o campo `"scheme"`, e o modelo ainda não tem um, então acrescente
`"scheme": "planner"` dentro de `"expo"`. O prebuild então escreve o intent filter no manifesto Android e o
tipo de URL no `Info.plist`. *Abrir `planner://course/guitar` num aparelho não foi rodado para este curso.* Com
o development build instalado, `adb shell am start -a android.intent.action.VIEW -d planner://course/guitar`
o abre no Android, e `npx uri-scheme open planner://course/guitar --ios` no simulador de iOS.

**Um esquema próprio não é um link seguro.** Qualquer app pode reivindicar `planner://`. Links que precisam
chegar só ao seu app, vindos de e-mail ou da web, são os Android App Links e os iOS Universal Links, que
amarram um endereço `https` ao app por meio de um arquivo no seu próprio domínio; o `mobile-delivery` trata
de publicá-los.
