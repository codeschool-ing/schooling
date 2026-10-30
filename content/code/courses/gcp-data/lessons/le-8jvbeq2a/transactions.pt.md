---
title: Uma transação de leitura e escrita, e leituras um pouco antigas
version: 1
---

**O Spanner dá a um banco espalhado por muitas máquinas as transações de um banco numa só.** Uma
transação de leitura e escrita lê, decide e escreve, e ou todas as escritas acontecem ou nenhuma
acontece, com a mesma garantia estejam as linhas num servidor ou em servidores de três regiões. A
palavra do Google para a garantia é **consistência externa** (*external consistency*): se uma transação
confirma antes de outra começar, todo leitor as vê nessa ordem, em todo lugar. É uma promessa mais
forte do que a maioria dos bancos distribuídos faz, e é a razão de o Spanner existir.

**A ideia errada é que isso é de graça, ou lento.** Não é nenhum dos dois. O Spanner paga por isso com
um relógio: o TrueTime, o serviço de hora do Google, dá a todo servidor a hora atual com um limite
conhecido para o erro, e um commit espera esse limite passar antes de ficar visível, para que dois
commits nunca fiquem na ordem errada. O Google documenta o limite como alguns milissegundos. Entre
regiões o commit também espera a maioria das réplicas concordar, que é o custo de verdade, e a razão
de uma instância multirregional escrever mais devagar do que uma regional. **Nada do relógio aparece no
emulador**, que tem um processo e um relógio; o que dá para praticar é o modelo de programação, que é
o mesmo.

## Conferir o estoque e gravar o pedido

**Fazer um pedido é a transação de livro**: ler quantas bananas sobram, recusar se não houver o
bastante, tirá-las e gravar o pedido, sem que ninguém mais consiga pegar as mesmas bananas no meio.

```schooling-example
{"language": "python", "file": "order.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Place one order: check the stock, take it, write the order, in one transaction.\n\n    python3 order.py CUSTOMER PRODUCT UNITS TOTAL_CENTS\n\"\"\"\nimport sys\n\nfrom google.api_core.exceptions import NotFound\nfrom google.cloud import spanner\nfrom google.cloud.spanner_v1 import param_types\n\ndb = spanner.Client(project='planner-dev').instance('quitanda').database('shop')\n", "note": "A docstring diz como rodar. `NotFound` é o erro que o Spanner levanta quando o pai de uma linha não existe."}, {"code": "customer, product, units, cents = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])\nP = {'c': customer, 'p': product, 'u': units, 'cents': cents}\nT = {'c': param_types.STRING, 'p': param_types.STRING, 'u': param_types.INT64,\n     'cents': param_types.INT64}\n\n", "note": "**Todo valor chega ao SQL como parâmetro**, `@c`, `@p`, `@u` e `@cents`, com o tipo do Spanner, e nunca colado na string."}, {"code": "def place(t):\n    rows = list(t.execute_sql('SELECT Units FROM Stock WHERE Product = @p', params=P, param_types=T))\n    if rows[0][0] < units:\n        raise ValueError(f'{product}: {rows[0][0]} left, {units} asked')\n", "note": "**A leitura acontece dentro da transação**, então a linha fica travada até o commit e ninguém mais pega as mesmas unidades no meio. Levantar uma exceção dentro da função desfaz a transação."}, {"code": "    t.execute_update('UPDATE Stock SET Units = Units - @u WHERE Product = @p', params=P, param_types=T)\n    inserted = t.execute_sql(\n        \"INSERT INTO Orders (CustomerId, Day, TotalCents) \"\n        \"VALUES (@c, CURRENT_DATE('America/Sao_Paulo'), @cents) THEN RETURN OrderId\",\n        params=P, param_types=T)\n    return list(inserted)[0][0]\n\n", "note": "**Duas escritas, uma transação.** O `OrderId` do pedido vem do `DEFAULT` da coluna, a sequência bit-reversed, e `THEN RETURN` o devolve. As duas escritas ficam visíveis juntas no commit, ou nenhuma fica."}, {"code": "try:\n    print('order', db.run_in_transaction(place), 'placed')\nexcept (ValueError, NotFound) as refused:\n    print('refused, nothing written:', str(refused).split(', request_id')[0])\n", "note": "`run_in_transaction` confirma quando a função retorna, e a roda de novo desde o começo se o Spanner a abortar. A mensagem é cortada antes do request id que a biblioteca acrescenta."}]}
```

```
ana@laptop:~/gcp$ python3 order.py c-17 banana 4 2760
order 7773212956841476096 placed
ana@laptop:~/gcp$ python3 order.py c-17 banana 8 5520
refused, nothing written: banana: 6 left, 8 asked
ana@laptop:~/gcp$ python3 order.py c-99 banana 1 690
refused, nothing written: 404 Insert failed because key was not found in parent table:  Parent Table: Customers  Child Table: Orders  Key: {String("c-99")}
```

