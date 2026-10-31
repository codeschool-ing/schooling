---
title: Estilos são objetos
version: 1
---

**Um estilo no React Native é um objeto JavaScript passado à prop `style`**, com nomes que parecem CSS
escrito em camelCase e números sem unidade: `{ fontSize: 17, paddingHorizontal: 16 }`. Não há arquivo de
folha de estilo, nem nome de classe, nem seletor. Cada elemento recebe exatamente o estilo que a própria
prop `style` diz, e nada além.

## StyleSheet.create

Os componentes do planner guardam os estilos no fim do arquivo, numa chamada a `StyleSheet.create`, como o
`CourseRow` vai fazer na última seção:

```tsx
const styles = StyleSheet.create({
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14 },
});
```

O `StyleSheet.create` devolve o mesmo objeto que recebeu, tipado: o TypeScript sabe que `fontWeight` aceita
`"600"` e recusa `"semi-bold"`. Guardar os estilos ali, e não em linha no JSX, é uma convenção de leitura, não
uma regra de desempenho; um objeto em linha funciona do mesmo jeito, e o planner usa objetos em linha para os
um ou dois valores que dependem do tema.

## Arrays, e o último vence

O `style` também aceita um **array**, aplicado da esquerda para a direita, em que um objeto posterior
sobrescreve um anterior propriedade por propriedade, e `false`, `null` e `undefined` são pulados:

```tsx
style={[styles.row, { borderColor: t.line }, pressed && { backgroundColor: t.pressed }]}
```

Essa linha é tudo o que o CSS faz com uma classe base, um modificador e um estado. **A ordem no array é a
única precedência que existe.** Nada de especificidade para calcular, nada de `!important`, nenhuma regra em
outro arquivo que por acaso case.

## Por que esta é a troca que a plataforma faz

Na web, uma regra escrita para uma página alcança todo elemento que o seletor dela casa, o que é poderoso e é
por isso que folhas de estilo grandes ficam difíceis de mudar: ninguém sabe o que mais uma regra toca. **Um
estilo aqui alcança exatamente o elemento a que está preso.** O reuso é por JavaScript comum: exporte um
objeto, importe-o, ponha-o num array. Uma biblioteca de componentes é um conjunto de componentes que trazem
os próprios estilos, e mudar um não quebra uma tela que não o usa.

O custo é que não há herança em que se apoiar, com uma exceção, texto dentro de texto, que a aula 4 mostrou.
Uma fonte definida na `View` externa da tela não alcança `Text` nenhum. A seção sobre o CSS que aqui não
existe lista o que mais falta e o que o substitui.
