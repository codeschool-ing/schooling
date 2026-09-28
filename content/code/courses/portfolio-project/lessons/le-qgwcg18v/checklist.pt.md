---
title: Uma lista, e o que ela não vê
version: 1
---

Alguns deslizes são mecânicos, e uma máquina os encontra mais rápido que os seus olhos. Um `grep` sobre as
linhas acrescentadas do diff pega os de costume:

```
ana@laptop:~/loanbook$ git diff main... | grep -nE '^\+.*(console\.log|TODO|print\(|debugger)'
9:+  console.log("items", items);
25:+  <!-- TODO: nicer empty state -->
```

O padrão olha só as linhas que começam com `+`, as que este branch acrescenta, atrás de `console.log`,
`TODO`, `print(` e `debugger`. Os dois deslizes estão ali, com o número da linha no diff. Transforme isso
em hábito, ou em script, ou num hook de pre-commit: não custa nada e nunca erra sobre o que encontra.

Depois a lista que uma máquina não consegue rodar, que é o motivo de ler:

| pergunta | o que ela pega |
|---|---|
| Todo nome diz o que a coisa é? | `data`, `x2`, `handleStuff` |
| Tem código comentado? | uma versão antiga guardada "por via das dúvidas"; o git já guarda |
| Todo caminho novo tem o seu erro? | um fetch sem falha, aula 11 |
| Algo que o usuário digitou entra na página como HTML? | o nome de quem pega emprestado desenhado como marcação |
| Tem um segredo, uma chave, uma senha, um endereço interno? | aula 14 |
| Eu entenderia isto daqui a seis meses? | uma linha esperta sem comentário |

Olhe de novo o contexto em volta do `console.log`. `list.innerHTML = items.map(row).join("")` monta a
tabela a partir de strings, e `row` põe o nome de quem pega emprestado dentro delas como foi digitado. Um
nome digitado como `<b>Rui</b>` apareceria em negrito, e qualquer coisa que alguém digite num nome seria
desenhada como marcação na página de todas as outras professoras. **Nenhum grep encontra isso; a quarta
pergunta encontra.** No loanbook isso foi encontrado, e corrigido no commit de acessibilidade, aula 13,
que monta cada linha com `textContent`.
