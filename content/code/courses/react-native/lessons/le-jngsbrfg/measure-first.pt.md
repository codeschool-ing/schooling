---
title: Um número antes, e um número depois
version: 1
---

**Trabalho de desempenho começa com uma medição, e não termina antes de uma segunda.** Sem a primeira, você
otimiza o que suspeita, que raramente é o que está lento. Sem a segunda, não dá para distinguir uma mudança
que ajudou de uma que só acrescentou código, e uma mudança que acrescenta código e não ajuda em nada é um
custo.

Quatro lugares onde um app como o planner fica lento, e o que mede cada um:

| o quê | como parece | o que mede |
|---|---|---|
| **renderizações** | um toque que demora a responder, digitação que atrasa | o Profiler do React DevTools; o componente `<Profiler>` do React; uma contagem num teste |
| **listas** | linhas em branco ao rolar rápido, um engasgo no fim de uma página | a taxa de quadros do Performance Monitor num celular; quantas linhas existem ao mesmo tempo |
| **imagens** | um app que o sistema fecha em segundo plano, rolagem lenta passando por fotos | o tamanho decodificado: largura × altura × 4 bytes |
| **o bundle** | uma primeira abertura lenta, uma primeira página lenta na web | o tamanho do bundle, por pacote, a partir do source map |

O primeiro e o último podem ser medidos num computador, e esta aula os mede; imagens podem ser calculadas
com exatidão, e a conta conferida num navegador. **O que a taxa de quadros de um celular faz não foi medido
para este curso**, que não tem celular; a aula 12 mediu uma animação num navegador pelo mesmo motivo, e a
mesma honestidade vale aqui: um computador é muito mais rápido que um celular barato, então um celular
precisa confirmar qualquer coisa que um navegador sugira.

**E meça um build de release.** A aula 18 mostrou o que o desenvolvimento acrescenta: avisos, conferências,
nenhuma minificação. Um build de desenvolvimento é mais lento em tudo, de propósito, então o perfil de um
acha problemas que não existem e esconde as proporções dos que existem.
