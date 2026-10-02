---
title: Automática, à mão, ou as duas
version: 1
---

A loja usa os três arranjos de propósito, e juntos eles cobrem a escolha que uma equipe faz para
cada serviço:

| | só automática | só à mão | automática, mais linhas à mão |
|---|---|---|---|
| no laboratório | nenhum, depois desta aula | storefront, payments, mailer, report | orders |
| cobre | toda borda que uma biblioteca instalada vê | exatamente o que o código escolheu | as duas coisas |
| atributos de negócio | nenhum | sim | sim, nos spans automáticos |
| esforço | um comando e variáveis de ambiente | cada span escrito e mantido | as poucas linhas que importam |
| muda com | atualizações das bibliotecas | as suas próprias versões | as duas coisas |

**A resposta comum é a terceira coluna.** A instrumentação automática é o jeito mais barato de
acertar as bordas, de forma consistente e com os nomes das convenções, e o código acrescenta o que
só ele sabe. Um serviço instrumentado inteiramente à mão, como a vitrine, faz sentido quando é
pequeno, quando as bibliotecas que usa não têm instrumentação, ou para ensinar, que é por que a aula
2 fez assim.

A mesma ideia existe fora do Python com outra maquinaria. O agente de Java é um JAR carregado com
`-javaagent` que reescreve as classes à medida que são carregadas. .NET e Node.js têm seus próprios
lançadores e ganchos de inicialização. Há também ferramentas que observam um processo a partir do
kernel, com eBPF, e veem as chamadas de rede dele sem tocá-lo. **Todas elas param nos mesmos três
lugares**: não conseguem nomear um objeto de negócio, não conseguem seguir um cliente que não
conhecem, e não conseguem ver dentro da sua própria lógica.
