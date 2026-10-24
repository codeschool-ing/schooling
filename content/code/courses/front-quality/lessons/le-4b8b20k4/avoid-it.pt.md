---
title: O melhor CORS é nenhum
version: 1
---

**O planner nunca precisou de nada disso, porque a página dele pergunta à própria origem desde a aula 5.**
O proxy do Vite manda o `/api` de `http://localhost:5173` para a porta 3000 pelas costas do navegador,
então o navegador vê uma origem só e não aplica regra de CORS nenhuma. O mesmo vale quando o app é
publicado, se a API for servida no próprio endereço do site, `https://planner.example/api/…`, pelo mesmo
servidor ou por um proxy reverso na frente dos dois.

Esse arranjo tem três vantagens, e elas são o motivo de ele ser a primeira escolha:

- **Nenhum preflight**, então nenhuma ida e volta a mais antes de cada `POST`.
- **Os cookies são do mesmo site** sem `SameSite=None` nenhum, e o cookie da aula 6 funciona como está.
- **Nada para errar**: nenhuma lista de permissão para manter em dia com os lugares onde o app é
  publicado, e nenhum curinga para tentar.

## Quando o CORS é a resposta

Algumas APIs existem para ser chamadas de outras origens: uma API pública que os sites de outras pessoas
usam, ou uma API por trás de vários apps em domínios diferentes. Aí a lista de permissão da seção
anterior é a ferramenta, escrita a partir da lista de sites que devem usá-la, e testada nas duas
direções, como a do planner: a origem que deve ser permitida é, e uma que não deve, não é.

## O que o CORS não é

Vale dizer mais uma vez, porque o erro faz parecer o contrário: **o CORS é o servidor dando ao navegador
permissão para relaxar uma regra; ele não é uma tranca no servidor.** Uma requisição bloqueada pelo CORS
chegou ao servidor; o `curl` lê a resposta; um script em outro site ainda consegue fazer o navegador da
pessoa *mandar* uma requisição com os cookies dela, embora não consiga ler a resposta. Esse último caso é
o cross-site request forgery, e a aula 9 o fecha com o `SameSite` e uma checagem do cabeçalho `Origin` em
toda requisição que muda alguma coisa.
