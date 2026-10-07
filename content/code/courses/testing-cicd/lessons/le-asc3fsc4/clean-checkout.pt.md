---
title: Começando do que foi commitado
version: 1
---

"Na minha máquina funciona" costuma ser verdade. A máquina tem arquivos que o repositório não tem,
pacotes instalados meses atrás, uma variável de ambiente definida num perfil de shell. O primeiro
trabalho de uma execução de CI é **esquecer tudo isso**: ela começa de um checkout do commit e de
mais nada, então testa o que todo mundo vai receber ao puxar.

Eis essa diferença pegando um erro de verdade. A Ana acrescenta um teste que lê um arquivo de dados
novo, `tests/data/carriers.csv`, commita o teste e esquece de adicionar o CSV. O commit, o arquivo e
o teste são criados pelo laboratório com este conteúdo:

```python
import csv
from pathlib import Path

CARRIERS = Path(__file__).parent / "data" / "carriers.csv"


def test_every_carrier_has_a_positive_base_price():
    for row in csv.DictReader(open(CARRIERS)):
        assert int(row["base_cents"]) > 0, row["name"]
```

```
ana@laptop:~/shipquote$ python -m pytest -q tests/test_carriers.py
.                                                                        [100%]
1 passed in 0.62s
ana@laptop:~/shipquote$ git status --short
?? tests/data/carriers.csv
ana@laptop:~/shipquote$ git push
remote: ci: run 2, commit f3b2545, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 2.00s        
remote: ci: 3.11  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 1.95s        
remote: ci: 3.12  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.43s        
remote: ci: 3.13  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 1.98s        
remote: ci: 3.13  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.42s        
remote: ci: run 2 FAILED, logs in /home/ana/ci/runs/2        
To /home/ana/ci/shipquote.git
   b3062cb..f3b2545  main -> main
```

No notebook o teste passa: o CSV está lá. O `git status --short` entrega com `??`, a marca de um
arquivo que o git não rastreia, mas nada obriga ninguém a ler isso. A execução da CI começou do
commit `f3b2545`, que tem o teste e não o arquivo, e **toda célula falhou com uma falha**: o teste não
conseguiu abrir um arquivo que nunca foi commitado.

## Por que isso é o mais valioso que a CI faz

Ninguém cometeria esse erro de propósito, e ninguém o percebe localmente, porque localmente não é
erro. Ele só existe para a próxima pessoa que clonar o repositório: um colega, um notebook novo, o
build de produção. O checkout limpo faz essa próxima pessoa chegar na hora, como máquina, em vez de
na semana que vem, como uma mensagem confusa.

Arquivos que estão numa máquina e não no repositório são o caso mais comum, mas não o único. A mesma
disciplina pega:

- **uma dependência instalada à mão** e nunca acrescentada a `requirements-dev.txt`;
- **uma variável de ambiente** definida no perfil de shell de alguém, da qual o código depende em
  silêncio;
- **arquivos gerados** commitados por engano, que mascaram um gerador quebrado.

A CI só pega isso se **começar limpa de verdade**. Um runner que reaproveita um diretório de
trabalho entre execuções, para economizar tempo, pode carregar um arquivo de um build anterior para
o seguinte e passar pelo mesmo motivo que o notebook passou. Runners hospedados começam cada job numa
máquina virtual nova; um runner próprio precisa ter o espaço de trabalho apagado, e a aula 6 mostra
onde isso se configura.

A correção do commit da Ana foi um segundo commit tirando o teste até o CSV poder ser revisado,
enviado como execução 3. A aula segue daí.
