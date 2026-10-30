---
title: Uma lista é um array de elementos
version: 1
---

**O React não tem sintaxe de laço. Uma lista é um array de elementos, e o jeito de obter um é o
`map`.** O JSX aceita um array em qualquer lugar onde aceita um child, e desenha os itens em ordem. O
planejador já tem duas listas, e as duas têm esta forma:

```tsx
{courses.map((course) => (
  <CourseCard key={course.id} course={course} … />
))}
```

Todo o resto sobre listas é JavaScript comum antes do `map`. **Filtre, ordene e corte os dados
primeiro, depois mapeie o que sobrou**, que é o que o `CourseScreen` faz com `[...sessions].sort(…)` e
o que o `App` faz com a semana. Fazer o trabalho nos dados deixa o JSX como uma descrição simples do
que é desenhado, e a aula 4 já disse por que a ordenação copia antes.

## O que o React pede a uma lista

Todo elemento de um array precisa de uma `key`, e o React avisa quando falta uma. Tire a key dos
cartões de curso:

```
ana@dev:~/planner$ sed -i '/^          key={course.id}$/d' src/CourseList.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
[error] Each child in a list should have a unique "key" prop.%s%s See https://react.dev/link/warning-keys for more information. 

Check the render method of `CourseList`. 
ana@dev:~/planner$ npm run lint 2>&1 | grep -A 1 "jsx-key"
  ! react(jsx-key): Missing "key" prop for element in iterator.
    ,-[src/CourseList.tsx:13:16]
ana@dev:~/planner$ sed -i 's|^          course={course}$|          key={course.id}\n&|' src/CourseList.tsx
ana@dev:~/planner$ grep -n "key=" src/CourseList.tsx
15:          key={course.id}
```

A página desenhou mesmo assim, e o console tem o erro, com o componente a olhar. O linter achou antes
de qualquer coisa rodar: `jsx-key`, "Missing `key` prop for element in iterator". Os dois últimos
comandos põem a key de volta. **Uma key ausente não é uma quebra; é o React dizendo que vai
adivinhar**, e as duas próximas seções mostram quanto custa um palpite errado.

O mesmo vale para qualquer coisa que produza um array de elementos: `filter(…).map(…)`, `Array.from`,
ou uma lista montada num laço e empurrada para um array. Se acaba como um array de elementos, cada um
precisa de uma key.
