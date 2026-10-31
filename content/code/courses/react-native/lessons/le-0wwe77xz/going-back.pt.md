---
title: Voltar, que o Android pede a todo app
version: 1
---

**A pilha dá o voltar de graça.** No iOS, o botão de voltar do cabeçalho e um deslizar a partir da borda
esquerda tiram a tela de cima; no Android, a ação de voltar do sistema faz isso, pela barra de navegação ou
por um deslizar a partir de qualquer borda na navegação por gestos. Na web, o botão de voltar do navegador
percorre o mesmo histórico, porque o `NavigationContainer` mantém a barra de endereço em sincronia. Nada no
planner precisou ser escrito para nada disso.

## Quando voltar precisa perguntar antes

A aula 11 acrescenta um formulário para adicionar uma sessão. Voltar de um formulário preenchido pela metade o
descartaria, e quem apertou voltar sem querer perde o que digitou. A resposta do React Navigation é um evento
disparado *antes* de uma tela ser removida, que a tela pode interromper:

```tsx
useEffect(() => {
  return navigation.addListener("beforeRemove", (e) => {
    if (!dirty) return;            // nothing typed: let it go
    e.preventDefault();            // stop the navigation
    Alert.alert("Discard this session?", "", [
      { text: "Keep editing", style: "cancel" },
      { text: "Discard", style: "destructive", onPress: () => navigation.dispatch(e.data.action) },
    ]);
  });
}, [navigation, dirty]);
```

O `beforeRemove` cobre todo jeito de sair, o botão do cabeçalho, o deslizar e o voltar do Android, e é por isso
que ele é melhor do que escutar o `BackHandler` do Android diretamente. O `BackHandler` fica para a tela rara
que não está em navegador nenhum. A aula 11 escreve esse listener de verdade.

## Voltar nem sempre é "a tela anterior"

Numa aba, o voltar do Android volta à primeira aba, e depois sai do app, que é a convenção da plataforma. Numa
tela aberta por uma notificação, talvez não haja tela anterior nenhuma. E depois de entrar numa conta, voltar
não deveria levar ao formulário de entrada. Cada um desses é uma decisão sobre o conteúdo da pilha, tomada com
`navigation.reset` ou escolhendo o que empilhar, e a regra a ter em mente é a da pessoa: **voltar leva de onde
ela veio, ou para fora.**

*O voltar do Android e o deslizar do iOS não foram experimentados num aparelho para este curso*; o histórico do
build web foi, pelo link de voltar que uma tela empilhada mostra no cabeçalho.
