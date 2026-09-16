---
title: Dependências, e os quatro jeitos de dar errado
version: 1
---

Um pacote declara do que precisa. O gerenciador lê cada declaração da máquina, mais cada uma dos
repositórios, e resolve para um conjunto que satisfaça todas ao mesmo tempo.

**Isso é um problema de satisfação de restrições de verdade**, que é por que às vezes ele diz algo
longo e estranho em vez de simplesmente fazer o que você pediu.

## As relações

| | |
|---|---|
| `Depends` | precisa estar instalado, e configurado antes |
| `Pre-Depends` | precisa estar **configurado** antes de este aqui ser sequer desempacotado |
| `Recommends` | instalado por padrão; seguro de recusar |
| `Suggests` | nunca instalado automaticamente |
| `Conflicts` | não pode estar instalado ao mesmo tempo que este |
| `Replaces` | assume arquivos que pertenciam a outro pacote |
| `Provides` | um nome virtual, para vários pacotes satisfazerem um requisito |

**O `Provides` é o que vale entender**, porque ele explica uma resposta que de outro modo parece
errada. O `cowsay` depende de `perl:any`, e vários pacotes fornecem `perl`. Uma dependência pode
nomear uma capacidade em vez de um pacote, e o solucionador escolhe algo que a ofereça.

Do lado rpm a mesma ideia vai mais longe: um pacote pode declarar `Requires: /bin/sh` — **um caminho
de arquivo, não um pacote** — e qualquer pacote que entregue aquele arquivo satisfaz isso.

## Vê-las antes de se comprometer

```
apt show thing                     # the Depends line
apt-cache depends thing            # what it needs, one per line
apt-cache rdepends thing           # what needs it — the reverse question
apt install --dry-run thing        # the whole plan, without doing any of it
```

**O `--dry-run` é o hábito que vale formar.** Ele imprime exatamente o parágrafo que a seção 04 te
ensinou a ler, e não muda nada. Numa máquina de produção é a diferença entre saber e descobrir.

O `rdepends` — dependências reversas — responde "o que quebra se eu remover isto", que é a pergunta
que você quer antes de digitar `apt remove` numa biblioteca.

## As quatro falhas

### 1. Meio instalado

Você usou o `dpkg -i` e a dependência não estava lá. O dpkg desempacota e se recusa a configurar,
deixando o pacote num estado em que os arquivos existem e ele não funciona. A seção 07 é essa por
inteiro, com o conserto.

### 2. Segurado

```
0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.
```

**`not upgraded` quer dizer que o apt decidiu não atualizar.** Normalmente porque atualizar uma coisa
exigiria remover outra, e o `upgrade` puro se recusa a remover. O `apt list --upgradable` os nomeia e
o `apt full-upgrade` tem permissão para fazer isso — depois de você ler o que ele tiraria.

O outro motivo é um hold deliberado, que é a seção 09.

### 3. Dependências não satisfeitas

```
The following packages have unmet dependencies:
 somepackage : Depends: libsomething (>= 2.0) but 1.9 is to be installed
```

Este é o solucionador te dizendo que não existe resposta válida. **Leia a restrição de versão**,
porque ela nomeia o problema: algo quer uma biblioteca mais nova do que os repositórios oferecem.
Isso normalmente quer dizer que um pacote de uma versão da distribuição foi instalado noutra — um
`.deb` de um Ubuntu mais novo, ou um repositório de terceiro que assumiu outra base.

O `apt --fix-broken install` conserta a versão disto que veio de uma instalação interrompida. Ele não
conserta a versão que vem de fontes genuinamente incompatíveis, e o conserto honesto ali é remover o
pacote que não pertence.

### 4. A dependência que ninguém quer mais

```
The following package was automatically installed and is no longer required:
  libtext-charwidth-perl
Use 'apt autoremove' to remove it.
```

O apt registra **por que** cada pacote está lá: porque você pediu, ou porque outra coisa precisava.
Remova a coisa que precisava e a dependência fica, marcada como indesejada, até o `autoremove`.

```
apt-mark showmanual        # what you asked for
apt-mark showauto          # what came in as a dependency
apt-mark manual thing      # "I want this even if nothing needs it"
```

**O `apt-mark manual` é o conserto de um acidente específico**: você instalou A, que trouxe B, você
passou a depender de B diretamente, e então removeu A. Marcar B como manual impede o próximo
`autoremove` de levá-lo.

## Remover remove mais do que você pediu

Este é o comportamento a conhecer antes de digitar `remove` numa biblioteca, e as duas famílias
fazem isso:

```
root@vm:~# dpkg -l cowsay libtext-charwidth-perl | tail -2
ii  cowsay                       3.03+dfsg2-8  all          configurable talking cow
ii  libtext-charwidth-perl:amd64 0.04-11build3 amd64        get display widths of characters on the
terminal
root@vm:~# apt-get remove --dry-run libtext-charwidth-perl
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  cowsay libtext-charwidth-perl
0 upgraded, 0 newly installed, 2 to remove and 168 not upgraded.
Remv cowsay [3.03+dfsg2-8]
Remv libtext-charwidth-perl [0.04-11build3]
```

**Pedi um pacote e o plano remove dois.** O `cowsay` depende dele, então tirar a biblioteca quer
dizer tirar o `cowsay` também — um gerenciador não vai conscientemente deixar um pacote com o
`Depends` insatisfeito. A seção 10 mostra o `dnf` fazendo a mesma coisa pelo mesmo motivo.

O `--dry-run` é por que isto é um parágrafo e não um incidente. E o `rdepends` é como você pergunta
antes mesmo de digitar `remove`:

```
root@vm:~# apt-cache rdepends libtext-charwidth-perl
libtext-charwidth-perl
Reverse Depends:
  debconf-i18n
  cowsay
  libtext-wrapi18n-perl
```

Três pacotes dependem dele e só um deles está instalado, que é por que o plano removeu um e não três.
**O `rdepends` lista tudo dos repositórios**, instalado ou não — então leia como "quem poderia se
importar", e use o `--dry-run` para "o que de fato aconteceria aqui".
