---
title: Talvez você não precise de um efeito
version: 1
---

**A maioria dos efeitos em código com problemas não deveria ser efeito.** A documentação do próprio
React tem uma página com esse título, e o argumento dela é o que as aulas 4 e 5 vêm construindo: um
efeito serve para manter algo fora do React em dia, e quase tudo para que as pessoas escrevem efeitos
já está dentro do React.

Cada linha abaixo é um padrão que funciona, no sentido de que a tela termina certa, e custa uma
renderização extra, um piscar do valor errado, ou um bug que espera o dia em que duas atualizações
chegam juntas:

| o que você quer | escrito como efeito | o que escrever no lugar |
|---|---|---|
| um valor calculado a partir de props ou estado | um efeito que define um segundo pedaço de estado | calcular ao renderizar, como o `WeekSummary` faz |
| algo acontecer quando um botão é apertado | estado definido pelo botão, e um efeito que o observa | fazer no handler do clique |
| um formulário reiniciado quando o usuário escolhe outro registro | um efeito que limpa os campos quando o id muda | `key={id}` no formulário, da aula 3 |
| dados do servidor | um efeito com `fetch`, `ignore` e três estados | um efeito está certo, e uma biblioteca é melhor: aula 11 |
| uma lista ordenada ou filtrada | um efeito que escreve a lista ordenada no estado | ordenar ao renderizar; a aula 7 guarda o resultado se for lento |

A primeira linha é a mais comum, então aqui está a forma dela, como costuma ser escrita:

```tsx
const [thisWeek, setThisWeek] = useState<Session[]>([])
useEffect(() => {
  setThisWeek(sessions.filter((s) => inWeek(s.date, monday)))
}, [sessions, monday])
```

Ela renderiza o componente com um `thisWeek` vazio, commita isso na página, roda o efeito, define o
estado e renderiza de novo com a lista certa. Duas renderizações onde uma bastaria, e a primeira não
mostra nada. A linha que o `App` já tem, `const thisWeek = sessions.filter(…)`, faz isso numa
renderização e não tem como ficar velha.

**Os três efeitos do planejador passam no teste**: o servidor, o título da aba e o teclado da janela
estão todos fora do React. Todo o resto dele é calculado ao renderizar, e isso não é um acaso de um
app pequeno. É a forma que um componente React deve ter, qualquer que seja o tamanho.
