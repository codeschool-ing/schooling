---
title: Do que o "NoSQL" abriu mão, e o que comprou
version: 1
---

"NoSQL" é um nome ruim. Ele diz o que esses bancos não são, e vários deles hoje falam uma linguagem
muito parecida com SQL. **O que eles têm em comum é uma troca feita de propósito**: cada um abriu
mão de parte do que um banco relacional promete em troca de algo que as aulas 1 a 3 mostraram ser
difícil de conseguir de um.

Um banco relacional como o PostgreSQL promete quatro coisas juntas:

- **qualquer consulta**: os dados ficam em tabelas normalizadas e um join responde perguntas que
  ninguém planejou quando as tabelas foram desenhadas;
- **transações em quaisquer linhas**: uma venda atualiza um show e insere um ingresso,
  atomicamente;
- **um esquema** que o banco faz cumprir, então uma linha que o quebra é recusada;
- **um lugar onde tudo isso é verdade**, que a aula 2 mostrou ser difícil de dividir.

Os bancos desta aula e da próxima mantêm algumas dessas e largam outras, e o que ganham de volta é
principalmente o que a aula 2 achou caro:

- **Particionamento embutido.** Os dados se espalham pelos servidores por uma chave desde a primeira
  linha, sem roteador para escrever, e acrescentar um servidor move dados sozinho, geralmente num
  anel de hash como o da aula 2.
- **Replicação embutida**, muitas vezes com os quóruns da aula 3 e uma escolha de consistência por
  consulta.
- **Um modelo de dados com o formato do acesso**, então a leitura comum é uma busca num servidor em
  vez de um join entre várias tabelas.

O preço são as duas primeiras promessas. **Consultas que você não planejou ficam caras ou
impossíveis**, porque os dados estão arrumados para as que você planejou. **As transações são
limitadas**, geralmente a um item ou a uma partição. E um esquema flexível muda a tarefa de conferir
o formato dos dados para todo programa que os lê.

É por isso que esta aula começa pelos padrões de acesso e não pelos produtos. Cada família abaixo é
uma resposta diferente à pergunta **"em qual coisa estes dados precisam ser bons?"**, e escolher uma
é decidir quais perguntas você topa deixar caras.
