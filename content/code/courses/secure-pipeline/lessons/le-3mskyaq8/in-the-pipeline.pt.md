---
title: Workflows conferidos a cada push
version: 1
---

Um arquivo de workflow é código que roda com credenciais, então ele recebe o que todo outro tipo de
código deste repositório recebe: uma checagem a cada push que quebra o build quando acha algo. O
estágio é uma linha de zizmor. Salve-o como `ci/workflows.sh`:

@@FENCE 1@@

Ele lê todo o `.github`, então os arquivos de configuração que a aula 18 acrescenta ali para os bots de
atualização também são lidos. E ele vem em segundo, logo depois de `secrets`, porque leva um segundo e
só lê texto. Salve a lista como `ci/stages`:

@@FENCE 2@@

### A execução

Faça commit do workflow e do estágio juntos, e envie:

@@FENCE 3@@

`workflows` passou em segundo, e os outros nove passaram como na aula 15. A CI local não roda o
workflow, e não precisa: ela o lê, que é a checagem que importa para um arquivo cujo risco está no que
ele diz.

### Uma regressão, pega

Um mês depois, alguém acha o `env:` e o `$TITLE` complicados demais e põe o título de volta onde
estava. Numa branch:

@@FENCE 4@@

**A branch para no segundo estágio**, com o achado e a linha, antes de um teste rodar ou de uma imagem
ser construída. A correção é a que a seção anterior fez, e o estágio vai continuar pedindo por ela em
toda branch que a desfizer. Nada chegou ao registry, porque o `push` nunca rodou.

### O que este estágio não vê

O zizmor offline lê os arquivos. Ele não confere se um commit fixado pertence mesmo à action que
nomeia, que é a auditoria `impostor-commit` e precisa da API do GitHub; nem sabe se uma versão de
action tem aviso publicado, que é a `known-vulnerable-actions` e precisa da mesma API. Rodadas online,
num job com token, essas duas auditorias também rodam. Nem ele nem scanner nenhum julga o runner em
que o workflow cai, que é o assunto das duas próximas seções.
