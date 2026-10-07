---
title: A sua máquina: um navegador, um editor e uma pasta
version: 1
---

Este curso se pratica escrevendo páginas e abrindo-as, e **a plataforma não lhe dá uma máquina para isso.** Você monta a sua, uma vez, aqui. É pouca coisa: três programas e uma pasta.

- **Um navegador feito sobre o Chromium**: Chrome, Edge ou o próprio Chromium. Todo número deste curso foi impresso pelo Chromium, então é nele que os seus números vão bater com os das aulas. Firefox e Safari desenham as mesmas páginas e diferem dele por um pixel aqui e ali.
- **Um editor de texto** que salve texto puro em UTF-8. O VS Code é gratuito no Windows, no macOS e no Linux, e é o editor que as aulas têm em mente quando citam um menu. Qualquer editor que salve texto puro serve. Um processador de texto não serve.
- **O Node.js**, para duas ferramentas de linha de comando: o validador da seção 13 e o Tailwind da aula 13. As aulas 2 a 12 só precisam do navegador e do editor.

## Escolha onde ela roda

| caminho | do que você precisa | quanto custa ao seu computador |
|---|---|---|
| **no seu próprio computador (recomendado)** | Windows, macOS ou Linux como estão | cerca de 200 MB para o Node.js, 13 MB para o validador, e o seu editor |
| numa máquina virtual | VirtualBox no Windows e no Linux, UTM no Mac, e o Ubuntu Desktop 24.04 LTS | 4 GB de memória enquanto roda e 25 GB de disco, o mínimo do próprio Ubuntu |
| online | um editor numa página web que desenha o resultado ao lado do código, como o CodePen ou o StackBlitz | nada na sua máquina; uma conta, e um plano gratuito que a empresa pode mudar |

**O seu próprio computador é a recomendação**, porque nada neste curso precisa de isolamento. Uma página é um arquivo que o seu navegador abre; nada aqui escuta numa porta, mexe no sistema ou pede senha. E o navegador que você já usa é o que os seus leitores usam.

A máquina virtual é para quem quer exatamente a máquina em que estas aulas foram gravadas, o Ubuntu 24.04. É a edição **Desktop**, e não a Server, porque este curso precisa de uma janela com um navegador dentro. O Ubuntu Desktop vem com o Firefox; o Chromium está a um comando de distância, `sudo snap install chromium`. O Node.js entra do mesmo jeito que em qualquer Linux, logo abaixo.

Os editores online funcionam de um computador emprestado, e servem bem para as aulas 2 a 12, em que tudo é HTML e CSS. O curso não depende de nenhum deles: o que oferecem de graça é decidido pela empresa que os mantém, e as duas sessões de terminal, na seção 13 e na aula 13, precisam de um Node.js que eles podem não dar.

## Monte

**Instale o Node.js** a partir do nodejs.org, a versão marcada como LTS. No Windows e no macOS é um instalador. No Linux, o nodejs.org lista os pacotes de cada distribuição, e um gerenciador de versões como o `nvm` é o outro caminho comum. Quando terminar, **abra um terminal novo**, porque um terminal que já estava aberto não sabe que o Node existe. Depois confira:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
```

O validador que este curso usa precisa do Node 22.22 ou posterior na linha 22, ou do 24.8 ou posterior. Uma LTS mais nova que a de cima serve.

**Crie a pasta** onde vai toda página do curso. As aulas a chamam de `~/site`, uma pasta chamada `site` no seu diretório pessoal, e os mesmos dois comandos a criam num terminal do Windows, do macOS e do Linux:

```
ana@laptop:~$ mkdir site
ana@laptop:~$ cd site
```

**Instale o validador dentro dela.** O `npm` é o gerenciador de pacotes do Node, e isto baixa um pacote para uma pasta `node_modules` dentro de `site`:

```sh
npm install html-validate@11.16.2
```

O `@11.16.2` fixa a versão com que este curso foi gravado; sem ele você recebe a mais recente, e as mensagens da seção 13 podem vir escritas de outro jeito. Esta aula não cita o que o `npm install` imprime, porque isso depende da rede no dia.

**Diga ao validador o que conferir.** Salve isto como `.htmlvalidate.json` em `site`, com o ponto no começo do nome:

```json
{"extends": ["html-validate:standard", "html-validate:document"]}
```

Ele escolhe dois dos conjuntos de regras do validador: `standard`, as regras da linguagem HTML, e `document`, as que tratam da página inteira, como ter um doctype e um título. Depois confira se o `npx`, que roda um programa instalado na pasta atual, o encontra:

```
ana@laptop:~/site$ npx html-validate --version
html-validate-11.16.2
ana@laptop:~/site$ ls -A
.htmlvalidate.json
node_modules
package-lock.json
package.json
```

`package.json` e `package-lock.json` são o registro do npm do que ele instalou. O `ls -A` está ali para mostrar o arquivo de configuração, que o `ls` sozinho esconde: no macOS e no Linux, um nome que começa com ponto fica oculto. A montagem é só isso.

## Como uma página chega à sua tela

Toda página que uma aula mede aparece inteira na seção que a mede, ou é descrita como uma mudança numa página mostrada antes: "o mesmo arquivo sem a primeira linha". **Digite ou cole a página num arquivo novo no seu editor, salve-a em `site` com o nome que a seção dá e dê um clique duplo nela.** Ela abre no seu navegador. Quando você mudar o arquivo, salve e recarregue a aba, porque o navegador mostra o arquivo como estava da última vez que o leu.

Para ver o que o navegador fez com a página, clique com o botão direito em qualquer elemento e escolha **Inspecionar**. O painel que se abre é o DevTools, da aula 11 de `web-fundamentals`, e é nele que você confere cada número que as aulas citam.
