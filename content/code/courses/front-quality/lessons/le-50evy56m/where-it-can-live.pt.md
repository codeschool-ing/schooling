---
title: Seis lugares em que um navegador guarda um segredo
version: 1
---

**Onde quer que um token fique guardado no navegador, a pergunta que decide se ele está seguro é a
mesma: que código consegue lê-lo?** Os scripts da própria página são código de muita gente. O planner
carrega só o seu, e um app de verdade carrega um framework, uma dúzia de bibliotecas, uma tag de
analytics e o que mais um widget de suporte trouxer, e cada um deles roda com exatamente os direitos
que a página tem. A aula 9 acrescenta o pior caso: um texto que alguém digitou, transformado em script
por uma linha descuidada.

| onde | vive até | um script da página consegue ler | mandado ao servidor |
|---|---|---|---|
| uma variável na memória | a aba ser fechada ou recarregada | só o código que alcança a variável, o que numa página é qualquer código que se esforce | pelo seu código |
| `sessionStorage` | a aba ser fechada | sim, qualquer script da mesma origem | pelo seu código |
| `localStorage` | alguém apagar | sim, qualquer script da mesma origem, em todas as abas, para sempre | pelo seu código |
| IndexedDB | alguém apagar | sim, como o `localStorage` | pelo seu código |
| um cookie sem `HttpOnly` | o `Max-Age` dele, ou o navegador fechar | sim, pelo `document.cookie` | pelo navegador, em toda requisição ao site dele |
| um cookie com `HttpOnly` | o `Max-Age` dele, ou o navegador fechar | **não** | pelo navegador, em toda requisição ao site dele |

**Só a última linha guarda o segredo longe dos scripts da própria página**, e essa é a propriedade que
vale a pena pagar. Todo o resto é questão de quanto tempo o segredo fica largado para um script achar:
o `localStorage` o guarda até alguém limpar, e é por isso que tantos vazamentos de apps de página única
começam ali.

## O que a última linha custa

Um cookie `HttpOnly` é mandado pelo navegador sozinho, e essa é a fraqueza dele: uma requisição que
outro site faz o navegador mandar também o leva. Esse ataque é o cross-site request forgery, e o
`SameSite`, numa seção desta aula, e as checagens da aula 9 são a resposta a ele. **A troca é boa.** O
ataque a um cookie é estreito e tem defesas padronizadas; o ataque a um token legível é qualquer script
na página, e a defesa é que nunca pode haver um.
