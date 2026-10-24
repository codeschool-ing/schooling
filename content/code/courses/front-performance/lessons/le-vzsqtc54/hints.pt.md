---
title: Contando ao navegador o que vem por aí
version: 1
---

**Toda correção desta aula até aqui diminuiu um arquivo ou o tirou do caminho crítico. Uma dica de recurso
não faz nenhuma das duas coisas: ela conta ao navegador de algo antes do que ele descobriria sozinho.** São
quatro, e um atributo, e é fácil usá-los demais.

| dica | o que faz | quando é a certa |
|---|---|---|
| `<link rel="preload">` | baixa um arquivo agora, com a prioridade que o `as` lhe dá | um arquivo de que a página vai precisar cedo mas que descobre tarde: uma fonte, como na seção das fontes, ou uma imagem citada só no CSS |
| `<link rel="modulepreload">` | o mesmo, para um módulo JavaScript, que ele também interpreta | os módulos que o script de entrada importa; **o Vite os escreve sozinho** quando um build tem mais de um chunk, e o da aula 8 terá |
| `<link rel="preconnect">` | abre agora a conexão com outro servidor: DNS, TCP e TLS | um servidor que a página certamente vai usar logo, como uma CDN de imagens |
| `<link rel="dns-prefetch">` | só consulta o nome | um servidor que a página talvez use; não custa quase nada |
| `fetchpriority` | sobe ou desce a prioridade de uma requisição | a imagem do LCP, como na seção "A imagem do LCP" |

## O custo de uma dica

**Um preload é uma promessa de banda.** Ele é pedido com prioridade alta, na frente do que o navegador
achou sozinho, então fazer preload de algo que não é necessário cedo tira a conexão de algo que é. Duas
regras o mantêm honesto:

- **faça preload só do que a primeira tela usa.** O planner faz preload de duas fontes porque o texto da
  primeira tela está nelas; uma fonte usada só num rodapé deve ser achada do jeito normal.
- **meça com e sem.** Um preload que ajuda numa página pode atrapalhar em outra, e uma página com dez
  preloads transformou as prioridades do navegador numa lista que alguém escreveu uma vez. O Chrome avisa no
  console quando um arquivo com preload não é usado poucos segundos depois da carga.

Um preconnect tem um custo menor do mesmo tipo: cada um é uma conexão mantida aberta, e o navegador desiste
de uma não usada depois de alguns segundos. Um punhado, para servidores que a página vai usar logo.

## Do que o planner precisa

De nada além do que tem. Os arquivos dele vêm todos do próprio servidor, então não há a que conectar cedo;
as fontes têm preload; a imagem tem a prioridade dela. **A dica que falta na maioria das páginas não é
nenhuma destas, e sim o próprio HTML**: tudo de que a primeira tela precisa, citado na primeira resposta. A
renderização no servidor da aula 1 e o CSS embutido desta aula são isso, e uma dica é o que sobra para os
arquivos que não podem ser.
