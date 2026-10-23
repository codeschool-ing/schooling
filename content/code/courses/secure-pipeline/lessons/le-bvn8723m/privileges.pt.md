---
title: Nenhuma capability, e nenhum jeito de ganhar privilégios novos
version: 1
---

O sistema de arquivos agora é somente leitura; o processo ainda tem catorze capabilities ao alcance
e uma porta aberta para ganhar mais. Duas flags fecham as duas coisas. **`--cap-drop ALL` esvazia o
conjunto limite, e `--security-opt no-new-privileges` impede qualquer programa que o contêiner
execute de rodar com mais privilégio que o processo que o iniciou.** O linkbox não precisa de
capabilities nem de programas setuid, então deve rodar sem os dois, e o único jeito de saber se
roda é rodando:

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
e7393ee048afb52485649a7c3ee8779ab16d5ce797b22220b70bb4f3c4796285
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"5d32jw"}
ana@vm:~/linkbox$ docker exec linkbox python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
NoNewPrivs:	1
Seccomp:	2
Seccomp_filters:	1
```

**O serviço responde, e o status mudou em duas linhas.** `CapBnd` é zero: nenhum processo deste
contêiner jamais terá uma capability, nem um que rode como root. `NoNewPrivs` é 1, e não pode ser
desligado de dentro: o kernel deixa um processo ligá-lo e nunca desligá-lo, e todo processo iniciado
a partir dele o herda.

### Root sem capabilities

O valor de uma capability aparece quando o root a perde. Trocar o dono de um arquivo é uma operação
que o kernel permite a um processo com `CAP_CHOWN`, que o root tem por padrão:

```
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
chowned
ana@vm:~/linkbox$ docker run --rm --user 0 --cap-drop ALL --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import os; os.chown('/data', 0, 0); print('chowned')
               ~~~~~~~~^^^^^^^^^^^^^^^
PermissionError: [Errno 1] Operation not permitted: '/data'
```

**O mesmo comando, o mesmo usuário 0, e o kernel recusa quando a capability some.** É isso que o
conjunto limite quer dizer: o root num contêiner com `--cap-drop ALL` continua dono dos arquivos do
root, e pode lê-los e escrevê-los onde o sistema de arquivos deixar, mas não consegue fazer nada que
exija uma capability, de trocar um dono a escutar numa porta abaixo de 1024 ou abrir um socket raw.
Somado à raiz somente leitura, um processo iniciado com `--user 0` por engano consegue fazer pouco que
o 65532 não conseguiria.

A alternativa que alguns times usam é tirar tudo e devolver uma capability, como
`--cap-add NET_BIND_SERVICE` para um servidor que precisa escutar na porta 80. O linkbox escuta na
8000 e não precisa de exceção. **Cada `--cap-add` é uma linha que alguém deveria conseguir
justificar na revisão**, o que fica mais fácil quando o padrão é nenhuma.

### Contra o que o `no-new-privileges` protege

Um programa setuid roda como o dono dele, e não como o usuário que o iniciou; `passwd` e `sudo` são
os exemplos clássicos, do root para que um usuário comum faça uma coisa privilegiada por meio deles.
Uma file capability faz o mesmo para uma capability só. Qualquer um dos dois, presente numa imagem, é
um caminho do usuário 65532 para mais privilégio. Esta imagem não tem nenhum:

```
ana@vm:~/linkbox$ docker exec linkbox python3 -c "import os, stat; print([os.path.join(d, f) for d, _, fs in os.walk('/usr') for f in fs if os.path.isfile(os.path.join(d, f)) and os.stat(os.path.join(d, f)).st_mode & stat.S_ISUID])"
[]
```

Uma lista vazia para tudo sob `/usr`, que é como uma imagem distroless se parece. Então por que
ligar a flag? **Porque ela protege a próxima imagem, não esta.** Uma imagem base futura, um pacote
acrescentado às pressas, uma ferramenta de depuração copiada: qualquer um deles pode trazer um
arquivo setuid, e ninguém revisa os modos dos arquivos de uma imagem. A flag não custa nada a um
programa que nunca precisou de privilégios novos, e elimina a classe de erro, e não só o caso.

### Quatro controles, e o que cada um supõe

| controle | o que tira | o que supõe |
|---|---|---|
| `USER 65532` na imagem | root por padrão | ninguém passa `--user 0` |
| `--cap-drop ALL` | toda capability, para todo usuário | nada |
| `--security-opt no-new-privileges` | ganhar privilégio executando um arquivo | nada |
| `--read-only` e dois `tmpfs` | mudar os arquivos da imagem | nada |

A primeira linha é onde a maioria das imagens para, e é a única com uma suposição na última coluna.
As outras três valem seja qual for o processo e como quer que tenha sido iniciado, que é a
propriedade de que um controle no pipeline precisa.
