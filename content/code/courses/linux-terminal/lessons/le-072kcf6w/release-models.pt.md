---
title: Fixo, LTS e contínuo
version: 1
---

Toda distribuição tem de responder uma pergunta: **quando você recebe versões novas de software?**
Existem três respostas, são trocas genuínas e não graus de qualidade, e a resposta que uma
distribuição dá é quase tudo o que ela é para conviver.

## As três

| | o que faz | você ganha | você abre mão de |
|---|---|---|---|
| **fixo** | versões congeladas no lançamento, só correções de segurança | uma máquina que se comporta igual por anos | software de um a três anos atrás |
| **LTS** | um lançamento fixo com janela bem mais longa | cinco ou dez anos do acima | o mesmo, por mais tempo |
| **contínuo** | atualiza sem parar; não existe versão | o software de hoje, sempre | uma máquina que muda embaixo de você |

**Debian stable, RHEL, Ubuntu LTS e openSUSE Leap são fixos.** Arch e openSUSE Tumbleweed são
contínuos. O Fedora é fixo com uma janela muito curta, o que o faz se comportar como algo no meio.

## O que "congelado" quer dizer de fato

Não quer dizer que nada muda. Um lançamento fixo continua recebendo **correções de segurança**, e é
esse o ponto inteiro: os mantenedores pegam a correção de uma vulnerabilidade e a aplicam na versão
antiga, em vez de entregar uma nova.

Isso se chama **backport**, e produz um fato que confunde as pessoas o tempo todo:

> Um scanner reporta que o seu `nginx 1.18` é vulnerável. O `nginx 1.18` da distribuição não é — a
> correção foi aplicada nele três semanas atrás, e o número da versão não se mexeu.

Então números de versão num lançamento fixo não são jeito confiável de julgar se um software está
corrigido, e uma ferramenta de segurança que só compara números vai reportar uma máquina cheia de
problemas que não existem. O gerenciador de pacotes sabe a verdade; a aula 7 é onde se pergunta.

## Por que alguém escolhe contínuo

Porque software antigo também não é de graça. Num lançamento fixo você está três anos atrás de um
runtime de linguagem, um banco tem um recurso que você não pode usar, e um bug que você encontrou
foi corrigido rio acima numa versão que você não vai ver até o próximo lançamento. Para a máquina
de um desenvolvedor, isso é um custo real.

O contínuo paga por isso com atenção: uma atualização pode mudar algo de que você dependia, numa
terça-feira, porque não há lançamento para segurar. **Isso está bem num laptop e é inaceitável em
quarenta servidores**, e é por isso que quase nada voltado a produção é contínuo.

## Números de versão que querem dizer algo

| | |
|---|---|
| `Ubuntu 24.04` | ano e mês — abril de 2024, e um LTS por ser abril de ano par |
| `Debian 12` | sequencial, mais ou menos a cada dois anos, cada um com um codinome de Toy Story |
| `RHEL 9.4` | maior ponto menor. O maior é uma linha de uma década; o menor é uma renovação dentro dela |
| `Alpine 3.20` | maior ponto menor, mais ou menos a cada seis meses |
| `Tumbleweed` | nenhum, e perguntar é a pergunta errada |

O que vale internalizar é o do Ubuntu, porque é o que você mais vai ler, e porque a data *é* o
número: `20.04` é antigo, `24.04` é atual, e dá para ver de relance sem consultar nada.

## Qual escolher

A seção 12 defende três casos direito. A versão comprimida:

- **Um servidor que outra pessoa mantém** — fixo, com a janela mais longa que você conseguir. Sem
  graça é a qualidade.
- **Sua máquina de desenvolvimento** — o que o seu time e a sua documentação assumem, o que na
  prática quer dizer Ubuntu LTS, a não ser que você goste da manutenção que o contínuo pede.
- **Uma imagem de contêiner** — a pergunta quase não se aplica. A imagem é reconstruída de uma tag
  a cada deploy, e o *pinning* da aula 7 é como você controla o que recebe.
