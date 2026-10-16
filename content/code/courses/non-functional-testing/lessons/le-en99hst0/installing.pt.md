---
title: Instalando o JMeter, e onde a janela dele entra
version: 1
---

O Apache JMeter é a ferramenta de teste de carga mais antiga deste curso e continua entre as mais
usadas: um programa Java, lançado pela primeira vez em 1998, que monta testes numa janela de desktop
e os roda em qualquer lugar onde Java rode. Ele é distribuído como um arquivo compactado, sem nada
para compilar. O Java 21 já está na máquina desde a aula 1, então instalar o JMeter é baixar e
descompactar, no seu diretório pessoal:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar -xzf apache-jmeter-5.6.3.tgz
```

**Essas três linhas não foram rodadas para este curso**: a máquina das transcrições tinha o mesmo
arquivo descompactado do mesmo jeito, em `~/apache-jmeter-5.6.3`. Os programas ficam no diretório
`bin` dele. Dois links colocam no path os dois de que você precisa, e a primeira chamada imprime a
versão:

```
ana@nft:~$ sudo ln -s ~/apache-jmeter-5.6.3/bin/jmeter ~/apache-jmeter-5.6.3/bin/jmeter-server /usr/local/bin/
ana@nft:~$ jmeter --version
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Oct 10, 2026 4:52:01 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
    _    ____   _    ____ _   _ _____       _ __  __ _____ _____ _____ ____
   / \  |  _ \ / \  / ___| | | | ____|     | |  \/  | ____|_   _| ____|  _ \
  / _ \ | |_) / _ \| |   | |_| |  _|    _  | | |\/| |  _|   | | |  _| | |_) |
 / ___ \|  __/ ___ \ |___|  _  | |___  | |_| | |  | | |___  | | | |___|  _ <
/_/   \_\_| /_/   \_\____|_| |_|_____|  \___/|_|  |_|_____| |_| |_____|_| \_\ 5.6.3

Copyright (c) 1999-2024 The Apache Software Foundation
```

As quatro linhas `WARN StatusConsoleListener` vêm da biblioteca de log que o JMeter 5.6.3 traz, e
todo comando do JMeter as imprime. Elas são inofensivas, e aparecem em todas as transcrições desta
aula, porque uma transcrição imprime o que o programa imprimiu. As duas linhas sobre preferências do
usuário aparecem só na primeira vez que o Java roda.

## A janela, e por que as rodadas não a usam

`jmeter` sem argumentos abre a **GUI**, uma árvore de elementos à esquerda e as configurações do
elemento selecionado à direita. É o jeito confortável de montar um plano: clique com o botão direito
num elemento, *Add*, escolha um sampler ou um timer num menu, preencha os campos, e *File → Save*
grava o `.jmx`. Ela também tem listeners que mostram cada requisição e cada resposta enquanto
acontecem, que é como um plano é depurado, com um ou dois usuários, antes de alguém confiar nele.

A VM não tem desktop, então a GUI não roda lá. **Rodá-la quer dizer o JMeter no seu próprio
computador**, onde você tem uma tela: instale o Java e descompacte o mesmo arquivo lá, ou no Windows
use o `jmeter.bat` do mesmo diretório `bin`. Monte e depure o plano lá, depois copie o `.jmx` para a
VM com `multipass transfer plan.jmx nft:loadtest/`. Nada disso foi rodado para este curso, que
também não tem desktop; o plano da próxima seção foi escrito à mão.

A rodada em si nunca é feita pela janela, e o JMeter diz isso no terminal de onde foi iniciado, toda
vez que a GUI abre. **Um teste de carga roda em modo não gráfico**, `jmeter -n`, por três motivos:

- A GUI desenha cada amostra que coleta. A algumas centenas de requisições por segundo, esse desenho
  tira tempo de processador e memória das threads que deveriam estar enviando requisições, e o
  resultado descreve a janela do JMeter tanto quanto o sistema sob teste.
- Uma rodada não gráfica é um comando, então pode ser roteirizada, repetida exatamente e rodada por
  um pipeline, que é o que a aula 11 faz.
- Ela roda numa máquina sem tela, que é onde um gerador de carga deve ficar: perto do sistema sob
  teste, e num hardware só dele.
