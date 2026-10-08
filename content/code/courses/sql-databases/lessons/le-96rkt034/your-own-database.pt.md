---
title: Um banco de dados seu, e três jeitos de ter um
version: 1
---

Este curso se aprende digitando. Cada aula mostra uma consulta e o que voltou, e o motivo de
mostrar o que voltou é que você rode a mesma consulta e compare. Então, antes do modelo, um
servidor de banco de dados no seu próprio computador. **A plataforma não roda um para você**, e
nada neste curso precisa de algo que você mesmo não instale.

O motor é o **PostgreSQL 16**, e o `psql` é o programa em que você digita. Toda transcrição do
curso foi gravada com eles. O PostgreSQL é gratuito, roda em qualquer sistema que você provavelmente
tenha, e é o mais rigoroso dos motores comuns com o que aceita — o que você quer enquanto está
aprendendo quais são as regras. A aula 12 o compara com MySQL, MariaDB e SQLite.

Há três jeitos de tê-lo. Um é o recomendado, e os outros dois são opções de verdade, com um custo
que o primeiro não tem.

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Rode o **Ubuntu Server 24.04
LTS** numa delas, instale o PostgreSQL pelos pacotes do próprio Ubuntu, e você tem exatamente o
sistema em que este curso foi gravado: o que você vê deve bater com as transcrições em tudo, menos
números de versão, tempos e o nome no prompt.

O programa que roda a máquina é um **hipervisor**, e qual usar depende do seu computador:

| seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux, ou um Mac com processador Intel | VirtualBox, em virtualbox.org | gratuito |
| um Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | gratuito |

Os passos, uma vez só:

1. Instale o hipervisor e baixe a imagem de instalação do Ubuntu Server 24.04 LTS em ubuntu.com.
   No Apple silicon, pegue a versão ARM; em todo o resto, a marcada `amd64`.
2. Crie uma máquina nova a partir dessa imagem com **2 processadores, 2 GB de memória e um disco
   de 20 GB**.
3. Ligue-a e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor e um nome
   de usuário — escolha nomes de que vá lembrar, porque o usuário você vai digitar todo dia.
4. Quando ela reiniciar, entre com esse usuário e a senha. Você está num prompt como `ana@vm:~$`,
   e a próxima etapa começa daí.

**O que custa ao seu computador:** os 2 GB de memória enquanto a máquina roda, e o disco que ela
vai ocupando — alguns gigabytes para o Ubuntu, mais uns 300 MB quando a aula 9 carregar a loja
grande. A primeira instalação demora, e a maior parte é esperar o instalador.

> **Seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é o usuário e `vm` é a máquina; no seu
> são os nomes que você escolheu no passo 3. Todo comando é o mesmo.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu ou Debian**, pule a máquina virtual: os comandos da próxima
etapa funcionam nele exatamente como estão impressos. É o caminho mais barato que existe.

No **macOS**, o Postgres.app (postgresapp.com) e o Homebrew (`brew install postgresql@16`)
instalam o PostgreSQL 16. No **Windows**, o instalador indicado em postgresql.org faz isso. Os três
custam algumas centenas de megabytes e um servidor rodando em segundo plano. O que eles não dão
são os mesmos passos de configuração. Cada um cria o primeiro usuário do seu jeito: o do Windows
pede uma senha para um usuário chamado `postgres`, e você se conecta com `psql -U postgres`. Então
as duas próximas etapas não vão bater com o que você vê. Tudo do fim desta aula em diante,
que é SQL, vai.

## Online, no servidor de outra pessoa

Serviços de PostgreSQL hospedado dão a você um banco e um endereço para se conectar, e vários têm
um plano gratuito — Neon e Supabase são dois, quando isto foi escrito. **Não custa nada ao seu
computador**, e precisa de uma conta e de conexão.

Use para começar se os outros dois estiverem fora de alcance hoje, e planeje mudar. Um plano
gratuito é uma oferta de uma empresa, e ofertas mudam seus limites e seus termos; a loja grande da
aula 9 pode não caber num deles; e a aula 10 precisa de configurações do servidor que só o dono de
um servidor pode mudar. Nenhuma aula deste curso depende de provedor algum.

## Qual escolher

A máquina virtual, a não ser que o seu computador já rode Ubuntu. Custa uma tarde, uma vez, e
compra a única propriedade que os outros não têm: **quando a sua tela e a transcrição discordam, a
diferença está no que você digitou**, e não em qual sistema você está.
