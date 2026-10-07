---
title: Onde um segredo fica na máquina
version: 2
---

Fora do repositório, um segredo ainda precisa estar em algum lugar na máquina que roda o programa, e
"algum lugar" tem plateia. Dois lugares importam para o `shipquote`: o arquivo de onde o token é lido,
e o processo que o segura.

## O arquivo

A configuração da produção foi gravada com as permissões padrão de um arquivo novo:

```
ana@laptop:~/shipquote$ stat -c "%A %n" ~/envs/production/config.env
-rw-r--r-- /home/ana/envs/production/config.env
ana@laptop:~/shipquote$ chmod 600 ~/envs/production/config.env && stat -c "%A %n" ~/envs/production/config.env
-rw------- /home/ana/envs/production/config.env
```

`-rw-r--r--` quer dizer que o dono lê e grava, e **todo outro usuário da máquina lê**. Qualquer conta
naquele servidor, um agente de monitoramento, o serviço de outra equipe, um processo comprometido,
poderia ler o token da transportadora. `chmod 600` deixa leitura e gravação só para o dono:
`-rw-------`. A regra é curta: **um arquivo com um segredo só é legível pela conta que roda o
programa.** Em plataformas de contêiner o equivalente é um segredo montado como arquivo ou injetado
como variável pela plataforma, nunca embutido na imagem.

## O processo

Como um segredo chega ao processo também importa. Compare um token passado como argumento de linha de
comando com um passado no ambiente, como o `shipquote` faz. O primeiro é um processo Python que dorme
trinta segundos e não faz mais nada, iniciado em segundo plano com um token entre os argumentos:

```sh
python3 -c 'import time; time.sleep(30)' --carrier-token=lab-live-token &
```

Depois, dentro desses trinta segundos, o que qualquer pessoa na máquina consegue listar:

```
ana@laptop:~/shipquote$ ps -o args= -C python3 | grep "[c]arrier-token"
python3 -c import time; time.sleep(30) --carrier-token=lab-live-token
ana@laptop:~/shipquote$ ps -o args= -C python3 | grep -c "[S]HIPQUOTE_CARRIER_TOKEN"
0
```

O primeiro processo foi iniciado com o token como argumento, e o `ps` o imprimiu. **No Linux qualquer
usuário lista os argumentos de todo processo**, então um token numa linha de comando fica publicado
para a máquina inteira enquanto o processo roda, e muitas vezes também em históricos de shell e logs
de auditoria. O segundo comando conta os processos cujos argumentos mencionam
`SHIPQUOTE_CARRIER_TOKEN`, e não acha nenhum: o token do `shipquote` vive no ambiente dele, e o
`/proc/<pid>/environ`, que a aula 8 seção 03 leu, só é legível pelo dono do processo e pelo root.

## A ordem de preferência

Do mais seguro ao menos seguro, para um programa que precisa de um segredo:

1. buscado na partida num gerenciador de segredos, com uma credencial de vida curta (seção 09);
2. um arquivo legível só pela conta do programa, ou um segredo montado pela plataforma;
3. uma variável de ambiente, definida por quem inicia o processo;
4. um argumento de linha de comando: nunca.

Cada degrau abaixo aumenta a plateia. O laboratório usa o terceiro, por simplicidade, com o arquivo de
onde ele vem tornado privado.
