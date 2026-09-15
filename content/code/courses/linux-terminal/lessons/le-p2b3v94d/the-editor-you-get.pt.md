---
title: `$EDITOR`, e o editor que outra coisa escolheu por você
version: 1
---

Metade das vezes em que você abre um editor, você não o abriu — alguma coisa o
abriu por você e está esperando.

```sh
git commit          # a message
git rebase -i       # a plan
crontab -e          # a schedule (lesson 13)
visudo              # sudoers, with a syntax check on the way out
sudoedit /etc/x     # a root-owned file, edited as you
systemctl edit x    # a unit override
```

**Qual editor esses abrem é decidido por duas variáveis de ambiente e uma cadeia
de recursos alternativos**, e conhecer a cadeia é a diferença entre dez segundos
confiantes e cinco minutos ruins.

## As variáveis

```
ana@vm:~$ echo "EDITOR=[$EDITOR] VISUAL=[$VISUAL]"
EDITOR=[] VISUAL=[]
```

Nenhuma das duas está definida aqui, que é o padrão numa máquina nova — e é por
isso que o que acontece a seguir surpreende as pessoas.

| | |
|---|---|
| `$VISUAL` | um editor de **tela cheia**. Consultada primeiro pela maioria dos programas |
| `$EDITOR` | qualquer editor, inclusive um editor de linha como o `ed` |

A distinção vem de quando alguns terminais não conseguiam fazer tela cheia. Hoje
são a mesma coisa e **definir as duas com o mesmo valor é o movimento honesto**.

## O que acontece quando nenhuma das duas está definida

```
ana@vm:~$ update-alternatives --display editor 2>&1 | head -6
editor - auto mode
  link best version is /bin/nano
  link currently points to /bin/nano
  link editor is /usr/bin/editor
  slave editor.1.gz is /usr/share/man/man1/editor.1.gz
  slave editor.da.1.gz is /usr/share/man/da/man1/editor.1.gz
```

No Debian e no Ubuntu existe um `/usr/bin/editor`, gerenciado pelo sistema de
alternativas da seção 32, e **aqui ele aponta para o nano**. Então um `$EDITOR`
não definido nesta máquina te dá o nano.

No Red Hat e no SUSE não existe uma alternativa `editor` e o recurso alternativo
normalmente é o `vi`. O mesmo comando, um editor diferente, dependendo da
distribuição — que é o argumento para não depender disso.

O `sudo update-alternatives --config editor` muda o padrão da máquina
interativamente.

## Definindo

```
ana@vm:~$ EDITOR=nano; export EDITOR; echo "EDITOR is now $EDITOR"
EDITOR is now nano
```

Isso dura até o shell sair. Para ficar, vai no arquivo de inicialização do seu
shell — seção 74:

```sh
# ~/.bashrc, or ~/.profile
export EDITOR=nano
export VISUAL=nano
```

**Defina de propósito, hoje, para qual dos três você escolheu.** O dia em que
você descobre qual editor o `git commit` abre não deve ser o dia em que você está
com pressa com doze arquivos no stage.

O `git` tem a sua própria, que ganha das duas:

```sh
git config --global core.editor nano
```

## O `visudo` e o `sudoedit`, que são especiais

Duas das ferramentas acima fazem mais do que abrir um arquivo, e as duas existem
porque editar o arquivo diretamente é perigoso.

**O `visudo`** edita o `/etc/sudoers` e **confere a sintaxe antes de instalar**.
O aviso da seção 65: um arquivo `sudoers` com erro de sintaxe pode trancar todos
os usuários para fora do `sudo` naquela máquina, e o `visudo` se recusa a
instalar um assim.

Ele usa o `$EDITOR` como qualquer outra coisa, e `sudo EDITOR=nano visudo` é a
grafia que te dá o nano — porque o `sudo` limpa o ambiente por padrão (seção 65),
então exportar no seu próprio shell não basta.

**O `sudoedit`** — também escrito `sudo -e` — é o jeito certo de editar um
arquivo que pertence ao root:

```sh
sudoedit /etc/hosts
```

Ele copia o arquivo para um temporário, roda o **seu** editor como **você** na
cópia, e então instala o resultado como root. Compare com o `sudo vim
/etc/hosts`, que roda o editor inteiro como root, com a sua configuração e
quaisquer plugins dentro dela, e com o `:!sh` a uma tecla de distância.

Para uma mudança de uma linha os dois funcionam. O `sudoedit` é o que está
correto.

## A cadeia, inteira

A maioria dos programas consulta, nesta ordem:

1. a configuração do próprio programa — `core.editor` para o git, `EDITOR` no `/etc/crontab`
2. `$VISUAL`
3. `$EDITOR`
4. um padrão compilado, ou o `/usr/bin/editor`, ou o `vi`

**O passo 4 é por que você nunca deveria chegar nele.** Ele é diferente em cada
distribuição e é o que produz o momento "como é que eu saio disto".

## Dois hábitos

**Defina `EDITOR` e `VISUAL` no seu profile.** Duas linhas, uma vez, em toda
máquina que você usa regularmente.

**Numa máquina que não é sua, confira antes de se comprometer com qualquer
coisa:**

```
ana@vm:~$ echo "${VISUAL:-${EDITOR:-nothing set}}"
nothing set
ana@vm:~$ which editor && readlink -f /usr/bin/editor
/usr/bin/editor
/usr/bin/nano
```

Dois comandos, e entre eles te dizem exatamente o que o `git commit` está prestes
a abrir: nada está definido, então o recurso alternativo se aplica, e o recurso
alternativo aqui resolve para o nano. O `${VISUAL:-${EDITOR:-…}}` é a expansão de
valor padrão da seção 152, aninhada — e é a mesma ordem de preferência que os
próprios programas usam.
