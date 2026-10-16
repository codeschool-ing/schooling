---
title: Um servidor seu, e três jeitos de ter um
version: 1
---

Este curso se aprende num servidor **que você tem permissão de quebrar**. A lição 5 edita o
arquivo de configuração, a lição 8 mata o servidor no meio de uma escrita, a lição 14 deixa o
autovacuum ficar para trás e a lição 20 faz o upgrade de tudo para uma nova versão maior. **A
plataforma não roda um servidor para você**, e nada no curso precisa de algo que você mesmo não
instale.

O servidor é o **PostgreSQL 16 no Ubuntu Server 24.04 LTS**, instalado pelos pacotes do próprio
Ubuntu. Toda transcrição do curso foi gravada exatamente nisso, numa máquina chamada `db` com um
usuário chamado `ana`. Há três jeitos de ter esse servidor. Um é o recomendado; os outros dois são
opções reais, com um custo que o primeiro não tem.

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, disco próprio e administrador próprio, que é você. Ela pode ser quebrada e jogada fora sem
encostar em mais nada do seu computador. Essa última propriedade é a que este curso precisa.

O programa que a roda é um **hypervisor**, e qual usar depende do seu computador:

| seu computador | hypervisor | custo |
|---|---|---|
| Windows, Linux, ou Mac com processador Intel | VirtualBox, em virtualbox.org | grátis |
| Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | grátis |

Os passos, uma vez só:

1. Instale o hypervisor e baixe a imagem de instalação do **Ubuntu Server 24.04 LTS** em
   ubuntu.com. No Apple silicon pegue a versão ARM; em qualquer outro, a marcada `amd64`.
2. Crie uma máquina nova a partir dessa imagem com **2 processadores, 4 GB de memória e um disco
   de 25 GB**.
3. Ligue-a e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor e um nome
   de usuário. Chame o servidor de `db` se quiser que seu prompt fique igual ao do curso; o nome de
   usuário é você quem escolhe, e você vai digitá-lo todo dia.
4. Quando o instalador oferecer instalar o **OpenSSH server**, aceite. Ele deixa você conectar do
   seu próprio terminal com `ssh`, que copia e cola muito melhor do que a janela do hypervisor.
5. Quando reiniciar, entre. Você está num prompt como `ana@db:~$`, e a seção depois desta começa
   daí.

**O que custa ao seu computador:** os 4 GB de memória enquanto a máquina roda, a atenção de dois
processadores e o disco que ela vai ocupando: alguns gigabytes para o Ubuntu e o PostgreSQL, e um
pouco mais a cada vez que uma lição adiante faz uma tabela crescer de propósito. Um computador com
8 GB de memória roda; com menos, dê 2 GB à máquina e espere que a conta da lição 6 dê números
menores que os do curso.

> **Seu prompt não vai dizer `ana@db`**, a não ser que você tenha escolhido esses nomes. Neste
> curso `ana` é o usuário e `db` é o servidor; no seu, são os nomes que você deu no passo 3. Todo
> comando é o mesmo.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu 24.04 ou Debian 12**, dá para pular a máquina virtual: todo
comando do curso funciona nele como impresso. É o caminho mais barato que existe, e tem um custo
que a máquina virtual não tem: o servidor que você quebra é o do computador em que você trabalha. A
lição 9 enche um disco; fazer isso no notebook é encher o disco do notebook.

No **macOS** (Postgres.app, ou o `postgresql@16` do Homebrew) e no **Windows** (o instalador
indicado em postgresql.org) o PostgreSQL em si é o mesmo, e tudo o que você faz dentro do `psql` —
papéis, grants, vacuum, estatísticas, mudanças de esquema — bate com o curso. O que não bate é tudo
em volta: onde ficam os arquivos, como o serviço sobe, para onde vai o log e quem é o primeiro
usuário. As lições 3 a 5, 9 e 19 não vão se parecer com a sua tela.

## Online, no servidor de outra pessoa

Um serviço de PostgreSQL hospedado dá a você um banco e um endereço, e vários têm um plano
gratuito. **Não custa nada ao seu computador**, e precisa de uma conta e de uma conexão.

É o mais fraco dos três para este curso especificamente, e a seção anterior diz por quê: sem shell,
sem arquivos, sem log, sem superusuário. Dá para seguir as lições 11 a 17 e a 22 nele, e quase nada
além disso. Um plano gratuito também é uma oferta de uma empresa, e ofertas mudam seus limites e
seus termos. **Nenhuma lição depende de provedor algum**, e se este for o único caminho aberto para
você hoje, use-o para começar e passe para uma máquina virtual quando puder.

## Qual escolher

A máquina virtual, a não ser que seu computador já rode Ubuntu. Ela custa uma tarde, uma vez só, e
compra a propriedade que falta às outras: **quando sua tela e a transcrição discordam, a diferença
está no que você digitou**, e não em qual sistema você está.
