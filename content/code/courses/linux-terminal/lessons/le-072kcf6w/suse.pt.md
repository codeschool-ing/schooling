---
title: SUSE, a terceira família
version: 1
---

Menor que as outras duas, mais velha que o Ubuntu, e a que você vai encontrar em lugares
específicos em vez de em geral: indústria, Europa de língua alemã, e quase todo lugar que roda SAP.

Merece uma seção curta em vez de longa — **porque se você dirige Red Hat, você quase dirige esta**,
e as diferenças são nomeáveis.

## Os três nomes

| | o que é |
|---|---|
| **SLE** | SUSE Linux Enterprise. O produto pago, com suporte longo — Server é `SLES`, Desktop é `SLED` |
| **openSUSE Leap** | grátis, construído das mesmas fontes que o SLE, e alinhado em versão com ele |
| **openSUSE Tumbleweed** | grátis, **contínuo** — sempre atual, nunca uma atualização de versão. Seção 29 |

O Leap e o SLE serem construídos das mesmas fontes é a parte útil: é a mesma relação que o Rocky
tem com o RHEL, arranjada de propósito pela SUSE em vez de reconstruída por voluntários.

## O que você digita

Pacotes `.rpm`, como no Red Hat, e uma ferramenta diferente na frente deles:

| | |
|---|---|
| instalar | `sudo zypper install nginx` |
| atualizar tudo | `sudo zypper update` |
| aplicar só correções | `sudo zypper patch` |
| buscar | `zypper search nginx` |
| atualizar o índice | `sudo zypper refresh` |

**O `zypper patch` é o que não tem equivalente em outro lugar.** O `update` leva pacotes a versões
mais novas; o `patch` aplica só as correções emitidas — segurança e bug — e deixa todo o resto onde
está. Numa máquina de produção essa é uma operação genuinamente diferente, e é o tipo de distinção
que uma distribuição corporativa existe para fazer.

## As duas coisas pelas quais a SUSE é conhecida

**O YaST**, uma ferramenta de configuração que cobre a máquina inteira — usuários, rede, serviços,
partições — numa interface só, com um modo texto que funciona por SSH. Nada nas outras famílias é
bem assim. Quem gosta sente falta em outros lugares; quem prefere editar o `/etc` na mão o acha
atravessado.

**Btrfs com snapshots por padrão.** A SUSE instala com um sistema de arquivos capaz de tirar
fotografias, e o liga ao gerenciador de pacotes: uma atualização tira uma foto antes, e uma máquina
que não dá boot depois pode ser revertida pelo menu de inicialização. É uma resposta de verdade
para um medo de verdade, e não é padrão em nenhum outro lugar.

## E AppArmor, não SELinux

A SUSE usa **AppArmor**, o mesmo arcabouço do lado do Debian, e não o SELinux do Red Hat. Que é o
fato entre famílias que vale carregar: **o arcabouço de segurança não acompanha o formato do
pacote.** SUSE e Red Hat usam `.rpm` os dois e discordam aqui.

## Onde você vai encontrar de fato

Se você nunca trabalhar com SAP ou com indústria europeia, possivelmente em lugar nenhum. Se
trabalhar, não vai encontrar outra coisa. Isso é uma coisa razoável de se saber sobre uma
ferramenta — nem toda família é uma para a qual você precisa estar pronto, e reconhecer o nome e o
gerenciador de pacotes basta até o dia em que não bastar.
