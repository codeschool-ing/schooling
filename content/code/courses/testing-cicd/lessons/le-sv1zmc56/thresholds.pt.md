---
title: Um mínimo, e o que um mínimo convida
version: 1
---

O jeito óbvio de usar cobertura numa equipe é uma regra: o build falha abaixo de uma porcentagem.
`coverage report` aceita isso direto com `--fail-under`, ou com `fail_under` na configuração. Aqui o
mínimo é 85%, contra os 81% do `shipquote`:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q > /dev/null; coverage report --fail-under=85 | tail -1; echo "exit status $?"
Coverage failure: total of 81 is less than fail-under=85
exit status 0
ana@laptop:~/shipquote$ coverage report --fail-under=85 > /dev/null; echo "exit status $?"
exit status 2
```

O primeiro comando imprimiu a mensagem de falha e depois `exit status 0`. O segundo imprimiu
`exit status 2`. Mesmo relatório, mesmo limite, e a diferença é o pipe: `| tail -1` faz o código de
saída da linha ser o do `tail`, que deu certo. **Um passo de pipeline escrito como a primeira linha
passa com a cobertura abaixo do mínimo.** A aula 1 seção 14 avisou disso com o código 5 do pytest, e
a aula 5 mostra como um shell de CI é configurado para isso não acontecer.

## O que o mínimo convida

Agora alguém precisa do build verde até o fim do dia. Acrescenta um arquivo:

```python
from unittest import mock

from shipquote.carrier import CarrierClient
from shipquote.mailer import SmtpMailer


def test_the_client_can_be_used():
    try:
        CarrierClient("http://carrier.example", "t",
                      opener=mock.MagicMock()).rate("01310100", 1)
    except Exception:
        pass


def test_the_mailer_can_be_used():
    with mock.patch("smtplib.SMTP"):
        SmtpMailer("smtp.example").send("bia@example.org", "s", "b")
```

```
ana@laptop:~/shipquote$ coverage run -m pytest -q | tail -1; coverage report | tail -1
43 passed, 2 skipped in 1.67s
TOTAL                     164     14     24      4    90%
ana@laptop:~/shipquote$ coverage report --fail-under=85 > /dev/null; echo "exit status $?"
exit status 0
```

**90%, e o limite passa.** Os dois testes executam o cliente da transportadora e o mailer e não
conferem nada; o primeiro ainda engole qualquer exceção que o cliente levante. Toda linha que eles
tocam agora está "coberta". O teste de contrato da aula 2 continua pulado, então o `CarrierClient`
não está mais bem testado que uma hora antes, e o relatório agora diz o contrário.

É a lei de Goodhart em miniatura: **quando uma medida vira meta, deixa de ser uma boa medida.**
Ninguém quis enganar ninguém. A regra pediu um número, e o número era a coisa mais barata de mudar.

## O que este repositório faz no lugar

O projeto que publica este curso diz a regra dele no `CLAUDE.md`:

> **Coverage is not a target.** Do not add tests to raise a percentage. Add the test that would
> have caught the failure you just found, and the one for the failure mode you can name. (X-04)

Isto é: cobertura não é meta; não acrescente testes para subir uma porcentagem; acrescente o teste
que teria pego a falha que você acabou de achar, e o do modo de falha que você consegue nomear. Essa
regra mantém a cobertura como **diagnóstico**: algo que se lê para achar pontos cegos, não algo pelo
qual se é avaliado. Equipes que querem mesmo uma barreira costumam escolher uma de duas formas mais
brandas:

- **uma catraca** (*ratchet*): o build só falha se a cobertura *cair* abaixo da que a main tem
  hoje, então ela só fica ou sobe, e ninguém precisa alcançar um número arbitrário de uma vez;
- **cobertura da mudança**: as linhas que um pull request acrescentou precisam estar cobertas, seja
  qual for o total, que é a próxima seção.

Nenhuma das duas é imune ao arquivo acima. Uma barreira sobre um número sempre pode ser satisfeita
por testes que não conferem nada, e é por isso que a revisão de um teste é sobre as verificações
dele, e por isso a seção 05 existe.
