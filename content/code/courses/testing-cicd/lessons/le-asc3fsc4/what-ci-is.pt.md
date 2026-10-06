---
title: O que é integração contínua
version: 1
---

**Integração contínua** é uma prática antes de ser uma ferramenta: todo mundo integra o próprio
trabalho na linha principal compartilhada com frequência, pelo menos uma vez por dia, e **cada
integração é conferida automaticamente**, montando o projeto e rodando os testes numa máquina que não
é a de quem escreveu. A ferramenta, um servidor de CI, é o que deixa a segunda metade barata o
bastante para acontecer a cada push.

As duas metades importam. Integrar raramente significa que, quando duas pessoas finalmente juntam o
trabalho, uma semana de mudanças colide de uma vez e ninguém sabe dizer qual quebrou o build.
Conferir à mão significa que a conferência é pulada. Um servidor de CI transforma "a main ainda
funciona?" numa pergunta que se responde sozinha poucos minutos depois de cada push.

## A menor CI que existe

Serviços hospedados, entre eles o GitHub Actions e o GitLab CI, são o assunto da aula 6. Para ver o
que eles fazem sem nada do vocabulário deles, esta aula usa uma CI que cabe num arquivo: um **hook
post-receive** do git, um script que o git roda no repositório que recebe, depois de cada push. O
`lab.sh ci` o grava num repositório bare em `~/ci/shipquote.git`:

```schooling-example
{
  "language": "sh",
  "file": "post-receive",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# The lab's whole CI. On every push to main: a clean checkout of the pushed\n# commit, then the test suite once per Python version and per time zone. What\n# it prints reaches the person who pushed, each line prefixed with \"remote:\".\nset -uo pipefail\nPYTHONS=${CI_PYTHONS:-\"3.11 3.12 3.13\"}\nZONES=${CI_ZONES:-\"America/Sao_Paulo UTC\"}\nRUNS=$(cd \"$(dirname \"$0\")/../..\" && pwd)/runs\n",
      "note": "A configuração: quais versões do Python e quais fusos horários testar, e onde guardar o que cada execução produziu. Cada combinação é uma **célula** da matriz de que trata a seção 06."
    },
    {
      "code": "while read -r old new ref; do\n  if [ \"$ref\" != refs/heads/main ]; then\n    echo \"ci: ${ref#refs/heads/} is not main, nothing to run\"\n    continue\n  fi",
      "note": "O git entrega ao hook uma linha por branch atualizado: commit antigo, commit novo, nome do branch. **Este é o gatilho**: só pushes na `main` rodam alguma coisa."
    },
    {
      "code": "  mkdir -p \"$RUNS\"\n  n=$(( $(ls \"$RUNS\" | wc -l) + 1 ))\n  run=$RUNS/$n\n  mkdir \"$run\"\n  work=$(mktemp -d)\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"ci: run $n, commit ${new:0:7}, checked out clean\"\n  failed=0",
      "note": "Uma execução numerada, e um **checkout limpo**: o `git archive` grava o commit enviado, e só o que foi commitado, num diretório novo e vazio. Nada do notebook de ninguém vem junto."
    },
    {
      "code": "  for py in $PYTHONS; do\n    venv=$work/.venv-$py\n    if ! { uv venv -q -p \"$py\" \"$venv\" &&\n           VIRTUAL_ENV=$venv uv pip install -q -r \"$work/requirements-dev.txt\"; } \\\n         > \"$run/install-$py.log\" 2>&1; then\n      echo \"ci: python $py could not be installed, see install-$py.log\"\n      failed=1\n      continue\n    fi",
      "note": "Um ambiente virtual novo por versão do Python, com as dependências fixadas. Se a instalação falha, a célula também conta como falha, com log próprio."
    },
    {
      "code": "    for tz in $ZONES; do\n      cell=\"py$py-${tz//\\//-}\"\n      if (cd \"$work\" && TZ=$tz \"$venv/bin/python\" -m pytest -q -p no:cacheprovider \\\n            --junitxml=\"$run/$cell.xml\" > \"$run/$cell.log\" 2>&1); then\n        result=pass\n      else\n        result=FAIL\n        failed=1\n      fi\n      printf 'ci: %-5s %-18s %-4s  %s\\n' \"$py\" \"$tz\" \"$result\" \"$(tail -1 \"$run/$cell.log\")\"\n    done\n  done",
      "note": "A suíte, uma vez por fuso horário, com a saída e um relatório JUnit XML guardados no diretório da execução. Uma linha por célula volta para quem fez o push, terminando com o resumo do próprio pytest."
    },
    {
      "code": "  rm -rf \"$work\"\n  if [ \"$failed\" = 0 ]; then\n    echo \"ci: run $n passed\"\n  else\n    echo \"ci: run $n FAILED, logs in $run\"\n  fi\ndone",
      "note": "Limpa o checkout e dá o veredito da execução."
    }
  ]
}
```

## O primeiro push

A Ana liga o clone dela a esse repositório e envia a `main`:

```
ana@laptop:~/shipquote$ git remote add origin ~/ci/shipquote.git
ana@laptop:~/shipquote$ git push -u origin main
remote: ci: run 1, commit b3062cb, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.05s        
remote: ci: 3.11  UTC                pass  41 passed, 2 skipped in 1.41s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.94s        
remote: ci: 3.12  UTC                pass  41 passed, 2 skipped in 1.41s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.03s        
remote: ci: 3.13  UTC                pass  41 passed, 2 skipped in 1.43s        
remote: ci: run 1 passed        
To /home/ana/ci/shipquote.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Toda linha que começa com `remote:` foi impressa pelo hook, do lado que recebe, e repassada pelo
git. **A execução 1 conferiu o commit `b3062cb` em seis células**, três versões do Python por dois
fusos, e as seis passaram, com 41 testes aprovados e 2 pulados, os testes de contrato da aula 2.
Depois o git informa o push em si: a `main` criada no remoto.

## O que este brinquedo deixa de fora

Três coisas o separam de um serviço de CI de verdade, e vale nomeá-las porque a aula 6 as devolve:

- **Ele roda na mesma máquina**, então "uma máquina que não é a de quem escreveu" é só meia verdade.
  O checkout é limpo, mas as instalações do Python e a rede são compartilhadas.
- **Ele relata depois do fato.** Um hook post-receive roda quando o push já foi aceito, então uma
  execução vermelha não impede um commit quebrado de chegar à `main`. Um serviço hospedado relata
  num pull request *antes* do merge, que é o ponto da seção 11.
- **As células dele rodam uma depois da outra.** Runners hospedados as rodam em paralelo, em
  máquinas separadas.

O que ele tem em comum com todo serviço de CI é o ciclo: **um push dispara uma execução, a execução
começa do que foi commitado, os testes rodam em toda configuração que importa, e o resultado volta
para quem fez o push.** O resto desta aula desmonta esse ciclo.
