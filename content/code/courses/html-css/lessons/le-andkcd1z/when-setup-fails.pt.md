---
title: Quando a montagem não funciona
version: 1
---

A montagem é onde a maioria das pessoas para, em geral diante de uma mensagem que nunca viram. Estas três foram reproduzidas de propósito, e cada uma diz o que está errado para quem sabe lê-la.

## O terminal nunca ouviu falar do Node

```
ana@laptop:~/site$ node --version
bash: node: command not found
```

Ou o Node.js não está instalado, ou foi instalado depois que este terminal foi aberto. Um terminal lê a lista de lugares onde procura programas uma vez, quando começa. **Feche-o e abra outro** antes de reinstalar qualquer coisa. No Windows a frase é outra, *is not recognized as the name of a cmdlet*, e quer dizer o mesmo.

## O validador não é um comando sozinho

```
ana@laptop:~/site$ html-validate -f text skeleton.html
bash: html-validate: command not found
```

Isso está certo, e nada quebrou. O `npm install` pôs o validador dentro de `site/node_modules`, e não entre os programas do sistema, então o terminal não o acha pelo nome. **Quem o acha é o `npx`**: `npx html-validate -f text skeleton.html`.

## O npx se oferece para baixá-lo

```
ana@laptop:~$ npx html-validate --version
Need to install the following packages:
html-validate@11.16.2
Ok to proceed? (y) n
npm error canceled
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-07T10_46_24_037Z-debug-0.log
```

Olhe o prompt: `~`, e não `~/site`. O `npx` procura o programa na pasta em que você está, não o achou e se ofereceu para buscar a versão mais recente na internet. **Responda `n` e depois `cd site`.** Responder `y` funciona, e deixa você com um validador que não é o das gravações das aulas, e sem o `.htmlvalidate.json` que mora em `site`. A versão que ele oferece é a mais nova no dia em que você pergunta.

## Quatro que não foram reproduzidas aqui

**No Windows, uma página salva como `skeleton.html.txt`.** O Explorador de Arquivos esconde as extensões por padrão, e o Bloco de Notas acrescenta `.txt` a menos que você escolha *Todos os arquivos* ao salvar. A página abre no Bloco de Notas em vez do navegador. Ligue as extensões de nome de arquivo no menu **Exibir** do Explorador, e o nome verdadeiro aparece.

**Um clique duplo que abre o editor.** O seu computador decidiu que arquivos `.html` são do editor. Arraste o arquivo para uma janela do navegador, ou clique nele com o botão direito, escolha **Abrir com** e depois o seu navegador.

**Uma mudança que não aparece.** O navegador não vigia o arquivo. Salve no editor e depois recarregue a aba.

**O npm avisa de `EBADENGINE`.** O seu Node é mais velho do que o validador aceita. Instale a LTS atual a partir do nodejs.org e rode `npm install html-validate@11.16.2` de novo em `site`.
