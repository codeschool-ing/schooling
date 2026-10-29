---
title: Workers nos frameworks
version: 1
---

**Escrever um worker à mão, como esta aula fez, é como entender um; escrever à mão toda rota de uma aplicação
grande é como errar um.** A lista de arquivos com hash que um worker deve guardar muda a cada build, e uma
ferramenta que lê o build consegue escrevê-la. O **Workbox**, a biblioteca do Google, é essa ferramenta para a
maioria dos projetos, e os frameworks chegam a ele, ou ao próprio, por caminhos diferentes. Esta seção foi lida na
documentação e no pacote de cada projeto; nada dela foi rodado.

| | o caminho comum | o que ele escreve |
|---|---|---|
| **Next.js** | o guia da documentação escreve um `public/sw.js` à mão, para notificações; para cache offline, o pacote Serwist, `@serwist/next`, feito sobre as ideias do Workbox | um worker com os arquivos do build listados |
| **Nuxt** | o módulo `@vite-pwa/nuxt` | pelo `vite-plugin-pwa`, um worker Workbox e o manifesto da aula 11 |
| **SvelteKit** | embutido: um arquivo `src/service-worker.js` é empacotado e registrado sozinho, e o módulo `$service-worker` lhe dá a lista dos arquivos do build e uma string de versão | o seu worker, com as listas de que ele precisa escritas para ele |
| **Angular** | `ng add @angular/pwa`, que instala o `@angular/service-worker` | o worker do próprio Angular, configurado no `ngsw-config.json`: grupos de assets buscados no install ou no uso, e grupos de dados com estratégia *performance* ou *freshness* |

**O que nenhum deles consegue decidir é a estratégia.** Cada um dá cache first, network first e stale while
revalidate com algum nome, e cada um deixa para o projeto a escolha de que arquivos recebem qual, porque isso
depende de quanto cada um muda e de quão vencido pode estar, que é do que tratavam as seções de estratégia desta
aula. O do SvelteKit é o mais perto desta aula: ele dá a lista e deixa o código com você.
