---
title: Uma árvore, sem letras de unidade
version: 1
---

No Windows um caminho começa com uma letra: `C:\Users\ana\notas.txt`. A letra diz em qual disco
físico o arquivo está, e existe um espaço de nomes por disco.

O Linux não tem letras de unidade. **Existe exatamente uma árvore, ela começa em `/`, e todo disco
da máquina aparece em algum lugar dentro dela.**

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Leia as duas pontas dessa linha juntas: `/dev/vda` é um disco — uma entrada em `/dev`, exatamente
como a seção 09 descreveu — e `/` é **onde na árvore ele foi pendurado**. O disco não é a árvore.
Ele está pendurado num galho dela.

## Montar é pendurar um disco num diretório

O verbo é *montar*, e é a ideia inteira. Você pega um sistema de arquivos — um disco, uma partição,
um pendrive, um compartilhamento em outra máquina — e diz **em qual diretório existente ele deve
aparecer**. A partir daquele momento, abrir aquele diretório abre o disco.

Então um segundo disco numa máquina Linux não vira `D:`. Ele vira um diretório, e quem montou a
máquina escolheu qual:

| o disco | pode aparecer em |
|---|---|
| um segundo drive interno | `/data`, `/srv`, `/home` |
| um pendrive que você espetou | `/media/ana/KINGSTON` |
| um compartilhamento em outra máquina | `/mnt/backups` |
| o disco do Windows, dentro do WSL | `/mnt/c` |

A aula 3 faz isso direito — `mount`, `lsblk`, o que acontece quando um disco não está lá. O que
importa agora é o formato.

## O que o formato muda para você

**Um caminho nunca diz qual disco.** `/srv/dados/relatorio.csv` é um endereço completo e sem
ambiguidade, e nada nele te diz se aquilo mora no drive principal, num segundo, ou em outra máquina
inteira. Isso é de propósito: **um programa não deveria ter de se importar, e não se importa.**
Mover os dados para um disco maior é trabalho de quem opera a máquina, e nenhum caminho, script ou
programa muda.

No Windows a letra faz parte do endereço, então a mesma mudança quebra todo caminho que dizia `D:`.

**Há um lugar só para procurar.** `cd /` e tudo na máquina está abaixo de você. Não existe "em qual
drive aquilo estava", porque não existe outra árvore para procurar.

**E as letras nunca foram estáveis mesmo.** Uma letra de unidade do Windows é atribuída na ordem em
que as coisas são encontradas, então o mesmo pendrive é `E:` numa máquina e `G:` em outra. Um ponto
de montagem é um nome que alguém escolheu, escrito num arquivo de configuração, e é o mesmo em todo
boot.

## Onde isso morde um iniciante

**`/` não é `/home`.** A raiz da árvore não é o seu diretório pessoal. O `~` (a sua casa) é um
diretório *dentro* da árvore, normalmente em `/home/seunome`, e os dois são confundidos o tempo
todo. A seção 13 desenha o mapa.

**Um diretório vazio pode ser um disco montado.** Se nada estiver montado em `/mnt/backups`, ele é
só um diretório vazio comum, e escrever ali escreve no disco principal. A aula 11 tem a versão
disso que custa dinheiro: um job de backup escrevendo feliz num ponto de montagem de onde o disco
caiu.

**E no WSL são duas árvores, não uma.** A sua casa Linux é `/home/voce` e o Windows fica em
`/mnt/c` — montado, como tudo o mais. Funciona, é mais lento, e os arquivos que você guardar lá
carregam finais de linha do Windows. A seção 12 é exatamente sobre isso.
