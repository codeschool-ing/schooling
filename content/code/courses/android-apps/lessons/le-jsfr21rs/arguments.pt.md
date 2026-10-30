---
title: Argumentos: um id, e nunca o objeto
version: 1
---

**Uma rota com propriedades é um destino com argumentos.** `CourseDetail("kotlin")` é a tela do curso
de Kotlin, e `entry.toRoute<CourseDetail>()` no grafo da seção 02 transforma a entrada da pilha de
volta num `CourseDetail` com o `courseId` preenchido. O compilador confere as duas pontas: uma rota
que precisa de `courseId` não pode ser navegada sem ele, e a tela recebe uma `String`, não algo que
precise de conversão.

Por baixo do tipo, o Navigation ainda trabalha com strings, e o teste da seção 04 as imprime. Eis o
que a pilha continha depois de tocar em Kotlin, e o argumento que a entrada do topo carrega:

```
ana@vm:~/planner$ grep -h -e 'tap Kotlin' -e 'argument' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.NavigationTest.xml
tap Kotlin             Courses  >  CourseDetail/{courseId}
courseId argument: kotlin
```

`CourseDetail/{courseId}` é o padrão que o Navigation gerou a partir da classe: o nome da rota e um
espaço reservado para cada propriedade. A entrada preenche o espaço com `kotlin`, e é isso que o
`toRoute` lê de volta. Antes da versão 2.8 os apps escreviam essas strings à mão,
`"course/{courseId}"`, e um erro de digitação numa delas era uma quebra em tempo de execução, não um
erro de compilação.

## Passe o id, busque o resto

**O argumento é `courseId`, não o `Course`.** É tentador passar o objeto inteiro, o nome, a cor, as
sessões, para a próxima tela ter tudo de uma vez. Três motivos para isso ser o hábito errado:

- **Os argumentos são salvos com a pilha**, no mesmo `Bundle` em que as chaves da aula 8 precisavam
  caber, para a pilha sobreviver quando o sistema tira o processo. Um `Bundle` é feito para valores
  pequenos; uma lista de sessões nele é o tipo de coisa que falha com `TransactionTooLargeException`
  no celular de alguém.
- **Uma cópia envelhece.** A tela do curso mostrando uma lista de sessões passada como argumento
  mostra a lista como estava quando o usuário tocou; uma sessão acrescentada na tela seguinte não
  está nela.
- **O id basta para encontrar o resto**, e encontrar é trabalho da próxima tela. Na aula 10 esse
  trabalho passa para um `ViewModel` que lê o curso pelo id; na aula 16, quem responde é um
  repositório.

Então as rotas do planner carregam ids, e só ids.
