---
title: Quando a preparação falha
version: 1
---

Cinco falhas respondem pela maior parte, e cada uma se apresenta na primeira linha que imprime. As
cinco foram produzidas na máquina em que estas lições foram gravadas, fazendo a coisa errada de
propósito. Uma sexta, a falta de memória, vem no fim.

## O instalador para antes de começar

```
ana@lab:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O Ollama vem comprimido com `zstd`, e um Ubuntu recém-instalado não o tem. Esta aconteceu de verdade
na primeira vez que este curso foi montado, e é por isso que o `zstd` está na linha do `apt-get`.
Instale-o, como a mensagem diz, e rode o instalador de novo.

## Nada responde

```
ana@lab:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@lab:~$ ask "Say hello in three words."
ask: cannot reach http://localhost:11434/v1 ([Errno 111] Connection refused). Is the model server running?
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED    
llama3.2:3b    a80c4f17acd5    2.0 GB    2 hours ago    
```

As duas dizem a mesma coisa de dois jeitos: o programa que serve o modelo não está rodando, então
nada escuta em `localhost:11434`. O instalador o transformou num serviço, e um serviço pode ser
parado, ou nunca iniciado por uma máquina que ligou sem ele. Inicie-o e confira:

```sh
sudo systemctl start ollama
```

O último `ollama list` acima é de depois que ele voltou. (A máquina das transcrições não tem
`systemd`, então lá o servidor foi iniciado pelo script que as grava. No Ubuntu e no WSL, o comando é
`systemctl`.)

Não o inicie com `ollama serve` como você mesmo no lugar disso. Funciona, e serve um conjunto de
modelos diferente e vazio: os da sua pasta pessoal e não os do serviço, onde o `ollama pull` pôs o
`llama3.2:3b`. Aí o modelo parece ter sumido.

## O modelo não está lá

```
ana@lab:~$ ASK_MODEL=lama3.2:3b ask "Say hello in three words."
ask: http://localhost:11434/v1 answered 404: {"error":{"message":"model 'lama3.2:3b' not found","type":"not_found_error","param":null,"code":null}}
```

O servidor está de pé e não tem modelo com esse nome. Aqui é um erro de digitação, `lama` no lugar
de `llama`, feito na variável `ASK_MODEL`. O outro jeito de ver esta mensagem é esquecer o
`ollama pull`. O `ollama list` mostra os nomes exatos que você tem, e são esses nomes que o `ask` e o
`ollama run` aceitam.

## Um programa não roda

```
ana@lab:~/pe$ toylm info
bash: line 1: /home/ana/pe/bin/toylm: Permission denied
ana@lab:~/pe$ chmod +x ~/pe/bin/toylm
ana@lab:~/pe$ toylm info | head -1
corpus:        761 words in corpus.txt
ana@lab:~/pe$ toylm info
bash: line 1: toylm: command not found
ana@lab:~/pe$ tail -2 ~/.bashrc
# prompt-engineering
export PATH="$HOME/pe/bin:$HOME/pe/.venv/bin:$PATH"
```

O primeiro é um programa salvo sem `chmod +x`: o arquivo está lá e o shell se recusa a rodá-lo. O
segundo é um terminal aberto **antes** de as duas linhas entrarem no `~/.bashrc`, então o `PATH`
dele não inclui `~/pe/bin`. Abra um terminal novo, ou digite `source ~/.bashrc` no que você tem. Se
isso não resolver, as duas últimas linhas do `~/.bashrc` são as que você confere.

## E o computador fica sem memória

Se o modelo fica lento a ponto de não servir, ou o computador inteiro trava enquanto ele responde,
compare a memória que o `ollama ps` informa com o que o computador tem livre com todo o resto aberto.
Fechar um navegador muitas vezes libera mais do que o modelo precisa. Se ainda não couber, use o
`llama3.2:1b`, como descrito acima.

Se falhar alguma coisa que não está aqui, leia o primeiro erro impresso antes de qualquer outra
coisa. As linhas depois dele costumam ser consequências.
