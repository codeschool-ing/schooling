---
title: No seu portfólio
version: 1
---

**Um release que ninguém encontra é uma pasta no seu disco.** O último passo é pô-lo onde as pessoas olham, e dizer
num minuto o que ele é. Três lugares, e cada um tem uma aula em outro ponto do catálogo que vai mais fundo que esta:

| onde | o que vai lá | a aula que trata disso |
|---|---|---|
| o README do repositório | o que o app é, uma captura de tela, como instalar, como gerar | `portfolio-project`, aula 16, "O README que faz entender o projeto em sessenta segundos" |
| uma página de release | os sete arquivos da seção anterior, e as notas | GitHub Releases, abaixo |
| o seu site de portfólio | o nome do app, uma imagem, um link para o release e para o código | `portfolio-project`, aula 15, "Deploy: camada gratuita, domínio, e algo que continue no ar" |

**O GitHub Releases é a página de release que a maioria dos projetos usa**: na página do repositório, **Releases,
Draft a new release**, escolha a tag `v0.3.0`, cole o `RELEASE-NOTES.md` como descrição, e anexe os arquivos. A
linha de comando `gh` faz o mesmo, `gh release create v0.3.0 --notes-file RELEASE-NOTES.md` seguido dos nomes dos
arquivos. *Não executado: o planner não tem repositório no GitHub.* Cada arquivo ganha então um endereço permanente,
que é também para onde o atualizador da aula 15 pode apontar, com o provedor `github` do electron-builder em vez do
`generic`.

## O que o README diz sobre o app

Quem lê um portfólio tem um minuto, e nesse minuto quer quatro coisas, nesta ordem:

1. **o que ele é**, numa frase que uma pessoa que nunca o viu entende;
2. **uma imagem** dele rodando, na plataforma para a qual você lançou; a aula 17 de `portfolio-project`, "Capturas
   de tela, vídeo de demonstração e dados que não sejam "teste teste"", trata de fazer essa imagem valer a pena;
3. **como obtê-lo**: o link do release, a linha de instalação de cada pacote, e como conferir a assinatura;
4. **como ele foi feito**: o caminho, com link para a sua nota de decisão, e o que não foi gerado nem testado.

**A quarta é a que um entrevistador pergunta.** "Por que Capacitor e não React Native" é uma pergunta que a sua nota
de decisão já responde, e "o que você faria diferente" é uma pergunta que uma retrospectiva escrita responde, e é ela
que a aula 21 de `portfolio-project` pede.

## Uma página na loja, se você fez uma

Se o app está no Google Play ou na App Store, a página da loja é uma segunda capa: ponha o link no README, e mantenha
as capturas e a descrição em dia com o release. **A política de privacidade e os formulários de dados da aula 14
precisam continuar verdadeiros**: um release que acrescenta um recurso que manda algo para fora do aparelho muda o
que esses formulários precisam dizer, antes de o release sair.
