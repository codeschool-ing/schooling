---
title: A data que alguém escolheu por você
version: 1
---

Todo lançamento fixo tem um fim. Num dia decidido anos antes, quem o mantém para — e a máquina
continua funcionando, que é exatamente o que torna isso perigoso.

**Nada quebra no fim da vida.** O software roda, os serviços sobem, o site serve. O que para são as
atualizações de segurança, e a máquina vira uma coisa que acumula em silêncio vulnerabilidades
conhecidas, publicadas e sem correção, enquanto se comporta perfeitamente.

## As janelas

| | suporte padrão | com assinatura |
|---|---|---|
| **Ubuntu LTS** | 5 anos | 10, com Ubuntu Pro |
| **Ubuntu intermediário** (`24.10`) | 9 meses | — |
| **Debian stable** | ~3 anos, mais ~2 de LTS | — |
| **RHEL** | 10 anos | extensível |
| **Rocky, Alma** | acompanha o RHEL | — |
| **openSUSE Leap** | ~18 meses por versão | — |
| **Alpine** | 2 anos por lançamento | — |
| **Fedora** | ~13 meses | — |
| **contínuo** | não se aplica | — |

Dois deles merecem uma segunda olhada. **Os lançamentos intermediários do Ubuntu duram nove
meses**, que é menos que o plano de implantação de muita gente — instalar o `24.10` num servidor
por ser o mais novo é uma decisão com data de validade pendurada. E os **treze meses do Fedora** não
são defeito: o Fedora é onde as coisas se provam antes do RHEL, e ele diz isso.

## O que fazer a respeito, em ordem

**1 · Saiba a data.** O `/etc/os-release` te dá a versão; a distribuição publica a data. É um fato
sobre toda máquina que você opera, e pertence a onde quer que você guarde fatos sobre máquinas.

**2 · Planeje a atualização antes da data, não depois.** Mudar de uma versão maior para a próxima é
trabalho de verdade — formatos de configuração mudam, padrões mudam, um serviço é substituído. Leva
uma semana que você tem, ou um fim de semana que você não tem.

**3 · Reconstrua em vez de atualizar, quando puder.** Num mundo de contêineres e infraestrutura
como código, a resposta mais barata costuma ser construir uma máquina nova na versão nova e mover o
trabalho, em vez de atualizar no lugar. A antiga então é algo que você apaga, e não algo em que
você confia.

## Por que isso cai no seu colo

Porque a máquina não vai te avisar. Não há diálogo, não há contagem regressiva, e `apt upgrade` num
lançamento em fim de vida reporta que está tudo em dia — **o que é verdade e soa tranquilizador** —
e quer dizer apenas que nunca mais vem atualização nenhuma.

Esse é o formato honesto: o modo de falha de um ciclo de vida é o silêncio, e o mesmo vale para o
job agendado da aula 13 e o backup da aula 10. **Um sistema que parou de te proteger parece idêntico
a um que não tem nada a fazer.** Aprender a conferir coisas que não reportam nada é a maior parte do
que operação é.

## E o fato que data este curso

O CentOS 7 acabou em junho de 2024, depois de dez anos. Ele rodava uma parte enorme da internet.
Máquinas com ele continuam por aí — funcionando, servindo, recebendo nada — e as pessoas
responsáveis por boa parte delas não sabem que a data passou.

Essa é a seção inteira num exemplo, e é por isso que o reflexo da próxima seção é
`/etc/os-release` e não `uptime`.
