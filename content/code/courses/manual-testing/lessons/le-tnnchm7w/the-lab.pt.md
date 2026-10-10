---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

**O laboratório de um testador manual é pequeno**: a aplicação em teste, um navegador para usá-la e
um terminal para os momentos em que o navegador esconde o que aconteceu. Este curso dá a aplicação,
um único arquivo Python na próxima seção, e esta seção põe o resto num computador seu. Nada no
curso roda em outro lugar. Não há servidor nosso onde entrar, e a aplicação não guarda nada depois
que você a para, então dá para quebrá-la quantas vezes quiser.

O laboratório são três coisas:

- **Python 3.10 ou mais novo**, que roda a aplicação. Ela não usa nada fora da biblioteca padrão do
  próprio Python, então não há mais nada a instalar para ela;
- **um navegador**, o que você já usa. A aula 7 pede um segundo, e diz qual;
- **um terminal com `curl`**, que manda uma requisição à aplicação e imprime a resposta. As
  transcrições deste curso o usam para mostrar exatamente o que voltou, e a aula 15 o usa para
  escrever um relatório de defeito que outra pessoa consegue repetir.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Python no computador que você já usa | cerca de 100 MB de disco | batem, fora os caminhos no Windows |
| **uma máquina virtual** | Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem como impressas |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalado é o caminho recomendado**, e o motivo é o navegador. O teste é feito com o navegador
que você usa todo dia, suas ferramentas de desenvolvedor e seu modo de tela estreita, e uma
aplicação rodando no mesmo computador está a um endereço dele: `http://127.0.0.1:8000`. Numa
máquina virtual a aplicação fica atrás da rede da própria máquina, e alcançá-la pelo seu navegador
é mais uma coisa a configurar antes de testar qualquer coisa.

**Instalado, no Linux**: Python 3 e curl quase sempre já estão lá. No Ubuntu ou no Debian,
`sudo apt-get install -y python3 curl` acrescenta o que faltar.

**Instalado, no Mac**: o curl vem com o macOS. O Python 3 vem com as ferramentas de linha de
comando da Apple, que o macOS oferece instalar na primeira vez que você digita `python3` no
Terminal; o instalador do python.org também serve.

**Instalado, no Windows 10 ou 11**: instale o Python pelo python.org e, na primeira tela do
instalador, marque **Add python.exe to PATH**. O curl já vem com o Windows. Duas diferenças das
transcrições acompanham você pelo curso: no Windows o comando é `python` ou `py` em vez de
`python3`, e um caminho aparece como `C:\Users\ana\boxoffice` em vez de `~/boxoffice`. Os comandos
que encadeiam um programa no outro, com `|`, são de um shell Unix; as aulas que os usam também dizem
o que procurar no navegador em vez disso. Nenhum dos passos de Mac ou Windows foi executado para
este curso.

**Uma máquina virtual** é o caminho se você prefere manter o curso separado do seu sistema, ou se
o seu computador não deixa instalar programas. O VirtualBox no Windows ou no Linux e o UTM num Mac
com Apple silicon rodam o Ubuntu Desktop 24.04, que tem Firefox, e tudo neste curso acontece dentro
dele. No Windows, o WSL rodando Ubuntu 24.04 também é uma máquina virtual, e o navegador que você já
tem alcança um programa rodando no WSL em `127.0.0.1` do mesmo jeito. A aula 4 de
`virtualization` monta uma máquina virtual passo a passo.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal e editor no navegador, e
encaminha a porta da aplicação para um endereço que você abre. Não custa nada ao seu computador; o
GitHub dá às contas pessoais uma cota mensal de horas e cobra além dela, em condições que ele define
e pode mudar. Não foi executado para este curso, e o endereço que ele dá substitui
`127.0.0.1:8000` em todo lugar.

## Conferindo

Abra um terminal e peça a versão de cada ferramenta:

```
ana@laptop:~/boxoffice$ python3 --version
Python 3.13.16
ana@laptop:~/boxoffice$ curl --version | head -n 1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
```

Qualquer Python a partir do 3.10 roda a aplicação, e qualquer curl faz o que este curso pede dele,
então um número diferente em qualquer das linhas está bem. Um `command not found` não está, e a
seção depois da próxima diz o que fazer.

## O que as transcrições imprimem

Toda transcrição deste curso foi gravada no Ubuntu 24.04, como Ana, a testadora de cujo terminal
elas vêm, e mostra o prompt dela: `ana@laptop:~/boxoffice$`. O seu mostra o seu nome e o seu
computador. Duas coisas nelas dependem do dia em que foram gravadas e vão ser diferentes nas suas:
**as datas dos espetáculos** e **os links dos e-mails de confirmação**. Todo o resto, as mensagens,
os preços, os números dos pedidos e os estados, deve bater com o que você vê depois de reiniciar a
aplicação do jeito que a próxima seção diz.
