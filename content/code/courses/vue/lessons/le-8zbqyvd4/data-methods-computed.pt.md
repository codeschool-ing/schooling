---
title: data, computed e methods
version: 1
---

**Na Options API, `data` devolve o estado do componente, `computed` define os valores derivados e
`methods` as funções, e os três são juntados no `this`.** Cada um é a grafia Options de algo que você já
conhece.

| Options API | é, na Composition API |
|---|---|
| `data() { return { clicks: 0 } }` | `const clicks = ref(0)` |
| `computed: { percent() { return … } }` | `const percent = computed(() => …)` |
| `methods: { ask() { … } }` | `function ask() { … }` |
| `props: { … }` | `defineProps({ … })` |
| `emits: ['more']`, depois `this.$emit('more', 15)` | `const emit = defineEmits(['more'])`, depois `emit('more', 15)` |
| `watch: { … }` | `watch(…)`, seção 06 desta aula |

Leia de novo o card da seção anterior com esta tabela ao lado e cada linha tem um par.

## Por que `data` é uma função

`data` devolve um objeto novo a cada vez que é chamada, e o Vue a chama uma vez por instância do
componente. Se fosse um objeto simples, todos os cards compartilhariam um único `clicks`, porque todos
guardariam o mesmo objeto. A regra é a mesma que a aula 10 enunciou para composables: **chamar a função
é o que cria estado novo.** Um componente escrito com `data: { clicks: 0 }` é recusado pelo Vue 3: ele avisa que
a opção data precisa ser uma função, e o componente não chega a montar. O Vue 2 só permitia isso na
instância raiz.

## Tudo no `this`, e quanto isso custa

O Vue junta props, data, valores computed e métodos num único objeto, a instância do componente, e
`this` dentro de qualquer opção é essa instância. Isso deixa a Options API rápida de escrever, e tem três
custos que você vai encontrar em código real:

- **Nomes colidem, e nem sempre em voz alta.** Um método e um computed chamados `percent` são um
  nome só no `this`; o Vue avisa sobre essa em desenvolvimento, e o computed vence. Outras colisões
  passam em silêncio: entre mixins (seção 07), e entre o que o `setup()` devolve e o `data` (seção 08).
- **Nada diz de onde um nome veio.** `this.label` pode ser uma prop, uma propriedade de data, um valor
  computed ou algo que um mixin acrescentou (seção 07). Num componente grande, descobrir significa
  procurar.
- **O desempacotamento é automático e está em toda parte.** `this.clicks` é o valor, nunca um ref, então
  não há `.value` para esquecer; e também não há ref para passar a uma função que deveria acompanhá-lo,
  que é o que as regras da aula 2 pediam.

O computed `percent` e o método `ask` leem `this.done` e `this.clicks` porque não há outro jeito de
alcançar o componente de dentro de uma opção. Esse é o assunto da próxima seção, e o bug mais comum em
código Options API.
