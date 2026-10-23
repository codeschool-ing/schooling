---
title: O que um contêiner pode fazer por padrão
version: 1
---

A aula 8 entregou uma imagem sem shell, sem pip e com um usuário que não é root, e é tentador chamar
isso de contêiner endurecido. **É uma imagem endurecida. Como o contêiner roda é decidido por quem o
inicia**, com flags sobre as quais a imagem não tem voz, e os padrões do `docker run` são generosos.
A aula 21 de `docker` desmontou esses padrões num serviço próprio; esta aula aplica os mesmos
controles ao linkbox e depois os põe onde ninguém consegue esquecê-los, na execução de staging do
pipeline.

### Os padrões, perguntados

Construa a imagem se ela não estiver mais na sua máquina, e inicie do jeito que a aula 8 fez:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ docker build -q -t linkbox:dev .
sha256:141991c1adc92f6c8ae6a4603dd5612fb61b68f80ab5ff49473b06e99656f295
```

```
ana@vm:~/linkbox$ docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
153870da8e4e47c5990113744c7aef5e6d105476a8acf8ae36d2f822a7f2ded0
ana@vm:~/linkbox$ docker inspect --format 'read-only={{.HostConfig.ReadonlyRootfs}} cap-drop={{.HostConfig.CapDrop}} security-opt={{.HostConfig.SecurityOpt}} memory={{.HostConfig.Memory}} pids-limit={{.HostConfig.PidsLimit}}' linkbox
read-only=false cap-drop=[] security-opt=[] memory=0 pids-limit=<nil>
```

**Toda restrição que o Docker oferece está desligada.** O sistema de arquivos raiz é gravável,
nenhuma capability foi removida, nenhuma opção de segurança foi definida, e o contêiner pode usar
toda a memória e iniciar quantos processos a máquina permitir. Nada disso está errado para um teste
rápido; tudo isso é o que um contêiner em staging ou em produção herda, a menos que alguém escreva o
contrário.

### O que o processo tem

O kernel mantém um resumo de cada processo em `/proc/<pid>/status`, e as linhas que importam aqui
são o usuário, os conjuntos de capabilities, `NoNewPrivs` e `Seccomp`. A imagem não tem `grep`,
então uma linha de Python faz o filtro. Guarde numa variável do shell, porque a aula faz a mesma
pergunta a vários contêineres:

```
ana@vm:~/linkbox$ status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
ana@vm:~/linkbox$ docker exec linkbox python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
NoNewPrivs:	0
Seccomp:	2
Seccomp_filters:	1
```

Leia de cima para baixo. **`Uid` é 65532**, o usuário da imagem. Dos cinco conjuntos de
capabilities, dois importam aqui. `CapEff`, as capabilities que o processo pode usar agora, é zero:
um usuário comum não tem nenhuma. `CapBnd`, o conjunto limite, é `a80425fb`, as mesmas catorze
capabilities que a aula 21 de `docker` decodificou, entre elas `chown`, `setuid` e `net_raw`. O
conjunto limite é o teto: nenhum processo deste contêiner jamais terá uma capability fora dele, o
que quer que execute. `NoNewPrivs: 0` diz que executar um programa ainda pode elevar privilégios,
por um arquivo setuid ou por uma file capability. `Seccomp: 2` diz que há um filtro de chamadas de
sistema ativo, o perfil padrão do Docker, que a quarta seção desta aula examina.

Então o processo em si não tem privilégio, e **o contêiner em volta dele ainda mantém catorze
capabilities ao alcance** de qualquer coisa que rode como root ou por um arquivo setuid.

### O que ele consegue escrever

```
ana@vm:~/linkbox$ docker exec linkbox python3 -c "open('/tmp/dropped.py', 'w').write('print(1)'); print('written')"
written
ana@vm:~/linkbox$ docker exec linkbox python3 -c "open('/app/app.py', 'a')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    open('/app/app.py', 'a')
    ~~~~^^^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 13] Permission denied: '/app/app.py'
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

Um arquivo em `/tmp` é escrito sem reclamação, e ainda por cima um arquivo Python, que o `python3`
rodaria. O código da própria aplicação não pode ser mudado, porque pertence ao root e o processo é o
65532: o `COPY` sem `--chown` da aula 8 está cumprindo seu papel. **A defesa se apoia num fato só, o
usuário, e o usuário é um padrão que qualquer um pode trocar:**

```
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "$status"
Uid:	0	0	0	0
CapInh:	0000000000000000
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
NoNewPrivs:	0
Seccomp:	2
Seccomp_filters:	1
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a').write('# changed'); print('app.py changed')"
app.py changed
```

`--user 0` é uma flag, aceita por todo runtime de contêiner e todo orquestrador que roda esta imagem,
e com ela o processo é root com o conjunto limite inteiro efetivo, e reescreve o `app.py`. Nada na
imagem impede isso: `USER` num Dockerfile é o usuário com que um contêiner inicia **quando nada diz o
contrário**. Em implantações reais, o que diz o contrário raramente é um atacante: um manifesto
escrito às pressas por alguém tentando resolver um erro de permissão, uma sessão de depuração
iniciada como root e deixada rodando, um padrão da plataforma que ninguém mudou.

Por isso o resto desta aula aplica controles que não dependem do usuário. Um sistema de arquivos
somente leitura recusa a escrita de quem quer que peça. Um contêiner sem capabilities não tem
nenhuma para dar ao root. E a aula 10 acrescenta a única coisa que confere o usuário: o
`runAsNonRoot` do Kubernetes, que se recusa a iniciar um contêiner cujo usuário seja 0.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l09-layers\" aria-label=\"Os controles em volta do processo do linkbox, aninhados de fora para dentro: limites de memória e de processos; o filtro seccomp do Docker, o único ligado por padrão; uma raiz somente leitura com dois tmpfs; nenhuma capability e nenhum privilégio novo; e no centro o gunicorn como usuário 65532, o único controle que a própria imagem define e o que uma única flag desfaz.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"520\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">limites de memória e de processos</text><rect x=\"58\" y=\"58\" width=\"444\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">seccomp: o filtro padrão</text><rect x=\"96\" y=\"96\" width=\"368\" height=\"138\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"108\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">raiz somente leitura, tmpfs em /tmp e /data</text><rect x=\"134\" y=\"134\" width=\"292\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"146\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem capabilities, sem privilégios novos</text><rect x=\"185\" y=\"168\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">usuário 65532</text><text x=\"280.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">definido pela imagem; --user 0 desfaz</text><rect x=\"560\" y=\"120\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">ligado por padrão</text><rect x=\"560\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"586\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">desligado se ninguém pedir</text></svg>", "caption": "Só o filtro vem ligado sem pedir. Todo o resto é uma flag no comando que inicia o contêiner, e o anel mais interno é o que uma única flag remove."}
```
