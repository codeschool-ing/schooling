---
title: Jobs, passos e o código de saída
version: 1
---

Uma execução de CI é feita de **jobs**, e um job é feito de **passos** (*steps*). As duas palavras
querem dizer a mesma coisa em quase todo serviço:

- um **job** roda numa máquina, a partir de um começo limpo, e é a unidade que pode rodar em
  paralelo com outros jobs. As seis células da matriz do laboratório seriam seis jobs num serviço
  hospedado;
- um **passo** é um comando ou ação dentro de um job. Os passos rodam em ordem, dividem os arquivos
  do job, e **o primeiro passo que falha para o job**.

Como a CI sabe que um passo falhou? De um jeito só: **pelo código de saída do comando**. Zero é
sucesso, qualquer outra coisa é falha. A CI não lê a saída, não procura a palavra "erro" nem conta
linhas vermelhas. Um passo que imprime cem falhas e sai com 0 é um passo verde.

## O pipe que mente

Isso faz o código de saída de cada passo valer a conferência, e o jeito mais comum de perdê-lo é um
pipe. As aulas 1 e 4 o encontraram; eis a correção. O comando roda o pytest com um marcador que não
seleciona nada, então o pytest sai com 5, e passa a saída pelo `tee` para guardar um log:

```
ana@laptop:~/shipquote$ python -m pytest -q -m smoke | tee run.log; echo "exit status $?"

43 deselected in 0.21s
exit status 0
ana@laptop:~/shipquote$ set -o pipefail; python -m pytest -q -m smoke | tee run.log; echo "exit status $?"

43 deselected in 0.18s
exit status 5
```

A primeira linha informa `exit status 0`. O código de um pipe é, por padrão, **o código do último
comando**, e o `tee` deu certo. A segunda linha liga o `pipefail`, que faz um pipe falhar se qualquer
comando dele falhou, e agora o código é o 5 do pytest.

**Todo passo de shell numa CI deveria rodar com `-e` e `-o pipefail`**: `-e` para no primeiro comando
que falha, `pipefail` impede um pipe de esconder um. O hook do laboratório começa com
`set -uo pipefail` pelo mesmo motivo, e deixa o `-e` de fora de propósito, porque quer continuar e
relatar todas as células.

## Confira o que o seu serviço faz por padrão

O GitHub Actions documenta como padrão dos passos `run` no Linux `bash -e {0}` quando nenhum shell é
declarado, e `bash --noprofile --norc -eo pipefail {0}` quando o passo diz `shell: bash`. Então **um
passo sem linha `shell:` roda sem `pipefail`**, e o primeiro comando acima passaria lá também. O
GitLab CI roda as linhas de script de um job num shell com regras próprias. O hábito seguro não
depende de lembrar nada disso: ou declare o shell, ou comece os passos de várias linhas com
`set -euo pipefail`.

## Dependências entre jobs

Jobs rodam em paralelo, a não ser que um diga que precisa de outro. Um grafo típico: um job rápido de
lint e os testes unitários lado a lado; testes de integração só depois que os dois passam; um deploy
só depois de tudo. A aula 6 escreve essas arestas como `needs:` no GitHub Actions e como estágios no
GitLab CI. O princípio é o da aula 1 seção 11: **verificações rápidas primeiro**, para um erro de
digitação falhar em trinta segundos e não depois de dez minutos de suíte de navegador.
