---
title: Quando um teste deve desligar o cache
version: 1
---

Um teste desliga o cache quando o assunto dele não é cache, e o deixa em paz quando é.
**Na maior parte do tempo o Playwright já fez essa escolha por você**, porque um contexto novo
começa com o cache vazio. O que falta é conhecer as outras maneiras de o cache se desligar, para
que nenhuma aconteça por acidente.

## Não existe a flag `--disable-cache`

Muita gente procura uma porque o painel do DevTools tem uma caixa de marcar. O Playwright 1.56 não
tem opção com esse nome, nem na linha de comando nem na configuração. A referência que vem com ele
fala do cache HTTP em dois lugares. Um é a promessa de que um contexto novo não divide cache com
outro. O outro é uma nota em `page.route` e `context.route`: **ativar rotas desativa o cache HTTP**.
Isso dá três maneiras de um teste ficar sem cache, e em geral só uma delas é escolhida de propósito:

| maneira | o que faz | quando é a ferramenta certa |
|---|---|---|
| um contexto novo | um cache vazio, que é o padrão da fixture `page` | quase sempre |
| `page.route` | desliga o cache daquela página como efeito colateral | quando você ia interceptar requisições de todo jeito |
| uma sessão do DevTools Protocol | desliga o cache e mais nada; só no Chromium | raramente; veja abaixo |

A segunda linha é a perigosa, porque ninguém a lê como configuração de cache. Um teste que intercepta
uma requisição para respondê-la com dados preparados, ou só para observá-la, também faz o navegador
parar de guardar qualquer coisa pelo resto da vida daquela página. O último teste de
`tests/cache.spec.js` é exatamente isso: os passos do cliente que volta, com uma rota que não muda
nada, passando.

A terceira linha é a própria caixa de marcar. O DevTools conversa com o Chromium pelo DevTools
Protocol, e o Playwright pode abrir uma sessão nesse mesmo protocolo para uma página:

```javascript
const cdp = await page.context().newCDPSession(page);
await cdp.send('Network.enable');
await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
```

Rodado contra o Chromium 141 deste laboratório com os passos do cliente que volta, a segunda visita
chegou ao servidor e mostrou a oferta nova. Sem a linha `Network.enable` não chegou, e nada
reclamou. Firefox e WebKit não falam esse protocolo, então uma suíte que depende dele virou, sem
avisar, uma suíte só de Chromium. Essas três linhas são para leitura; o projeto não precisa delas.

## Quando deixar ligado

**Quando o cliente que você imita já esteve aqui antes.** O cliente que volta, uma página aberta
duas vezes na mesma sessão, um usuário que volta por um favorito: todos encontram o cache, e um teste
que o desliga decidiu não olhar. Duas visitas num contexto, ou um perfil guardado, são as ferramentas
de duas seções atrás.

**Quando a velocidade é o assunto.** Uma página que carrega em um segundo na primeira visita e bem
mais rápido na segunda está se comportando como projetado, e medir só a primeira visita perde metade
da história. A aula 10 de `non-functional-testing` trata de medir a velocidade de uma página, e o
cache pertence a ela.

## Quando desligar

**Quando o teste é sobre conteúdo, e o cache só acrescentaria uma dúvida.** A resposta aqui é o
padrão: um contexto por teste. Desligar o cache dentro de um teste que já tem contexto novo não muda
nada, e esconde a decisão numa linha que ninguém liga a ela.

**Quando você está caçando um defeito e quer saber se o cache faz parte dele.** Rode os mesmos passos
com o cache ligado e desligado. Se o resultado muda, o cache está na história, e os cabeçalhos são a
próxima coisa a ler; a seção anterior os verificou.

## O que um contexto novo não limpa

Um contexto novo começa com o cache do **navegador** vazio. Uma CDN ou um proxy entre o navegador e o
servidor não está dentro do navegador, então um teste não consegue esvaziá-lo, e uma resposta que ele
guarda chega a todo contexto novo exatamente como chega a um cliente que volta. Quando um teste passa
na sua máquina e falha num ambiente atrás de uma CDN, ou o contrário, vale perguntar por esse cache;
a aula 21 de `manual-testing` trata de como os ambientes diferem. Uma página com service worker
também guarda cópias próprias, e a aula 5 encontra um.
