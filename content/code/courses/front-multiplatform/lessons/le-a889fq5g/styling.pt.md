---
title: Estilos sem CSS
version: 1
---

**Um estilo do React Native é um objeto JavaScript, e a maioria dos nomes dele são nomes de CSS em
camelCase**: `backgroundColor`, `fontSize`, `borderRadius`. Essa semelhança é a armadilha. Quatro
diferenças em relação ao CSS explicam quase toda surpresa:

1. **O flexbox é o único layout, e a direção padrão dele é `column`.** Tudo se empilha na vertical até
   um pai dizer `flexDirection: "row"`, que é como cada linha de sessão desta aula põe a data e o botão
   lado a lado. Não há `float`, nem `grid`, nem `display: block`.
2. **Nada se propaga em cascata.** Uma cor ou uma fonte numa `View` não chega a nenhum `Text` dentro
   dela, e não há seletores nem classes: cada componente recebe o próprio estilo. A única exceção é que
   um `Text` dentro de um `Text` herda os estilos de texto do pai.
3. **Números não têm unidade.** `padding: 16` são dezesseis pixels independentes de densidade, uma
   unidade que tem o mesmo tamanho físico num celular de tela densa e num sem. Porcentagens existem como
   texto, `width: "50%"`; `rem`, `em` e `vh` não.
4. **As plataformas ainda diferem.** Uma sombra é `boxShadow` nas versões recentes, e ela aparece
   diferente no Android e no iOS; fontes, o teclado e a barra de status também diferem. `Platform.OS` e
   `Platform.select({ ios: …, android: … })` são como um estilo diz isso.

```tsx
const styles = StyleSheet.create({
  row: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 10 },
  action: { color: "#0a58ca", fontWeight: "600" },
});
```

**O `StyleSheet.create` é o jeito comum de escrevê-los**, fora do componente, para os objetos serem
criados uma vez e não a cada desenho, e os nomes se lerem como nomes de classe. Um estilo é passado com
`style=`, e um array, `style={[styles.input, problem && styles.wrong]}`, combina vários, com os últimos
ganhando.

*A regra sobre a cascata é o comportamento documentado num celular; o build web, que transforma estilos
em CSS, pode deixar uma cor numa `View` chegar ao texto dela, mais um caso do navegador ser tolerante
onde o celular é rígido. Este curso só conseguiu rodar o build web.*

## Cores que passam

O azul do planner sobre branco é `#0a58ca`, um contraste de mais de 6 para 1, e o texto branco sobre o
mesmo azul também, então os dois passam no WCAG 2.2 AA para texto normal, que pede 4,5. Um celular
acrescenta uma configuração que a web muitas vezes ignora: **o tamanho de texto da pessoa**. O React
Native escala o `Text` com o tamanho de fonte do sistema por padrão, e um layout com alturas fixas é
onde o texto aumentado pelo sistema fica cortado. Dê às linhas espaçamento interno, não alturas.
