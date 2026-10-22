---
title: Variáveis de ambiente
version: 1
---

Todo processo começa com uma lista de strings `NOME=valor`, o ambiente dele, copiada do processo que o
iniciou. Um shell acrescenta à lista com `export`, e uma variável escrita antes de um comando vale só para
aquele comando. O Go lê a lista com `os.Getenv` e `os.LookupEnv`, e a diferença entre os dois é a primeira
coisa que vale saber. O `knobs` imprime o que o `LookupEnv` diz sobre `BOXOFFICE_REGION`:

```
ana@vm:~/knobs$ BOXOFFICE_REGION= ./knobs | tail -1
BOXOFFICE_REGION: "", set: true
ana@vm:~/knobs$ BOXOFFICE_REGION=sao-paulo ./knobs | tail -1
BOXOFFICE_REGION: "sao-paulo", set: true
```

As execuções da seção 03 disseram todas `set: false`. Aqui a primeira execução define a variável como
vazia, e o `LookupEnv` diz que ela existe e está vazia, enquanto o `os.Getenv` teria devolvido `""` nos
dois casos. **A maioria dos programas trata vazio como não definido**, e o boxoffice também: uma definição
de container com `BOXOFFICE_ORIGIN=` e nada depois quase sempre significa que alguém a deixou em branco, não
que o site seja a string vazia. Use o `LookupEnv` quando a diferença importar para você.

```
ana@vm:~/knobs$ export BOXOFFICE_REGION=sao-paulo; ./knobs | tail -1; bash -c 'echo "a child sees $BOXOFFICE_REGION"'
BOXOFFICE_REGION: "sao-paulo", set: true
a child sees sao-paulo
```

**Uma variável exportada chega a todo processo iniciado depois dela**, o shell filho inclusive. É assim que
uma plataforma entrega configuração a um programa, e é também a primeira coisa que a seção 05 tem contra
segredos no ambiente.

## Strings, todas elas

Um ambiente só guarda strings. Uma porta, um tamanho de pool ou um timeout precisa ser analisado, e um valor
que não se analisa é problema do programa informar, com o nome da variável na mensagem. Uma mensagem que
diz `parse error` sem dizer qual de trinta variáveis o causou manda alguém ler as trinta. A seção 07
reaproveita os analisadores do pacote flag para isso, então `BOXOFFICE_WRITE_TIMEOUT=90s` é lido
exatamente pelo mesmo código que `-write-timeout 90s`.

## Nomes

Duas convenções mantêm os nomes longe de problemas:

- **Um prefixo para as configurações do próprio programa**, `BOXOFFICE_` aqui. Nomes curtos como `PORT`,
  `ADDR` ou `DEBUG` são definidos por outras ferramentas e plataformas por motivos delas, e um programa que
  os lê acaba recebendo um valor que nunca foi para ele.
- **Os nomes conhecidos como estão.** `DATABASE_URL` fica sem o prefixo porque outras ferramentas o leem
  por esse nome: o `sqlc.yaml` da aula 8 lê, e várias plataformas de hospedagem o definem para o banco que
  oferecem.

Uma variável é lida uma vez, quando o programa começa. Mudá-la depois não muda nada no processo em
execução, então configuração nova significa reiniciar, o que o encerramento gracioso da aula 17 torna
barato.
