---
title: O caractere que você não vê
version: 1
---

Um arquivo de texto é uma sequência de linhas, e algo precisa marcar onde cada uma acaba. Existem
duas respostas, ambas dos anos 1960, e ninguém nunca as reconciliou:

| | termina a linha com | usado por |
|---|---|---|
| **LF** | um byte, `\n` | Linux, macOS, e todo protocolo que você vai encontrar |
| **CRLF** | dois bytes, `\r\n` | Windows |

O `\r` é um retorno de carro — a instrução que trazia o carro da máquina de escrever de volta para
a margem esquerda. O Windows ficou com os dois caracteres porque os teleimpressores de que ele
herdou precisavam dos dois. O Unix ficou com um.

**Isso seria curiosidade se o byte extra fosse ignorado. Ele não é ignorado — ele faz parte da
linha**, e um shell que lê uma linha lê o `\r` como conteúdo.

## Três formas em que a mesma falha aparece

Aqui está um script escrito duas vezes. Mesmo texto, mesmas permissões, finais de linha
diferentes.

### O interpretador que não existe

```
ana@vm:~/crlf$ ./unix.sh
hello
ana@vm:~/crlf$ ./windows.sh
bash: ./windows.sh: cannot execute: required file not found
```

**"Required file not found" — e o arquivo está bem ali.** O arquivo que falta não é o script. A
primeira linha de um script é `#!/bin/bash`, que nomeia o programa que deve executá-lo, e com CRLF
essa linha diz `/bin/bash\r`. O kernel procura um programa naquele caminho, retorno de carro
incluído, e não existe programa nenhum ali.

### O erro de sintaxe numa linha que está certa

```
ana@vm:~/crlf$ bash vars.sh
vars.sh: line 5: syntax error: unexpected end of file
```

Aquele script tem quatro linhas e o erro nomeia a linha 5. O bash leu `then\r` e `fi\r`, nenhuma
das quais é a palavra-chave que ele esperava, então, no que diz respeito a ele, o `if` nunca foi
fechado — e ele diz isso quando o arquivo acaba.

### A que funciona, que é a pior

```
ana@vm:~/crlf$ bash windows.sh
hello
```

O mesmo arquivo quebrado, executado nomeando o bash explicitamente, e ele imprime. O shebang é
pulado, nenhuma palavra-chave está envolvida, e o `\r` só viaja junto no fim do argumento. Vai
continuar funcionando até o dia em que um valor daquele arquivo for comparado com algo, ou usado
para montar um caminho — e aí vai falhar em outro lugar completamente.

**Uma causa, três caras, e a terceira é a que desperdiça um dia.**

## Como enxergar

O caractere é invisível por definição, então pergunte a um programa que reporta bytes em vez de
desenhá-los:

```
ana@vm:~/crlf$ file windows.sh unix.sh
windows.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
unix.sh:    Bourne-Again shell script, ASCII text executable
```

`with CRLF line terminators` é o diagnóstico inteiro, numa oração só, e o `file` é a primeira coisa
a buscar sempre que um script se comporta de forma impossível.

Para ver os bytes em si:

```
ana@vm:~/crlf$ cat -A windows.sh
#!/bin/bash^M$
echo "hello"^M$
```

O `cat -A` marca o fim de cada linha com `$` e mostra caracteres de controle. O `^M` é o retorno de
carro, sentado exatamente onde não deveria haver nada.

## Como consertar, e como impedir

```
ana@vm:~/crlf$ sed -i 's/\r$//' windows.sh
ana@vm:~/crlf$ ./windows.sh
hello
```

Esse é o `sed` da aula 8 chegando cedo: apague um retorno de carro no fim de cada linha, no próprio
arquivo. O `dos2unix` faz a mesma coisa com um nome mais simpático, quando está instalado.

**Impedir é melhor que consertar**, e há três portas por onde ele entra:

- **O seu editor.** Todo editor pode ser mandado gravar LF. O VS Code mostra `CRLF` ou `LF` na
  barra de status e deixa você clicar ali.
- **O git.** `git config --global core.autocrlf input` no Windows comita LF e deixa a sua cópia de
  trabalho em paz. Um repositório que tem os dois é um repositório onde todo diff é o arquivo
  inteiro.
- **O `/mnt/c` do WSL.** Arquivos editados do lado Windows carregam hábitos do Windows. Mantenha o
  trabalho em `/home/voce`, que a seção 04 já recomendou por velocidade e agora recomenda duas
  vezes.

## Por que isto é a seção 12 e não um apêndice

Porque é a primeira falha que o aluno encontra em que **a mensagem de erro descreve ativamente a
coisa errada**. "Required file not found" aponta para o arquivo que você está olhando, "syntax
error" aponta para uma linha que não existe, e a terceira cara não aponta para nada. Todo outro
erro desta aula diz o que quer dizer.

Conhecer o formato deste — *o arquivo parece certo e se comporta de forma impossível, então rode
`file` nele* — vale mais que a correção.
