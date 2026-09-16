---
title: PID 1, e por que houve uma briga
version: 1
---

O kernel dá boot, monta o sistema de arquivos raiz, e inicia **exatamente um programa**. Todo o
resto da máquina é descendente dele.

Esse programa é o processo 1, e a função dele é iniciar todo o resto, na ordem certa, e ficar
observando. Ele se chama *sistema de init*.

```
root@vm:~# ps -p 1 -o pid,comm
  PID COMMAND
    1 process_api
root@vm:~# ls -l /sbin/init
lrwxrwxrwx 1 root root 22 Jul 28 15:04 /sbin/init -> ../lib/systemd/systemd
```

**Nesta máquina o PID 1 não é um sistema de init.** É o supervisor de um runtime de contêiner,
porque isto é um contêiner e contêineres frequentemente rodam um programa sem init por baixo. É um
arranjo real e comum, e é a razão honesta de várias transcrições mais adiante nesta aula serem
desenhos — a nota da seção 10 diz isso onde importa.

A segunda linha é a interessante. **O `/sbin/init` aponta para o systemd**, exatamente como em
qualquer Ubuntu: o software está instalado e seria o processo um se esta máquina tivesse dado boot
normalmente. Não falta nada. Outra coisa foi iniciada primeiro.

## Três gerações, e o que cada uma consertou

**SysV init**, de 1983 e em uso até por volta de 2014. Um diretório de **scripts de shell**,
numerados, rodados um após o outro:

```
/etc/init.d/nginx start
/etc/rc3.d/S20nginx -> ../init.d/nginx
```

O `S20` é o projeto inteiro: `S` de start, `20` de ordem, e os scripts rodam em sequência
alfabética. É legível, depurável, e **lento** — um por vez, cada um esperando o anterior, e uma
máquina com quarenta serviços passa um bom tempo dando boot em nada em particular.

Pior, ele não fazia ideia do que tinha iniciado. Um script rodava, o script terminava, e se o daemon
continuava vivo não era problema de ninguém. Observar um serviço exigia uma segunda ferramenta.

**Upstart**, do Ubuntu, 2006–2014. Orientado a eventos em vez de ordenado: inicie isto quando a rede
aparecer, inicie aquilo quando um disco for montado. Resolveu o paralelismo e perdeu a discussão.

**systemd**, de 2010, e o padrão no Debian, Ubuntu, Red Hat, Fedora, SUSE e Arch. Três ideias, e
vale enunciá-las como ideias e não como veredito:

| | |
|---|---|
| **declare, não escreva script** | um arquivo de unit diz *o quê* — `ExecStart=`, `After=` — em vez de programar *como* |
| **dependências, não números** | `After=network.target` é um fato; `S20` é um palpite sobre um fato |
| **acompanhe o que você iniciou** | cada serviço ganha um cgroup, então o systemd conhece os processos dele e consegue parar todos |

Essa terceira é a silenciosa, e é a maior diferença prática. No SysV, parar um serviço era ler um
arquivo de PID e torcer. No systemd, os processos do serviço estão num grupo que o kernel mantém,
então o `systemctl stop` para também os que se bifurcaram para longe.

## A briga, contada com justiça

Foi barulhenta, durou anos, e os dois lados tinham razão em alguma coisa.

**Contra**: o systemd é grande, e cresceu muito além de iniciar serviços — logins, registro de logs,
configuração de rede, resolução de DNS, sincronização de hora, contêineres. A tradição Unix é de
ferramentas pequenas que se compõem, e o systemd não é isso. O log dele é binário em vez de texto, o
que põe uma ferramenta entre você e os seus dados pela primeira vez neste curso. E é uma
implementação só, em quase toda distribuição, num lugar em que um bug é um bug muito ruim.

**A favor**: o que ele substituiu era uma pilha de scripts de shell que cada distribuição tinha
reescrito de um jeito e ninguém tinha testado. Serviços agora se descrevem num arquivo que quer
dizer a mesma coisa em toda parte. A inicialização paralela tornou os boots mensuravelmente mais
rápidos. E o acompanhamento por cgroup fechou uma classe de bug que não tinha resposta limpa antes.

**O que decidiu não foi nenhum dos dois argumentos.** As distribuições adotaram, uma após a outra, e
as alternativas hoje são a escolha de especialista. O Devuan existe para quem quer Debian sem ele; o
Alpine usa OpenRC e é por isso que a aula 2 o mencionou; o Void usa runit. São reais e você
provavelmente não vai encontrar um.

**Aprenda systemd.** É o que está na máquina à sua frente. Os sete comandos da seção 09 são tudo de
que você precisa por muito tempo.

## O que o PID 1 faz, além de iniciar coisas

Duas tarefas que só o PID 1 consegue fazer, e as duas reaparecem neste curso:

**Ele adota órfãos.** Quando o pai de um processo termina, o filho é readotado pelo PID 1. É assim
que um daemon acaba pertencendo ao sistema — a segunda propriedade da seção 07 — e a seção 06 da
aula 6 desenha isso.

**Ele os recolhe.** Um processo terminado fica na tabela até o pai dele coletar o código de saída. O
pai de um órfão é o PID 1, e o PID 1 coleta continuamente. **Um init que não faz isso vaza
zumbis**, que é o bug mais comum num entrypoint de contêiner escrito à mão, e a seção 04 da aula 6 é
onde você encontra um.

É também por isso que o `docker run` tem o `--init`: ele insere um processo um minúsculo cuja única
função são essas duas coisas, porque o programa que você queria de fato rodar nunca foi escrito para
fazê-las.
