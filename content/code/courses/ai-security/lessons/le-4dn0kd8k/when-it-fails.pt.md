---
title: Quando a instalação falha
version: 1
---

Quatro falhas respondem pela maior parte, e **cada uma se apresenta na primeira linha que imprime**. As
quatro foram produzidas na máquina em que estas aulas foram gravadas, a primeira por acidente e as
outras fazendo a coisa errada de propósito. Uma quinta, a memória acabar, vem no fim.

## O instalador para antes de começar

```
ana@lab:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O download do Ollama é comprimido com `zstd`, e um Ubuntu recém-instalado não o tem. Isto aconteceu de
verdade na primeira vez que este curso foi montado, e é por isso que o `zstd` está na linha do
`apt-get`. Instale-o, como a mensagem diz, e rode o instalador de novo.

## Nada responde

```
ana@lab:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@lab:~/guard$ guard ask "Say hello in five words."
ask: cannot reach http://localhost:11434/v1 ([Errno 111] Connection refused). Is Ollama running?
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    56 minutes ago    
```

As duas dizem a mesma coisa de dois jeitos: o programa que serve o modelo não está rodando, então nada
escuta em `localhost:11434`. O instalador o transformou num serviço, e um serviço pode ser parado, ou
nunca ter subido numa máquina que ligou sem ele. Suba-o e confira:

```sh
sudo systemctl start ollama
```

O último `ollama list` acima é de depois que ele voltou. (A máquina de onde vêm as transcrições não tem
`systemd`, então lá o servidor foi subido à mão. No Ubuntu e no WSL, o comando é o `systemctl`.)

Não o suba com `ollama serve` como você mesmo. Funciona, e serve um conjunto de modelos diferente e
vazio: os da sua pasta pessoal, e não os do serviço, onde o `ollama pull` pôs o `llama3.2:3b`. O modelo
então parece ter sumido.

## O modelo não está lá

```
ana@lab:~/guard$ ASK_MODEL=lama3.2:3b guard ask "Say hello in five words."
ask: http://localhost:11434/v1 answered 404: {"error":{"message":"model 'lama3.2:3b' not found","type":"not_found_error","param":null,"code":null}}
```

O servidor está de pé e não tem modelo com esse nome. Aqui é um erro de digitação, `lama` em vez de
`llama`, feito na variável `ASK_MODEL`. O outro jeito de receber esta mensagem é esquecer o
`ollama pull`. O `ollama list` mostra os nomes exatos que você tem, e são esses os nomes que o
`guard ask` e o `ollama run` aceitam.

## O `guard` não roda

```
ana@lab:~/guard$ guard surface
bash: line 1: guard: command not found
ana@lab:~/guard$ guard surface
bash: line 1: /home/ana/guard/bin/guard: Permission denied
ana@lab:~/guard$ guard sufrace
guard: no tool named 'sufrace' in ~/guard/tools
```

Três mensagens diferentes, de três erros diferentes:

- `command not found` é um terminal aberto antes de as duas linhas entrarem no `~/.bashrc`, então o
  `PATH` dele não inclui `~/guard/bin`. Abra um terminal novo, ou digite `source ~/.bashrc` no que você
  tem. Se isso não resolver, `tail -2 ~/.bashrc` mostra se as linhas estão lá.
- `Permission denied` é o `bin/guard` salvo sem `chmod +x`: o arquivo está lá e o shell não o roda.
- `no tool named` vem do próprio `guard`, que rodou e não achou programa com esse nome em
  `~/guard/tools`. Ou o nome está errado, como aqui, ou a aula que imprime o programa ainda não foi
  feita. `ls ~/guard/tools` lista o que você tem.

## E a memória do computador acaba

Se o modelo fica lento a ponto de não servir, ou o computador inteiro trava enquanto ele responde,
compare a memória que o `ollama ps` informa com o que o computador tem livre com todo o resto aberto.
Fechar um navegador costuma liberar mais do que o modelo precisa. Se mesmo assim não couber, use o
`llama3.2:1b` como descrito acima.

Se falhar algo que não está aqui, **leia o primeiro erro que ele imprimiu antes de qualquer outra coisa.**
As linhas depois dele costumam ser consequências.
