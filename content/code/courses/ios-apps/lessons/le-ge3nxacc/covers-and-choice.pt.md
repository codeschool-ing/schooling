---
title: Telas cheias, e como escolher entre as três
version: 1
---

**Uma tela cheia, o `fullScreenCover`, é uma sheet que ocupa a tela toda e não pode ser puxada para
baixo.** Ela é para um modo do qual a pessoa tem de sair de propósito: uma câmera, um vídeo, uma
apresentação inicial que o app precisa concluída antes de qualquer outra coisa fazer sentido. Ela é
escrita do mesmo jeito que uma sheet, com `fullScreenCover(isPresented:onDismiss:content:)`, e a tela
dentro dela tem de oferecer a sua própria saída, porque não há gesto para recorrer. Nada aqui foi
executado; foi escrito a partir da documentação da Apple para o `fullScreenCover` e das *Human
Interface Guidelines* sobre modalidade.

```swift
.fullScreenCover(isPresented: $timing) {
    StudyTimer(sessionID: session.id)   // has its own "Stop" button that calls dismiss()
}
```

O planner tem uma candidata: um cronômetro que corre enquanto a pessoa estuda uma sessão e a marca como
feita quando ela para. É um modo, não deve se perder num deslizar, e nada atrás dele importa até ele
acabar.

## Qual delas

| a pessoa está… | use | porque |
|---|---|---|
| indo mais fundo no que está olhando: um curso, depois uma sessão | um push, `NavigationLink(value:)` | pertence ao histórico, e voltar desfaz |
| fazendo uma tarefa curta que a traz de volta aqui: acrescentar uma sessão | uma sheet | não é um lugar para onde voltar, e um deslizar ou *Cancel* a abandona |
| num modo que tem de encerrar de propósito: um cronômetro de estudo | uma tela cheia | nada atrás dela é alcançável, e a saída é um botão |
| respondendo uma pergunta: apagar este curso? | um alerta ou um diálogo de confirmação | é uma decisão, não uma tela |

**O teste é o que *voltar* deve fazer.** Se voltar deve levar à tela anterior, é um push. Se a tela é
um desvio que se fecha, é uma sheet ou uma tela cheia, e a diferença entre as duas é se um deslizar
pode abandoná-la. As diretrizes da Apple dizem isso pelo outro lado: apresente de forma modal só quando
a pessoa precisa terminar ou dispensar uma tarefa antes de seguir, e é por isso que o formulário, o
cronômetro e a pergunta são modais e as telas de curso e de sessão não são.

**Apresentação é estado como qualquer outro**, e tem um dono. O `adding` mora na tela de curso, o path
mora no modelo, e uma sheet que o modelo precisasse abrir de outro lugar, uma notificação pedindo para
acrescentar a sessão de amanhã, levaria a sua flag para o modelo ao lado do path, pelo mesmo motivo
pelo qual a seção 04 levou o path.
