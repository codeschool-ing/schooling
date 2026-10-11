---
title: O Postman, e o seu trabalho guardado em arquivos
version: 1
---

**O Postman é um aplicativo de desktop que manda requisições HTTP e as guarda**, para que uma
requisição montada uma vez possa ser mandada amanhã exatamente como era. Tudo o que ele manda, o
curl mandou na lição 1. O que ele acrescenta é memória e uma janela: cada requisição fica salva com
um nome, a resposta aparece dividida em painéis, e as requisições de uma API ficam juntas numa
*coleção*. Também é a ferramenta que a maioria dos times de QA abre primeiro quando chega uma API
nova, o que já basta para valer a pena conhecê-lo.

Ele não é a API, e não é um framework de testes, embora consiga rodar testes. Uma requisição no
Postman é o mesmo texto na rede que o curl mandou, e o boxoffice não tem como saber qual programa
perguntou.

## Como conseguir

Baixe em postman.com, para Windows, macOS ou Linux. No Ubuntu o mesmo programa também é publicado
como snap, que se instala com uma linha:

```sh
sudo snap install postman
```

No Windows com WSL, instale a versão de Windows, e não a de Linux. O WSL repassa o `localhost` para
o Windows, então o Postman no Windows alcança o boxoffice rodando dentro do WSL em `localhost:8080`
sem configurar nada. Inicie o boxoffice no terminal dele, como na lição 1, antes de mandar qualquer
coisa.

**O plano gratuito pede que você entre com uma conta, e guarda as suas coleções na nuvem do
Postman.** Esse é o negócio do Postman, e os termos são dele para mudar: mudaram em 2023, quando o
Scratch Pad, o jeito de trabalhar sem conta, foi aposentado. Por isso este curso guarda toda coleção
como um arquivo JSON no seu próprio projeto, em `~/boxoffice/postman/`. Você salva os arquivos a
partir destas lições e os importa no aplicativo. Um arquivo é seu, seja qual for o plano amanhã: o
Newman o roda na lição 6 sem conta nenhuma, e o git guarda o histórico dele como o de qualquer outro
arquivo.

Crie o diretório agora, no seu primeiro terminal:

```sh
mkdir -p ~/boxoffice/postman
```

## Duas alternativas com as mesmas ideias

| ferramenta | o que é | onde guarda as suas requisições |
|---|---|---|
| **Bruno** | código aberto, desktop | como arquivos de texto puro numa pasta que você escolhe |
| **Insomnia** | da Kong, desktop | no seu computador ou na nuvem da Kong, como você escolher |

As duas têm coleções, ambientes e variáveis com esses nomes, e as duas importam um arquivo de
coleção do Postman. Tudo o que esta lição explica vale nelas; só os botões mudam de lugar. A escolha
do Bruno de guardar as requisições como arquivos no seu projeto é a mesma que este curso faz à mão
com o Postman.

## O que esta lição não consegue mostrar

**O Postman não foi executado para este curso.** A máquina de onde vem cada transcrição não tem
ambiente gráfico, e o Postman não roda sem um. Por isso as janelas dele são descritas em palavras
aqui, nunca desenhadas ou fotografadas, e toda afirmação sobre um arquivo é conferida num terminal,
com jq. O Postman também reorganiza a interface de tempos em tempos. Quando um botão não estiver
onde uma frase diz, procure pela palavra, não pela posição.
