---
title: Dois lugares para rodar
version: 1
---

**JavaScript é uma linguagem, e uma linguagem precisa de um programa que a execute.** Esse
programa se chama hospedeiro. Este curso usa dois: o navegador, onde JavaScript nasceu em 1995 e
onde toda página com script roda um pouco dela, e o **Node.js**, que tira a mesma linguagem do
navegador e a roda como qualquer outro programa do seu computador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois hospedeiros em volta de uma linguagem. À esquerda, o navegador: o motor V8 roda a linguagem, e o navegador acrescenta document, localStorage, fetch e setTimeout. À direita, o Node.js: o mesmo motor V8, com process, fs, fetch e setTimeout no lugar.\"><rect x=\"20\" y=\"16\" width=\"330\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o navegador (Chromium)</text><rect x=\"40\" y=\"56\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a linguagem</text><text x=\"185.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">executada pelo motor V8</text><text x=\"185\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o hospedeiro acrescenta</text><rect x=\"40\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document</text><rect x=\"190\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">localStorage</text><rect x=\"40\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fetch</text><rect x=\"190\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setTimeout</text><rect x=\"370\" y=\"16\" width=\"330\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Node.js</text><rect x=\"390\" y=\"56\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a linguagem</text><text x=\"535.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">executada pelo motor V8</text><text x=\"535\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o hospedeiro acrescenta</text><rect x=\"390\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">process</text><rect x=\"540\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fs</text><rect x=\"390\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fetch</text><rect x=\"540\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setTimeout</text></svg>", "caption": "A linguagem é a mesma nos dois. Do que cada hospedeiro acrescenta, só os dois contornados em âmbar, fetch e setTimeout, existem nos dois.", "same": ["Node.js"]}
```

A linguagem do meio é a mesma. O que muda é o que cada hospedeiro acrescenta em volta. O navegador
dá ao seu programa a página, como `document`, e um jeito de guardar coisas para a próxima visita.
O Node dá o computador no lugar dela: arquivos, o processo em que o programa roda, um servidor de
rede. As aulas 11 e 12 tratam da metade do navegador, e o resto do curso é a linguagem. **Essa
divisão é proposital**: um curso posterior de Node precisa de tudo daqui, menos da página.

## Node: um arquivo e um comando

A primeira coisa a conferir em qualquer máquina é a versão do Node, de dentro de `~/js`, onde fica
o seu trabalho:

```
ana@dev:~/js$ node --version
v22.22.0
```

Um programa é um arquivo de texto terminado em `.js`. A ana escreve um com duas linhas:

```javascript
console.log("Hello from Node");
console.log(2 + 3);
```

`console.log` imprime o que recebe, e `node` executa o arquivo de cima para baixo:

```
ana@dev:~/js$ node hello.js
Hello from Node
5
```

Para uma expressão só existe um atalho. `node -p` avalia o que você passa e imprime o resultado, o
que ajuda a conferir como algo se comporta sem escrever um arquivo:

```
ana@dev:~/js$ node -p '2 ** 10'
1024
```

## O navegador: uma página e o seu console

No navegador, JavaScript chega dentro de uma página. Um elemento `<script>` guarda o código, e o
navegador o executa enquanto lê a página:

```html
<!doctype html>
<title>Hello</title>
<script>
  console.log("Hello from the browser");
  console.log(2 + 3);
</script>
```

Com um navegador na sua área de trabalho, você abriria esse arquivo e olharia o **console**, o
painel que as ferramentas de desenvolvedor do navegador reservam para mensagens dos scripts. Uma
transcrição de terminal não consegue mostrar uma janela, então este curso usa o comando `page` da
seção anterior. Ele serve `~/js` em `http://127.0.0.1:8080`, abre a página num Chromium de verdade
e imprime o que o console disse:

```
ana@dev:~/js$ page hello.html
Hello from the browser
5
```

As mesmas duas linhas, as mesmas respostas. **O que `page` imprime é o console do navegador, uma
mensagem por linha**, e a aula 22 abre o painel de verdade e o resto das ferramentas de
desenvolvedor.

## O mesmo arquivo, dois hospedeiros

Um script pode perguntar em que está rodando. `typeof` responde com o tipo de um valor, e um nome
que não existe responde `"undefined"` em vez de falhar:

```javascript
console.log(typeof process, typeof document);
```

```html
<!doctype html>
<script src="where.js"></script>
```

```
ana@dev:~/js$ node where.js
object undefined
ana@dev:~/js$ page where.html
undefined object
```

**O Node tem `process` e não tem `document`; o navegador, o contrário.** Todo o resto desta aula
funciona nos dois, e daqui em diante um programa roda no hospedeiro que deixar o ponto mais claro.
