---
title: Quando o celular está sem rede
version: 1
---

**Um celular fica offline com frequência**: um elevador, um trem, um prédio de paredes grossas, o modo avião. O
padrão do TanStack Query é **pausar** uma query ou uma mutation enquanto está offline e rodá-la quando a
conexão voltar, em vez de falhar na hora. Para isso ele precisa saber se o celular está online, e essa é a
única linha do `src/planState.tsx` fora de todo hook:

```tsx
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));
```

Num navegador, o TanStack Query escuta os próprios eventos online e offline do navegador. Num celular não há
nenhum, então o NetInfo, que pergunta à plataforma, o avisa no lugar.

## O que o terceiro teste mostrou

O último teste da seção anterior define `onlineManager.setOnline(false)` antes de apertar:

- o total mostrou **95** na hora, porque o `onMutate` rodou e escreveu a mudança no cache;
- o `sendDone` **não** tinha sido chamado: a mutation estava pausada, esperando;
- depois do `setOnline(true)`, ele foi chamado exatamente uma vez.

Então uma pessoa num trem marca uma sessão como feita, a vê feita, e a requisição sai quando o trem deixa o
túnel. **Se o app for fechado antes disso, a mudança pausada se perde**, porque ela mora só na memória.
Mantê-la através de um reinício quer dizer escrevê-la no armazenamento, que o TanStack Query oferece pelos
plugins de persistência dele e que o curso `mobile-offline` constrói direito, com uma fila própria e os
conflitos que vêm com uma.

## Dizendo que o celular está offline

Uma mudança que espera em silêncio é melhor do que uma que falha, e pior do que uma que diz que está esperando.
O `onlineManager.isOnline()`, ou o hook `useNetInfo()` do NetInfo, permite a uma tela mostrar uma linha como
*Offline: changes will be sent when you reconnect*, num `status` para um leitor de tela ouvi-la uma vez. O
planner ainda não desenha uma; é o tipo de frase que deveria existir na primeira vez que o app é usado em algum
lugar de verdade.
