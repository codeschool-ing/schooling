---
title: O build é a renderização
version: 1
---

**A geração estática renderiza cada página uma vez, enquanto o site é construído, e escreve cada
uma num arquivo.** Dali em diante uma requisição é atendida entregando esse arquivo. Nenhum programa
roda por requisição, nada é lido de um banco de dados, e o servidor na frente dos arquivos pode ser
a coisa mais simples que uma hospedagem oferece. É a terceira resposta à pergunta da aula 1 sobre
onde o HTML é feito: no seu computador ou na CI, antes de alguém pedir.

A ideia comum é que sites estáticos servem para blogs e documentação, e apps de verdade precisam de
servidor. A linha não é o tipo de site. É **se uma página pode ser igual para todo mundo por algum
tempo**. Um catálogo de cursos, uma página de produto, uma página de preços e um artigo de ajuda se
encaixam, mesmo dentro de um app grande; uma página que mostra a uma pessoa logada os seus próprios
dados nunca se encaixa.

## O que uma página estática compra

Cada item abaixo é algo que a aula 1 mediu ou nomeou, agora no seu custo mais baixo:

- **a primeira resposta carrega a página**, como na renderização no servidor, então crawlers,
  prévias de link e um celular lento recebem o conteúdo de uma vez;
- **o tempo antes do primeiro byte é o tempo de ler um arquivo**, sem renderização nele;
- **qualquer cache pode guardá-la**, porque o mesmo endereço dá os mesmos bytes a todo mundo, e é
  sobre isso que a aula 9 constrói;
- **hospedar é uma pasta de arquivos**, que toda hospedagem serve e muitas servem de graça.

## Quanto custa

**Uma página estática é uma fotografia dos dados no momento do build.** Mude os dados e a página
fica errada até o site ser construído de novo. Toda técnica depois das duas primeiras seções desta
aula é sobre esse custo: por quanto tempo uma página pode ficar errada, quanto build custa
corrigi-la, e quem percebe primeiro.

O outro custo é o próprio build, que renderiza todas as páginas, todas as vezes. Três páginas não
custam nada. Uma loja com cem mil produtos leva muito tempo, e a seção "O que fica velho, e quanto
custa um novo build" mede como o tempo cresce com o número de páginas, no planner.

## O vocabulário

A mesma ideia tem vários nomes, e vale separá-los antes de os frameworks usarem todos:

| termo | o que quer dizer aqui |
|---|---|
| **geração estática**, SSG | renderizar páginas no build, em arquivos |
| **pré-renderização** | o mesmo, dito de uma página ou rota; é como os quatro frameworks chamam nas suas opções |
| **regeneração** | renderizar de novo uma página estática depois do build, com o site rodando |
| **regeneração estática incremental**, ISR | regenerar uma página de cada vez, quando ela é pedida depois de uma certa idade, servindo a cópia velha enquanto isso |
| **revalidação sob demanda** | regenerar porque algo disse que os dados mudaram, e não porque o tempo passou |

Os dois depois do primeiro são o motivo de esta aula existir. Eles deixam uma página continuar
sendo um arquivo e ainda assim não ficar errada por muito tempo.
