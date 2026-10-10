---
title: Um teste de integração por HTTP
version: 1
---

Um teste de integração confere que pedaços que funcionam sozinhos também funcionam juntos. O erro
de costume é pensar nele como um teste de unidade maior, a mesma coisa com mais código dentro. **O
que muda é aquilo de que o teste depende**: um teste de unidade não precisa de nada além da função,
e um teste de integração precisa que os pedaços que ele atravessa estejam lá e rodando. Essa
diferença molda como ele é escrito, como falha e o que as falhas dele querem dizer.

No boxoffice, o teste de integração natural entra pela mesma porta que você usa com o curl. Ele
envia o formulário de reserva por HTTP à aplicação rodando, exatamente como um navegador faria, e
lê o total na página do pedido que volta. No caminho atravessa o servidor, o código que lê o
formulário, a verificação da quantidade, `discount`, a conta do total e a própria página.

## O arquivo de teste

Salve-o como `test_booking.py`, em `~/boxoffice`, ao lado dos outros dois arquivos:

```schooling-example
{"language": "python", "file": "test_booking.py", "parts": [
 {"code": "import re\nimport unittest\nfrom urllib.parse import urlencode\nfrom urllib.request import urlopen\n", "note": "Tudo aqui está na biblioteca padrão do Python. `urlopen` manda uma requisição do jeito que o curl manda."},
 {"code": "BOXOFFICE = \"http://127.0.0.1:8000\"\n\n", "note": "O endereço da aplicação rodando. O teste não a inicia: alguém precisa iniciá-la, em outro terminal, e essa é a primeira diferença para um teste de unidade."},
 {"code": "def total_of_booking(**fields):\n    \"\"\"Book through the running application and return the total on the order page.\"\"\"\n    with urlopen(BOXOFFICE + \"/book\", urlencode(fields).encode()) as answer:\n        page = answer.read().decode()\n    return re.search(r\"<strong>(R\\$ [^<]+)</strong>\", page).group(1)\n\n", "note": "Envia o formulário de reserva com os campos que um navegador mandaria, lê a página do pedido que volta e separa o total, o primeiro valor em reais em negrito."},
 {"code": "class BookingTest(unittest.TestCase):\n\n    def test_member(self):\n        total = total_of_booking(email=\"member@example.org\", show=\"S2\", quantity=\"2\")\n        self.assertEqual(total, \"R$ 144,00\")\n", "note": "Dois ingressos para Hamlet a R$ 80,00, reservados pelo membro que já vem cadastrado, que ganha 10%. O valor esperado é dinheiro, como o cliente vê, e não mais uma porcentagem."},
 {"code": "    def test_student(self):\n        total = total_of_booking(email=\"member@example.org\", show=\"S2\", quantity=\"2\",\n                                 student=\"on\")\n        self.assertEqual(total, \"R$ 80,00\")", "note": "O mesmo pedido com a caixa de estudante marcada, que o navegador manda como `student=on`. A metade de R$ 160,00 é R$ 80,00, porque vale o maior desconto."}
]}
```

São dois testes, cada um uma reserva: o membro que já vem cadastrado comprando dois ingressos para
Hamlet, uma vez como ele mesmo e uma vez com a caixa de estudante marcada. Os valores esperados
estão escritos como o cliente os leria, em reais com vírgula, porque é isso que esta camada
consegue ver e o teste de unidade não conseguia.

## Quando a aplicação não está rodando

Um teste de integração tem uma pré-condição que um teste de unidade nunca tem. Rode-o com o
boxoffice parado e os dois testes param no primeiro pedido:

```
ana@laptop:~/boxoffice$ python3 -m unittest test_booking 2>&1 | grep -E 'ERROR|URLError|FAILED'
ERROR: test_member (test_booking.BookingTest.test_member)
    raise URLError(err)
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
ERROR: test_student (test_booking.BookingTest.test_student)
    raise URLError(err)
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
FAILED (errors=2)
```

A saída completa é longa, porque cada teste imprime a cadeia de chamadas que levou à conexão
recusada; o `grep` guarda as linhas que importam. Duas palavras merecem ser separadas aqui, porque o
`unittest` as separa. **Um `FAIL` é um teste que rodou e recebeu a resposta errada. Um `ERROR` é um
teste que não conseguiu resposta nenhuma**: aqui, não havia nada escutando na porta 8000. Relatar
esses dois erros como um defeito do boxoffice seria um engano. Eles são uma falha na montagem, do
mesmo tipo que a aula 1, seção 05, tratou quando o servidor não subia.

## Quando ela está rodando

Inicie o boxoffice no terminal dele, como sempre, e rode o teste de novo no segundo terminal:

```
ana@laptop:~/boxoffice$ python3 -m unittest -v test_booking
test_member (test_booking.BookingTest.test_member) ... ok
test_student (test_booking.BookingTest.test_student) ... FAIL

======================================================================
FAIL: test_student (test_booking.BookingTest.test_student)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/boxoffice/test_booking.py", line 25, in test_student
    self.assertEqual(total, "R$ 80,00")
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
AssertionError: 'R$ 144,00' != 'R$ 80,00'
- R$ 144,00
+ R$ 80,00


----------------------------------------------------------------------
Ran 2 tests in 0.054s

FAILED (failures=1)
```

Um `ok` e um `FAIL`. Os dois ingressos do membro custam R$ 144,00, que são R$ 160,00 menos 10%, então
tudo entre o formulário e a página funciona para um membro. O pedido do estudante voltou também em
R$ 144,00, onde o R5 diz R$ 80,00: a caixa de estudante chegou à aplicação e não mudou nada.

**É a mesma regressão pela terceira vez.** A aula 10 a viu num navegador, a seção 03 desta aula a viu
em `discount`, e este teste a vê no meio do caminho. As três visões não são redundantes: o teste de
unidade diz onde está a causa, este diz quanto ela custa a um cliente, e só um navegador mostra o
que o cliente vê. Se o desenvolvedor corrigir `discount`, este arquivo e o `test_discount.py` ficam
verdes; se alguém um dia renomear a caixa de estudante no formulário, só este arquivo percebe.

## O que testes de integração custam

Duas coisas que você vai encontrar em qualquer time que os tenha.

**Eles deixam estado para trás.** Cada rodada deste arquivo reserva quatro ingressos para Hamlet e
cria dois pedidos, então os lugares livres diminuem e os números de pedido sobem a cada vez. Aqui
isso é inofensivo, porque reiniciar zera o boxoffice. Num ambiente de teste compartilhado, com um
banco de dados de verdade, é o motivo de as suítes de integração gastarem tanto código criando os
próprios dados e limpando depois, um assunto a que a aula 20 volta.

**Eles são mais lentos e mais ruidosos.** Estes dois rodaram rápido, numa máquina só. Uma suíte de
verdade conversa com um banco de dados, um serviço de pagamento e um servidor de e-mail, e um teste
pode falhar porque um deles estava lento ou fora do ar. Isso é um `ERROR` como o de cima, não diz
nada sobre o código sob teste, e um time que recebe muitos deles para de confiar na suíte. A seção
05 desta aula trata da resposta de costume: trocar as partes de que o teste não trata por
substitutos.
