---
title: Quando a preparação falha
version: 1
---

É aqui que um curso é abandonado com mais frequência, num erro sobre uma ferramenta que o aluno ainda
não terminou de instalar. Estas são as falhas encontradas enquanto esta aula era gravada, na ordem em
que a preparação as encontra, e o que cada uma quer dizer.

**O ambiente virtual não foi criado.** O Ubuntu vem com o Python sem a parte que cria ambientes
virtuais, e é isto que o `python3 -m venv` diz sem ela:

```
ana@laptop:~/cloud$ python3 -m venv ~/cloud/venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/cloud/venv/bin/python3
```

A mensagem diz o remédio: `sudo apt-get install -y python3-venv`, o pacote que o primeiro bloco da
preparação instala. A tentativa que falhou deixou para trás um `~/cloud/venv` feito pela metade, e o
resto do bloco pode ter clonado o cloud-init antes de parar, então remova os dois com
`rm -rf ~/cloud/venv ~/cloud/cloud-init` e rode o terceiro bloco da preparação inteiro de novo.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois que a máquina liga, e só um programa por vez pode instalar pacotes. Espere
alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai achar na
internet, e é assim que um banco de pacotes se estraga.

**O `aws` não é encontrado.** As ferramentas estão instaladas e o shell não sabe onde:

```
ana@laptop:~/cloud$ aws --version
bash: line 1: aws: command not found
```

Todo terminal novo começa sem o `~/.local/bin` e sem o ambiente virtual. As duas linhas de "Toda vez
que você abrir um terminal", na preparação, devolvem os dois; o mesmo acontece com o `moto_server` e
o `cloud-init`, e as mesmas duas linhas resolvem.

**O instalador da AWS falha com `Exec format error`, ou o `aws` não roda.** O arquivo zip é feito para
um tipo de processador. Uma máquina virtual num Mac com Apple silicon, e a maioria das placas Arm
pequenas, precisam do arquivo `aarch64` que a preparação cita, e `uname -m` imprime qual é o seu:
`x86_64` ou `aarch64`. Apague o `~/.local/aws-cli` e instale a partir do outro arquivo.

**Um download da lista de preços parou no meio.** Os arquivos do EC2 têm centenas de megabytes, e uma
conexão que cai no meio deixa o Python com menos bytes do que o servidor anunciou. Isso aconteceu uma
vez enquanto este curso era gravado, e a última linha do erro foi:

```
urllib.error.ContentTooShortError: <urlopen error retrieval incomplete: got only 291821784 out of 292285717 bytes>
```

Rode o mesmo comando de novo. O programa grava cada download num arquivo terminado em `.part` e só lhe
dá o nome de verdade quando ele está completo, então um download quebrado nunca passa por um
terminado, e a próxima execução o começa de novo do início.

**A tabela de preços imprime o cabeçalho e depois a palavra `Killed`.** O sistema ficou sem memória e
parou o programa, que é o que o Linux faz quando um processo pede mais do que a máquina tem. O bloco
do EC2 precisa de uns 2,2 GB só para ele. Feche outros programas; numa máquina virtual, dê a ela 4 GB
de memória. Se nenhum dos dois for possível, todo preço que as aulas citam está impresso na própria
aula, então o bloco do EC2 é o único comando deste curso que você pode ler em vez de rodar.

**O moto não sobe porque a porta está em uso.** A aula 5 sobe o `moto_server` na porta 5000. Uma
segunda cópia, ou qualquer outro programa já escutando ali, recebe isto:

```
ana@laptop:~/cloud$ timeout 10 moto_server -p 5000 2>&1 | tail -3
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

O dono mais provável é um `moto_server` que você subiu antes e deixou rodando, e `jobs` no mesmo
terminal o lista. Pare-o com `kill %1`, ou feche o terminal que o subiu. Num Mac, a porta 5000 é
também onde o receptor AirPlay do sistema escuta. Qualquer porta livre serve, desde que você use o
mesmo número em `AWS_ENDPOINT_URL` na aula 5.
