---
title: A instalação que funcionou ontem
version: 1
---

```sh
requirements.txt:  requests==2.31.0
```

```sh
segunda:  urllib3 2.8.0
quinta:   urllib3 2.9.0        ← ninguém mudou nada
```

**O `requests` está fixado e a instalação não é reprodutível.** Ele declara
`urllib3 (<3, >=1.21.1)` e o `pip` pega a coisa mais nova que cabe, que é o que quer que o índice
guardasse no momento em que você rodou.

Na maior parte do tempo isso está bem e ocasionalmente é a quinta-feira inteira: uma dependência
transitiva lançou uma versão, a sua máquina de build a pegou, e a falha está numa biblioteca que
ninguém da equipe leu.

## O que é um arquivo de trava

Um segundo arquivo, gerado, listando **todo** pacote — direto e transitivo — numa versão exata,
em geral com um hash do arquivo que foi baixado. Ele não é escrito à mão e não é o arquivo que
você edita.

```sh
requirements.in     o que você pede           ← editado por uma pessoa
requirements.txt    no que isso resolve       ← gerado, comitado
```

```sh
pip-compile requirements.in          # escreve requirements.txt, todo fixado
pip-sync requirements.txt            # faz o ambiente bater exatamente com ele
```

```sh
# requirements.txt — gerado pelo pip-compile
certifi==2026.7.22
    # via requests
charset-normalizer==3.5.1
    # via requests
idna==3.20
    # via requests
requests==2.31.0
    # via -r requirements.in
urllib3==2.8.0
    # via requests
```

**Olhe as anotações.** Elas são a coisa que o `pip freeze` não consegue produzir: uma linha diz
`via -r requirements.in`, e é o único pacote que alguém escolheu. As outras quatro dizem qual
pacote as arrastou para dentro, então o arquivo responde "posso apagar esta linha" sem ninguém
precisar deduzir.

O `pip-tools` é o jeito antigo de fazer isso com o `pip`, e a nomeação é confusa de propósito: o
arquivo gerado se chama `requirements.txt` para o `pip install -r` continuar funcionando para quem
nunca ouviu falar de nada disso.

## Os dois arquivos são comitados

A entrada diz do que o projeto precisa e é revisada por pessoas. A saída diz o que foi instalado e
é revisada por ninguém, e é o que faz duas máquinas serem idênticas.

Um pull request que muda o arquivo gerado sem mudar a entrada é uma atualização de algo
transitivo, que é exatamente a mudança que você quer conseguir enxergar.

## `--require-hashes`

```sh
requests==2.31.0 \
    --hash=sha256:58cd2187c01e70e6e26505bca751777aa9f2ee0b7f4300988b709f44e013003f
```

Com hashes no arquivo, o `pip` recusa qualquer coisa cujos bytes não batam. É o que impede um
índice comprometido de servir um arquivo diferente sob o mesmo número de versão, e vale ligar para
qualquer coisa que vai para produção.

## E o resumo honesto

O `pip` sozinho faz tudo isso e nada disso é padrão dele. As ferramentas da próxima aula fazem sem
serem pedidas, que é a maior parte de por que elas existem.