**Três execuções, três resultados.** A primeira pegou quatro das dez bananas e gravou o pedido número
`7773212956841476096`, um valor bit-reversed da sequência. A segunda pediu oito das seis que sobravam e
foi recusada pelo programa, antes de qualquer escrita. A terceira nomeou um cliente que não existe,
então o `INSERT` violou a regra do pai da seção anterior, e o `UPDATE` do estoque, que já tinha rodado
dentro da transação, foi desfeito junto:

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT CustomerId, OrderId, Day, TotalCents FROM Orders'
CustomerId  OrderId              Day         TotalCents
c-17        7773212956841476096  2026-10-30  2760
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT Units FROM Stock WHERE Product = 'banana'"
Units
6
```

**Um pedido, e seis bananas**: dez menos as quatro da primeira execução, e nada da terceira. Essa é a
promessa de tudo ou nada, e ela valeu para uma escrita recusada depois de outras escritas da mesma
transação já terem dado certo.

## Leituras um pouco antigas

**Uma leitura forte vê toda transação confirmada antes de ela começar**, e é o padrão. O Spanner
oferece também **leituras stale**: uma leitura num timestamp do passado, dado exato ou como limite, que
devolve o banco como ele estava naquele momento. Uma leitura stale não precisa descobrir se existe uma
escrita mais recente, então qualquer réplica que esteja em dia até aquele timestamp pode responder,
inclusive uma em outra zona ou região, sem perguntar à réplica que lidera o split. Isso a deixa mais
rápida e mais barata onde os dados têm réplicas longe de quem lê.

`stale.py`:

```python
#!/usr/bin/env python3
"""Three reads of the same row: strong, at a past timestamp, and a bounded time ago."""
import datetime
import time

from google.cloud import spanner

db = spanner.Client(project='planner-dev').instance('quitanda').database('shop')
SQL = "SELECT Units FROM Stock WHERE Product = 'banana'"


def set_units(n):
    with db.batch() as batch:
        batch.update('Stock', ['Product', 'Units'], [('banana', n)])
    return batch.committed


first = set_units(6)
time.sleep(3)
set_units(40)

reads = {
    'strong': {},
    'at the first commit': {'read_timestamp': first},
    'exactly 2 seconds ago': {'exact_staleness': datetime.timedelta(seconds=2)},
}
for label, options in reads.items():
    with db.snapshot(**options) as snap:
        print(f'{label:<22} {list(snap.execute_sql(SQL))[0][0]}')
```

**Ele define o estoque duas vezes, com três segundos de intervalo, e depois o lê de três jeitos.**
`batch.committed` é o timestamp do commit que a primeira escrita devolveu, que é como um programa
guarda um momento para ler depois.

```
ana@laptop:~/gcp$ python3 stale.py
strong                 40
at the first commit    6
exactly 2 seconds ago  6
```

**`strong` viu a segunda escrita, e as duas leituras stale viram a primeira.** Uma leitura de 2
segundos atrás fica antes da segunda escrita e depois da primeira, então devolve 6. As páginas de
catálogo da Quitanda mostram quantas unidades há em estoque, e um número de quinze segundos basta ali;
o checkout, que pega as unidades, lê de forma forte dentro da transação, como o `order.py` faz.

**Várias leituras num mesmo momento são uma transação só de leitura.** Um relatório que lê `Orders` e
depois `Stock` e quer que os dois concordem abre um snapshot para os dois, `db.snapshot(multi_use=True)`
no cliente Python, e toda leitura dentro dele vê o banco no mesmo timestamp. Ela não trava nada e não
bloqueia nenhum escritor, e por isso um relatório longo cabe numa dessas e não numa transação de
leitura e escrita, onde as leituras dele segurariam travas enquanto ele rodasse.

## Onde o emulador fica devendo: uma transação de cada vez

`two.py`:

```python
#!/usr/bin/env python3
"""Two read-write transactions at once, on different rows. How long does each take?"""
import threading
import time

from google.cloud import spanner

db = spanner.Client(project='planner-dev').instance('quitanda').database('shop')
start = time.monotonic()
first_has_read = threading.Event()
slow_attempts = quick_attempts = 0


def slow(t):
    global slow_attempts
    slow_attempts += 1
    list(t.execute_sql("SELECT Units FROM Stock WHERE Product = 'banana'"))
    first_has_read.set()
    time.sleep(3)
    t.execute_update("UPDATE Stock SET Units = Units + 1 WHERE Product = 'banana'")


def quick(t):
    global quick_attempts
    quick_attempts += 1
    t.execute_update("UPDATE Stock SET Units = Units + 1 WHERE Product = 'rice-5kg'")


def second():
    first_has_read.wait()
    db.run_in_transaction(quick)
    print(f'rice-5kg committed after {time.monotonic() - start:.1f} s, on attempt {quick_attempts}')


other = threading.Thread(target=second)
other.start()
db.run_in_transaction(slow)
print(f'banana committed after {time.monotonic() - start:.1f} s, on attempt {slow_attempts}')
other.join()
```

**Duas transações em duas linhas diferentes**, que no Spanner não travam nada em comum e confirmam as
duas em cerca dos três segundos que a mais lenta dorme:

```
ana@laptop:~/gcp$ python3 two.py
banana committed after 3.0 s, on attempt 1
rice-5kg committed after 7.2 s, on attempt 3
```

**A banana levou os seus três segundos, e o arroz levou mais de sete, na terceira tentativa.** O
emulador abortou a transação rápida duas vezes enquanto a lenta estava aberta, e a biblioteca cliente a
repetiu a cada vez, com uma pausa que cresce entre as tentativas. A documentação do emulador lista isso
entre os limites dele: ele permite uma transação de leitura e escrita por vez, por mais que as linhas
não tenham relação, e uma segunda que se sobreponha é abortada. O Spanner de verdade teria rodado as
duas ao mesmo tempo e confirmado o arroz numa fração de segundo. **A lição a guardar é a repetição**,
não o atraso: `run_in_transaction` roda a função inteira de novo quando uma transação é abortada, no
emulador e no Spanner, então a função precisa ser segura para rodar duas vezes. Ler dentro da função,
como o `order.py` faz, é o que a torna segura; um valor lido antes da transação e reusado dentro dela
seria o bug.
