---
title: Entre a página e a rede
version: 1
---

**Um service worker é um script que o navegador roda à parte da página, que vê toda requisição que a página
faz e pode respondê-la ele mesmo.** Ele não tem janela nem DOM. É instalado por uma página, continua
rodando entre visitas como o navegador achar melhor, e dali em diante toda requisição das páginas que ele
controla passa por ele primeiro: ele pode responder de um cache próprio, perguntar à rede, ou as duas
coisas.

## O que o diferencia dos caches da aula 9

| | o cache HTTP | um service worker |
|---|---|---|
| quem decide | o servidor, pelos cabeçalhos | o seu script, requisição por requisição |
| o que guarda | o que os cabeçalhos permitirem | o que o script puser no seu **Cache Storage** |
| sem a rede | nada que precise de conferência funciona | tudo o que ele guardou pode ser respondido |
| quando muda | quando os cabeçalhos dizem | quando uma versão nova do script é instalada |

**O Cache Storage é um estoque de pares de requisição e resposta**, com nomes que o script escolhe, que só o
script, ou a página, lê e escreve. O navegador nunca o vence por conta própria, embora possa apagar os dados
de um site quando o disco está cheio, como pode com quaisquer dados de site.

## A vida dele

1. **register**: uma página chama `navigator.serviceWorker.register("/sw.js")`. O navegador baixa o
   arquivo.
2. **install**: o evento `install` do script roda uma vez, o momento de buscar o que ele quer ter desde o
   começo.
3. **activate**: quando nada mais antigo está controlando páginas, o `activate` roda, o momento de apagar o
   que uma versão anterior deixou.
4. **fetch**: dali em diante, toda requisição de uma página controlada é um evento `fetch`, e o script decide
   a resposta.

Duas regras vêm com o poder. **Um service worker só roda em HTTPS, ou em `localhost`**, porque um script que
responde toda requisição é exatamente o que um atacante na rede gostaria de instalar. E **o escopo dele é a
pasta dele**: um worker servido de `/sw.js` controla o site inteiro, um de `/assets/sw.js` só os endereços
abaixo de `/assets/`. É por isso que o do planner vai em `public/`, que o Vite copia para a raiz, sem hash,
com um nome que nunca muda.
