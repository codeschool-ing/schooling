---
title: fork, exec, exit, wait
version: 1
---

Não existe uma chamada de sistema que signifique *inicie um programa*. Existem duas, e elas fazem
metades diferentes do trabalho. Saber disso explica a árvore de processos, o zumbi, o órfão, e por
que o seu shell continua existindo depois de o comando que você rodou ter terminado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um diagrama de sequência com duas raias. O pai, bash, chama fork, que cria um filho que é uma cópia do bash. O filho chama exec e vira ls. O pai fica bloqueado no wait até o filho chamar exit, e então o pai define o código de saída e imprime um prompt.\"><defs><marker id=\"lc\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><path d=\"M200 76 L200 286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M500 118 L500 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M500 176 L500 286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"140\" y=\"44\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bash</text><rect x=\"430\" y=\"88\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">uma cópia do bash</text><rect x=\"440\" y=\"146\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ls</text><rect x=\"130\" y=\"288\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">$? = 0, prompt</text><path d=\"M206 92 L424 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc)\"></path><text x=\"350.0\" y=\"86\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">fork()</text><text x=\"500\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">exec()</text><text x=\"186\" y=\"200\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">wait() — bloqueado aqui</text><path d=\"M494 236 L206 244\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc)\"></path><text x=\"350.0\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">exit(0)</text><text x=\"200\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um processo</text><text x=\"500\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dois processos, um programa cada</text></svg>", "caption": "Rodar um comando são duas chamadas de sistema, e não uma. O intervalo entre o `fork` e o `exec` é onde o filho muda o que precisar antes de o programa novo carregar."}
```

## O `fork` faz uma cópia

Um processo chama `fork`, e **um segundo processo passa a existir** — uma cópia quase idêntica do
primeiro. Mesmo programa, mesmo conteúdo de memória, mesmos arquivos abertos, mesmo diretório de
trabalho. A única diferença que importa é o que o `fork` devolve: o filho recebe `0`, e o pai recebe
o PID do filho.

É assim que cada lado sabe qual dos dois ele é, e esse é o mecanismo inteiro.

## O `exec` substitui o programa

O filho então chama `exec`, que **joga fora o programa que estava rodando e carrega outro no mesmo
processo.** O PID não muda. O pai não muda. Os arquivos abertos em boa parte sobrevivem — e é por
essa porta que os redirecionamentos da seção 13 passam.

Então o `ls` no seu shell é: bifurque uma cópia do bash, e faça a cópia virar `ls`.

Parece desperdício e não é: o `fork` não copia a memória de verdade, ele a marca para ser copiada só
se um dos dois escrever. Bifurcar um programa que usa dois gigabytes custa quase nada até alguém
mudar alguma coisa.

**E as duas chamadas são separadas de propósito.** No intervalo entre elas — depois de a cópia
existir, antes de o programa novo carregar — o filho pode mudar a identidade dele, o diretório de
trabalho, a umask e os arquivos abertos. **É nesse intervalo que um redirecionamento acontece**, e
onde o `User=` de um arquivo de unit da aula 5 faz efeito. Uma chamada só, que fizesse as duas
coisas, não teria onde pôr nada disso.

## `exit` e `wait` também são duas metades

Um processo termina chamando `exit` com um número — o código de saída da seção 14. **O número
precisa ir para algum lugar**, e onde ele vai é o pai, que o recolhe chamando `wait`.

Até o pai recolher, o kernel mantém a entrada do filho na tabela de processos. Ela não tem memória,
nem arquivos abertos, nem programa: o que sobra é um PID e um número esperando ser lido. **Isso é um
zumbi**, e a seção 04 cria um de propósito.

Então o ciclo completo do `ls` num shell:

1. o bash **bifurca**. Agora existem dois bashes.
2. O filho dá **exec** no `/usr/bin/ls`. Agora ele é o `ls`.
3. o bash chama **wait** e bloqueia — e é por isso que seu prompt não volta.
4. O `ls` imprime, e **termina** com um código.
5. O `wait` do bash retorna com aquele código, põe no `$?`, e imprime um prompt.

**O passo 3 é tudo que o `&` muda.** Pôr um comando em segundo plano quer dizer que o bash não
espera — seção 10.

## Quando o pai não espera

Duas coisas podem dar errado no passo 5, e elas têm nomes diferentes e gravidades diferentes.

**O pai está vivo e não recolhe.** A entrada fica. Repita isso alguns milhares de vezes e a tabela
de processos enche, e a máquina não consegue iniciar nada. É esse o vazamento que a seção 08 da aula
5 atribuiu a um entrypoint de contêiner escrito à mão.

**O pai termina primeiro.** O filho agora é um **órfão**, e o kernel o entrega ao PID 1 — que não
está fazendo nada além de recolher, continuamente. Aqui está, numa transcrição:

```
ana@vm:~/work$ bash -c 'sleep 200 & echo child is $!'
child is 1230
ana@vm:~/work$ ps -eo pid,ppid,stat,comm | grep -E 'PID|sleep' | grep -v grep
  PID  PPID STAT COMMAND
 1230     1 S    sleep
```

O `bash` de dentro iniciou o `sleep` e terminou. O `sleep` continua rodando, e **o PPID dele agora é
`1`** — ele foi adotado enquanto ninguém olhava.

**Ficar órfão não é um erro.** É como um daemon passa a pertencer ao sistema — a segunda propriedade
da seção 07 da aula 5, e agora você viu acontecer.

## O que isso explica e nada mais explica

**Por que um filho não muda o diretório do pai.** Um `cd` num script não afeta o shell que rodou o
script, porque o script é um processo separado com a cópia dele. O `cd` precisa ser embutido no
shell — a seção 05 da aula 3 disse isso, e este é o motivo.

**Por que uma variável definida num subshell desaparece.** `( VAR=1 )` define numa cópia que depois
termina. A aula 9 volta a isso.

**Por que `exec ls` substitui o seu shell.** O bash tem um `exec` embutido que pula o fork: o shell
vira `ls`, e quando o `ls` termina não há shell para voltar. Seu terminal fecha. Tente uma vez, numa
janela que você não se importe de perder.
