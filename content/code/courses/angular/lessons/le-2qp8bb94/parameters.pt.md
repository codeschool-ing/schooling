---
title: Parâmetros de rota, como inputs
version: 1
---

**Um parâmetro de rota é a parte do endereço que muda de uma visita para outra, e com input binding
ele chega ao componente como um input.** O `courses/:courseId` dá ao `CoursePage` o `courseId` dele, o
mesmo input que a aula 8 definiu à mão com `courseId="javascript"`. O componente não sabe, nem precisa
saber, de onde o valor veio, e é por isso que ele não mudou.

Um parâmetro para o qual o planner não tem curso:

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
There is no course called rust.
```

O endereço casou com a rota, o input foi `rust`, e o `course()` não achou nada, então a página diz
isso com o último ramo da aula 8. Um erro de digitação numa URL é um acontecimento normal, e a página o
trata como tal.

## O parâmetro pode mudar debaixo de um componente

**O router reaproveita um componente quando o próximo endereço casa com a mesma rota.** Ir de
`/courses/git` para `/courses/javascript` mantém o mesmo `CoursePage` e define um `courseId` novo. Com
um input e um `computed`, não há nada em que pensar: o `course()` lê o `courseId()`, então acompanha.
Código escrito antes do input binding lê o parâmetro do `ActivatedRoute`, e muitas vezes assim:

```typescript
export class OldCoursePage implements OnInit {
  private readonly route = inject(ActivatedRoute);
  courseId = '';

  ngOnInit(): void {
    this.courseId = this.route.snapshot.paramMap.get('courseId') ?? '';
  }
}
```

O `snapshot` é o parâmetro no momento em que o `ngOnInit` rodou, uma vez. Quando o router reaproveita
o componente para outro curso, o `ngOnInit` não roda de novo, e a página continua mostrando o primeiro
curso sob o endereço do segundo. A correção nesse código é o `route.paramMap`, um Observable que emite
toda mudança; a correção que este curso usa é o input, que é um signal e não pode ser lido velho.

| como um componente obtém o `courseId` | acompanha uma troca de curso |
|---|---|
| um input, com `withComponentInputBinding()` | sim |
| `route.paramMap`, assinado | sim |
| `route.snapshot.paramMap`, lido uma vez | não |
