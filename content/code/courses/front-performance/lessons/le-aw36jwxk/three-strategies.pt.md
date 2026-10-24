---
title: Três estratégias
version: 1
---

**Uma estratégia é uma ordem de perguntar: o cache, a rede, ou os dois, e qual resposta vale.** Cinco têm
nomes que todo guia usa, e o planner usa três delas:

| estratégia | o que faz | certa para | a do planner |
|---|---|---|---|
| **cache first** | a cópia, se houver, senão a rede, guardando a resposta | arquivos que nunca mudam no endereço | `/assets/`, os scripts com hash |
| **network first** | a rede, senão a cópia | o que precisa ser o mais novo possível, e ainda funcionar offline | as páginas |
| **stale while revalidate** | a cópia na hora, e a rede em segundo plano para a próxima vez | o que pode ter uma visita de atraso | fontes, capas, o plano, o aviso |
| **network only** | a rede, como se não houvesse worker | o que nunca pode estar vencido, como um pagamento | não usada |
| **cache only** | a cópia, nunca a rede | o que foi buscado no install | não usada |

**O cache first é o `immutable` da aula 9, feito à mão**, e certo pelo mesmo motivo: um nome com hash não pode
apontar para outro arquivo. Numa rede lenta é a estratégia que tira a ida e volta de vez.

**O network first mantém uma página honesta.** Um visitante online sempre vê a página que o servidor desenha
agora; a cópia é só para quando a rede some. O custo é que uma rede lenta ainda é esperada: um celular com sinal
fraco espera o timeout inteiro antes de receber a cópia. Um refinamento comum dá à rede alguns segundos e
responde do cache depois disso.

**O stale while revalidate é o `stale-while-revalidate` da CDN da aula 9, no navegador.** O visitante recebe a
cópia sem espera, e o worker busca uma nova por trás, então uma mudança chega a ele com uma visita de atraso.
Para uma fonte ou uma capa isso não é nada; para o plano seria a lista de cursos da última visita, e é por isso
que as páginas do planner, que levam o plano dentro delas, são network first.

## Como o worker escolhe

O `fetch` vê um `Request`, e três propriedades dele decidem tudo acima:

- **`request.method`**: só `GET` é respondido de um cache; o `POST` para `/vitals` vai para a rede intocado,
  porque o tratador retorna sem chamar `respondWith`;
- **`request.mode === "navigate"`**: a requisição da própria página, em oposição aos arquivos que a página pede;
- **o endereço**: `/assets/` é a parte que o Vite põe hash, como as regras da aula 9 disseram.
