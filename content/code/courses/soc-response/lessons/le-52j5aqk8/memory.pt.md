---
title: Memória
version: 1
---

Um disco guarda o que foi salvo. **A memória guarda o que estava rodando**: processos, conexões de rede, comandos
digitados, chaves de criptografia, documentos abertos e nunca salvos. A aula 13 coletou o estado volátil como
texto; um **dump de memória** é ele inteiro, em bytes, para analisar depois.

O laboratório mostra a ideia em um processo, o caso menor. Escreva isto como `holder.py`:

```schooling-example
{"language": "python", "file": "holder.py", "parts": [{"code": "# holder.py: a program holding a value in memory that it never writes anywhere\nimport os\nimport secrets\nimport time\n"}, {"code": "token = \"session-\" + secrets.token_hex(8)  # made here, kept only in this process", "note": "Um valor aleatório, criado quando o programa começa. Nunca é impresso, salvo ou enviado: a única cópia está na memória deste processo."}, {"code": "print(os.getpid(), flush=True)\ntime.sleep(600)", "note": "O programa imprime o id do processo, para o dump saber qual processo pegar, e depois espera dez minutos."}]}
```

Rode-o em segundo plano, e depois faça o dump da memória dele com o `gcore`, que vem com o depurador `gdb` (`sudo
apt install gdb`):

```
root@soc:~/case# python3 holder.py > holder.pid &
root@soc:~/case# cat holder.pid
6340
root@soc:~/case# gcore -o mem $(cat holder.pid) 2>&1 | tail -2
Saved corefile mem.6340
[Inferior 1 (process 6340) detached]
root@soc:~/case# ls -l mem.*
-rw-r--r-- 1 root root 7955232 Oct  7 21:05 mem.6340
root@soc:~/case# strings mem.* | grep -m 1 '^session-'
session-221150b3744351ae
root@soc:~/case# sha256sum mem.*
3fbb717e63f017d61330400fb6d99453b3e167f6309fb07647490de5d7570d47  mem.6340
```

O `gcore` escreve a memória do processo em `mem.` seguido do id do processo, quase 8 MB aqui. O `strings` extrai
toda sequência de caracteres imprimíveis, e o `grep` acha o valor: **ele nunca foi escrito num arquivo, e o dump o
tem**. O hash vai para o registro de custódia, como qualquer outra evidência. Pare o programa depois com
`kill $(cat holder.pid)`.

Para uma máquina inteira o princípio é o mesmo e as ferramentas são outras, e **nenhuma delas foi rodada aqui**:

| passo | Linux | Windows |
|---|---|---|
| adquirir toda a memória | AVML, LiME | WinPmem, DumpIt |
| analisar | Volatility 3 | Volatility 3 |

O **Volatility 3** lê uma imagem da memória inteira e responde perguntas com plugins: a lista de processos como o
kernel a via (`windows.pslist`, `linux.pslist`), as conexões de rede (`windows.netscan`), o histórico do shell
ainda na memória (`linux.bash`). Para imagens de Linux ele precisa de uma tabela de símbolos que corresponda
exatamente ao kernel, que é o obstáculo comum, e o motivo para preparar uma para cada padrão de servidor antes de
um incidente, não durante.

Duas regras decidem se a memória é capturada. **Ela vem primeiro**, antes de qualquer coisa que a encerre, como
diz a ordem de volatilidade da aula 13. E **a ferramenta de captura muda a memória que captura**, um pouco, por
estar rodando; o registro diz qual ferramenta rodou, quando, e de onde, para a mudança ser conhecida.
