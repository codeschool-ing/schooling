---
title: O array de dependências diz quando rodar de novo
version: 1
---

**O React roda um efeito de novo depois de qualquer renderização em que um valor do array de
dependências mudou.** O array é uma lista de todo valor do componente que o efeito lê. Acerte e o
efeito fica em dia; esqueça um e ele roda com um valor velho, em silêncio.

O segundo efeito mantém o título da aba em dia com a semana:

```tsx
useEffect(() => {
  document.title = `Week of ${formatWeek(monday)} · Study planner`
}, [monday])
```

O `look --html title` imprime o elemento `<title>` da página no fim:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --html title
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --html title
-- click button Next week
<title>Week of 26 Oct 2026 · Study planner</title>
```

Depois de "Next week" o título diz 26 de outubro. O `monday` mudou, o array do efeito citava
`monday`, então o React o rodou de novo depois do commit.

## Três jeitos de escrever o array

| você escreve | o efeito roda | o exemplo do planejador |
|---|---|---|
| `useEffect(fn)`, sem array | depois de toda renderização | nenhum: quase nunca é o que você quer |
| `useEffect(fn, [])` | uma vez, depois que o componente aparece | buscar os dados; o listener do teclado |
| `useEffect(fn, [monday])` | depois da primeira renderização, e depois de qualquer uma em que `monday` mudou | o título |

O React compara cada valor com o da renderização anterior usando `Object.is`, a comparação que a aula
4 apresentou. Para strings e números, isso compara valores. Para um objeto ou uma função criados
durante a renderização, nunca dá igual, então um efeito que lista um deles roda depois de toda
renderização; a aula 7 trata disso.

## Esquecendo um

Troque o array do efeito do título por `[]` e o título para de acompanhar a semana:

```
ana@dev:~/planner$ sed -i 's|^  }, \[monday\])$|  }, [])|' src/App.tsx
ana@dev:~/planner$ grep -n "}, \[" src/App.tsx
39:  }, [])
43:  }, [])
53:  }, [])
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --html title
-- click button Next week
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  ! react-hooks(exhaustive-deps): React Hook useEffect has a missing dependency: 'monday'
    ,-[src/App.tsx:43:6]
 41 |   useEffect(() => {
 42 |     document.title = `Week of ${formatWeek(monday)} · Study planner`
    :                                            ^^^|^^
    :                                               `-- useEffect uses `monday` here
 43 |   }, [])
    :      ^^
 44 | 
    `----
  help: Either include it or remove the dependency array.

Found 1 warning and 0 errors.
Finished in 107ms on 11 files with 116 rules using 4 threads.
ana@dev:~/planner$ sed -i '0,/^  }, \[\])$/!{0,/^  }, \[\])$/s//  }, [monday])/}' src/App.tsx
ana@dev:~/planner$ grep -n "}, \[" src/App.tsx
39:  }, [])
43:  }, [monday])
53:  }, [])
```

O título ainda diz 19 de outubro depois de "Next week". O efeito rodou uma vez com a `monday` da
primeira renderização e nunca mais foi chamado. **Nada falhou, e nada na página disse isso.** Mas o
linter do modelo percebeu. O `npm run lint` roda o Oxlint, que traz uma regra chamada
`exhaustive-deps`: ela lê o efeito, vê o `monday` e aponta para o array que não o cita. O último
`sed` põe o `[monday]` de volta.

**O array não é uma escolha de quando você gostaria que o efeito rodasse. É uma declaração do que o
efeito lê**, e um linter consegue conferir uma declaração. Se um efeito roda vezes demais com o array
correto, a correção é mudar o que o efeito lê, nunca mentir no array. A aula 6 trata das regras que
esse linter impõe, e a aula 23 de linters em geral.
