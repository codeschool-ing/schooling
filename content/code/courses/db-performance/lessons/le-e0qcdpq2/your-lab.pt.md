---
title: Um banco lento só seu, e três maneiras de ter um
version: 1
---

Este curso se aprende medindo. Cada aula roda uma consulta, cronometra, lê o que o servidor fez,
muda uma coisa e cronometra de novo, e esses números aparecem para que você produza os seus e
compare. Então, antes do primeiro suspeito, um servidor de banco de dados no seu próprio
computador. **A plataforma não roda um para você**, e nada neste curso precisa de algo que você
mesmo não tenha instalado.

O motor é o **PostgreSQL 16**, dos pacotes do próprio Ubuntu, e o `psql` é o programa em que você
digita. Se você fez o `db-administration`, já tem um servidor como este, e a próxima seção só
acrescenta um banco a ele. Todas as transcrições do curso foram gravadas na configuração descrita
aqui.

O que este curso precisa não é bem o que os outros precisam. Um curso de SQL se contenta com
qualquer banco que funcione. **Este precisa de um banco lento**: grande o bastante para que um
plano ruim custe segundos, e não microssegundos, numa máquina cuja memória você conhece. Isso
elimina algumas opções, como dizem os três caminhos abaixo.

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Aqui isso pesa mais do que na
maioria dos cursos: você vai mudar configurações do servidor, encher o disco de propósito, abrir
duzentas conexões de uma vez e matar processos, e nada disso deve acontecer no computador em que
você trabalha.

O programa que roda a máquina é um **hipervisor**:

| seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux ou um Mac com processador Intel | VirtualBox, em virtualbox.org | grátis |
| um Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | grátis |

Os passos, uma vez só:

1. Instale o hipervisor e baixe a imagem de instalação do **Ubuntu Server 24.04 LTS** em
   ubuntu.com. No Apple silicon, pegue a versão ARM; em todo o resto, a marcada `amd64`.
2. Crie uma máquina nova a partir dessa imagem com **2 processadores, 4 GB de memória e um disco
   de 30 GB**.
3. Ligue-a e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor e um
   nome de usuário. Este curso chama o servidor de `vm` e o usuário de `ana`.
4. Quando ela reiniciar, entre. Você está num prompt como `ana@vm:~$`, e a próxima seção começa
   dali.

**O que custa ao seu computador:** 4 GB de memória enquanto a máquina roda, então o computador
precisa de 8 GB ou mais para ficar confortável, e uns 10 GB de disco depois que o banco do curso
estiver carregado e algumas aulas tiverem feito cópias dele. Com menos memória, dê 2 GB à
máquina: tudo continua funcionando e toda consulta fica mais lenta, o que já é uma lição (a aula 1
seção 06 mostra por quê).

> **Seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é o usuário e `vm` é a máquina; no seu
> são os nomes que você escolheu no passo 3. Todos os comandos são os mesmos.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu ou Debian**, dá para pular a máquina virtual: todo comando
deste curso funciona nele como está impresso. É o caminho mais barato em memória, e custa algo que
a máquina virtual não custa — os experimentos das aulas 15, 16 e 23 carregam o computador em que
você está trabalhando, e uma configuração do servidor esquecida fica esquecida.

No **macOS** (Postgres.app ou `brew install postgresql@16`) e no **Windows** (o instalador
indicado em postgresql.org) você tem o mesmo PostgreSQL 16 e o mesmo SQL. O que não bate é tudo
em volta: os comandos que reiniciam o servidor, onde fica o arquivo de configuração, como se sobe
um segundo servidor na aula 20 e como se instala um pooler de conexões na aula 16. Todo plano de
consulta do curso vai bater; um terço dos comandos de shell, não.

## On-line, no servidor de outra pessoa

Serviços de PostgreSQL hospedado entregam um banco e um endereço, e alguns têm um plano gratuito —
Neon e Supabase são dois, no momento em que isto é escrito. **Para este curso é o caminho mais
fraco**, e vale saber por quê antes de escolhê-lo:

- o banco do curso tem cerca de **1,3 GB**, mais do que a maioria dos planos gratuitos permite;
- metade das aulas muda configurações do servidor com `ALTER SYSTEM` ou reinicia o servidor, e um
  serviço hospedado não deixa o cliente fazer nenhuma das duas coisas;
- a máquina é um dos três suspeitos, e num serviço hospedado você não a enxerga.

Use-o para ler planos se os outros dois estiverem fora de alcance hoje, com um banco menor, e
planeje mudar. Nenhuma aula depende de fornecedor algum, e um plano gratuito é uma oferta de uma
empresa, que pode mudar seus limites quando quiser.

## Qual escolher

A máquina virtual, a menos que seu computador já rode Ubuntu. Custa uma tarde, uma vez, e compra a
propriedade em que este curso mais se apoia: **quando os seus tempos e os da transcrição diferem,
você sabe que a diferença é a máquina**, porque todo o resto é igual.
