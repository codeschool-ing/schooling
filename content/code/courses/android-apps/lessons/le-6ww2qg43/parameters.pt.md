---
title: Tudo o que um composable mostra chega como parâmetro
version: 1
---

**`CourseRow` não sabe nada que não tenha recebido.** Ele não procura o curso, não lê um banco de
dados, não guarda os minutos em lugar nenhum; recebe um `Course` e um `Int` e os descreve. Chame-o com
`Course("sql", "SQL Databases")` e `0`, e ele descreve isso. Um composable escrito assim se chama
**sem estado** (*stateless*), e é o formato que a maioria dos composables do planner vai ter: os dados
entram pelos parâmetros e a função os transforma numa descrição da tela.

Esse formato se paga três vezes:

- **Ele pode ser mostrado com quaisquer dados.** Uma prévia, na seção 04, o chama com um curso
  inventado; um teste, na aula 21, o chama com os casos incômodos, um curso de nome muito longo, zero
  minutos, dez mil minutos.
- **Ele pode ser reaproveitado.** A lista de cursos, o resumo da semana e um resultado de busca podem
  todos mostrar `CourseRow`, cada um com os próprios dados.
- **Ele não tem como errar sobre de onde vieram os dados**, porque nunca busca nenhum. Quando a aula
  15 levar os cursos para um banco de dados, `CourseRow` não muda.

O formato oposto, um composable que busca os próprios dados, é tentador porque a chamada fica mais
curta: `CourseRow("kotlin")` e a linha faz o resto. Todas as vantagens da lista acima somem, e a linha
só pode ser vista numa prévia com um banco de dados funcionando por trás.

## Como costuma ser uma lista de parâmetros

Os próprios componentes do Compose seguem um padrão que vale copiar, e o `Button` mostra tudo de uma
vez:

```kotlin
@Composable
fun Button(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    // … colours, shape, padding …
    content: @Composable RowScope.() -> Unit,
)
```

Essa assinatura é uma versão resumida da do Material 3 e não foi compilada aqui. Leia em quatro
partes:

1. **O que é obrigatório vem primeiro**, sem valor padrão: `onClick`, o que fazer ao ser apertado.
2. **`modifier: Modifier = Modifier`** é o primeiro parâmetro opcional, por convenção, em todo
   componente que emite um layout. É como quem chama decide tamanho, espaçamento e posição, que é o
   assunto da aula 6.
3. **Todo o resto tem valor padrão**, então a chamada mais simples é curta e a completa é possível.
4. **Um slot vem por último**, uma lambda composable, para que o conteúdo de quem chama possa ser
   escrito entre chaves depois da chamada: `Button(onClick = { … }) { Text("Add") }`. A seção 05 é
   sobre slots.

`onClick` é a outra direção dos dados. Valores **entram** como parâmetros; o que o usuário faz
**sai** como uma função que quem chamou passou. `CourseRow` vai ganhar um `onClick: () -> Unit` quando
a lista virar algo em que se toca, na aula 8, e a aula 10 dá nome ao padrão: estado desce, eventos
sobem.
