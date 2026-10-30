---
title: Preferences, para um recarregamento guardar o plano
version: 1
---

**A aula 1 terminou com um plano que esquecia cada mudança ao recarregar.** Agora o `savePlan` roda
depois de cada uma, e o `loadPlan` roda antes de o arquivo JSON ser buscado, então o arquivo só fornece
o plano na primeiríssima vez. Marque como feita a sessão de espanhol de 22 de outubro, recarregue, e
olhe o que o navegador guardou:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Spanish A2' --click 'Mark done' --reload --eval 'Object.keys(localStorage)' --eval 'localStorage.length'
console.debug: [vite] connecting...
console.debug: [vite] connected.
console.debug: [vite] connecting...
console.debug: [vite] connected.
Object.keys(localStorage) = CapacitorStorage.plan
localStorage.length = 1
- main:
  - heading "Study planner" [level=1]
  - paragraph: "This week: 105 of 125 minutes done"
  - list:
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
  - button "Export plan"
  - button "Where am I?"
  - status
```

**A semana agora diz 105 de 125 depois de recarregar**, onde antes dizia 75: a sessão marcada foi
salva, e a página carregou o plano salvo em vez do `courses.json`. As duas linhas `--eval` mostram para
onde ele foi na web, uma chave no `localStorage`, chamada `CapacitorStorage.plan`.

## Por que não o `localStorage` direto

Na web, o Preferences é uma camada fina sobre o `localStorage`, então é justo perguntar o que ele
acrescenta. A resposta está no celular. **Um sistema móvel pode limpar o `localStorage` de uma
WebView**, que ele trata quase como um cache, e a própria documentação do plugin diz isso nas primeiras
linhas. No iOS o Preferences escreve no `UserDefaults` e no Android no `SharedPreferences`, os
armazéns que cada sistema mantém para as configurações de um app e nunca limpa pelas costas dele. A
mesma chamada, três armazéns, e só um deles pode sumir.

**O Preferences é para valores pequenos**, configurações e um plano de algumas centenas de caracteres.
Ele escreve o valor inteiro toda vez e o lê inteiro, então uma lista que cresce para milhares de
sessões pertence a um arquivo, a próxima seção, ou a um banco de dados: os plugins da comunidade para
SQLite são a escolha comum, e nenhum é oficial.

## Duas regras que vale guardar

- **Salve depois da mudança, não antes da tela.** O `change()` do `main.ts` redesenha na hora e salva
  em segundo plano, então uma escrita lenta nunca segura um toque. Se o salvamento falhar, a linha de
  status diz isso, em vez de a mudança simplesmente não sobreviver em silêncio.
- **Ponha versão no que você guarda.** No dia em que `Session` ganhar um campo, um plano salvo pelo app
  antigo volta sem ele. Uma chave `version` ao lado do plano, conferida no `loadPlan`, é o que deixa um
  lançamento seguinte converter um plano antigo em vez de quebrar nele. O planner ainda não precisa de
  uma; o seu app pode precisar.
