---
title: Como o Linux decide, entrada por entrada
version: 1
---

**O kernel não soma as entradas de um usuário. Ele acha a primeira classe que se aplica e para.** A
crença comum é que o acesso é a soma de tudo o que se aplica a você, a sua entrada de usuário mais
cada grupo de que faz parte. No Linux não é, e a diferença pode trancar do lado de fora a pessoa que
a regra queria ajudar ou, mais raramente, deixar entrar quem ela queria restringir.

A ordem é fixa, e é conferida de cima para baixo:

1. **Dono.** Se o arquivo é seu, os bits do dono decidem, e nada mais é olhado.
2. **Usuário nomeado.** Se há uma entrada para o seu usuário, ela decide, limitada pela máscara.
3. **Grupos.** Se o grupo dono ou algum grupo nomeado de que você faz parte está na lista, você recebe
   o acesso de qualquer um deles que conceda o que você pediu, limitado pela máscara; se todos
   recusam, você é recusado.
4. **Outros.** Só se nada acima se aplicou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-resolve\" aria-label=\"Como o Linux resolve uma ACL POSIX, em quatro perguntas feitas em ordem, parando no primeiro sim. Um: o usuário é dono do arquivo? Então a entrada do dono decide. Dois: há uma entrada com o nome do usuário? Então essa entrada, limitada pela máscara, decide. Três: o grupo dono ou um grupo nomeado é um dos grupos do usuário? Então o acesso é dado se alguma entrada de grupo que casa, limitada pela máscara, permitir, e recusado caso contrário. Quatro: senão, a entrada other decide. O exemplo: a auditora, no grupo que grava mas com uma entrada nomeada de leitura, para na pergunta dois e fica só com leitura.\"><defs><marker id=\"l06-resolve-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-resolve-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1  dono?</text><text x=\"300.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">user::</text><path d=\"M145.0 74.0 L145.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"20.0\" y=\"92.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2  usuário nomeado?</text><text x=\"300.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">user:auditoria:r--</text><path d=\"M145.0 136.0 L145.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"20.0\" y=\"154.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3  um dos meus grupos?</text><text x=\"300.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">group::rw-</text><path d=\"M145.0 198.0 L145.0 216.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"20.0\" y=\"216.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4  todos os outros</text><text x=\"300.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">other::---</text><rect x=\"470.0\" y=\"80.0\" width=\"230.0\" height=\"70.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a auditora pede para gravar</text><text x=\"585.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">para no 2: só leitura</text><text x=\"585.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o passo 3 nem é perguntado</text><path d=\"M470.0 115.0 L440.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-phosphor)\"></path><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os passos 2 e 3 são limitados pela máscara</text></svg>", "caption": "A primeira classe que se aplica decide. As entradas nunca são somadas."}
```

O passo que surpreende é o segundo. Ponha a auditora em `contabil`, o grupo que pode gravar, e peça a
ela para gravar num arquivo em que ela também tem uma entrada nomeada só de leitura:

```
ana@web:~$ sudo usermod -aG contabil auditoria && id auditoria
uid=1004(auditoria) gid=1005(auditoria) groups=1005(auditoria),1002(contabil)
ana@web:~$ echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt
tee: /srv/clientes/souza.txt: Permission denied
edited
ana@web:~$ sudo setfacl -x u:auditoria /srv/clientes/souza.txt && echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt
edited
```

Recusado. Ela está no grupo que grava, mas o kernel achou primeiro a entrada nomeada dela, no passo 2,
e parou ali: `r--`. Tire a entrada nomeada com `setfacl -x`, e o mesmo pedido chega ao passo 3, onde o
grupo concede gravação, e dá certo. **Uma entrada de usuário nomeado pode tirar acesso de alguém a quem
o grupo daria.** Isso a torna uma ferramenta precisa, o jeito de dizer "esta pessoa, só leitura, em
qualquer grupo em que entrar", e uma confusa, quando alguém põe um usuário num grupo e nada muda.

O passo 4 é onde todos os outros caem, e neste diretório ele está vazio:

```
ana@web:~$ sudo -u estagio ls /srv/clientes
ls: cannot open directory '/srv/clientes': Permission denied
```

A conta do estagiário, que a aula 1 travou e que está de volta neste laboratório novo, nem consegue
listar o diretório. São os bits e a ACL trabalhando juntos: `other::---` no diretório e em cada
arquivo dele, e nenhuma entrada para quem não precisa de uma.

## Lendo uma lista do jeito certo

Quando a pergunta é "esta pessoa consegue fazer isto", responda na ordem do kernel, com `getfacl` e
`id` lado a lado: a pessoa é a dona, há uma entrada com o nome dela, quais dos grupos dela aparecem e
o que a máscara permite. Na dúvida, pergunte ao sistema, como esta aula fez o tempo todo:
`sudo -u <usuário> test -r <arquivo>` responde para leitura sem mudar nada, e `-w` para gravação.
