---
title: Locust, num ambiente virtual
version: 1
---

O Locust vai um passo além do k6 e do Gatling: **o teste é um programa Python, e o Locust é uma
biblioteca que ele importa.** Não há DSL para aprender além de algumas classes e um decorador, e
tudo o que o Python faz um teste também faz. É a escolha natural para um time que já escreve Python.

## Instalando

O Locust vem do PyPI, e vai para um ambiente virtual próprio em vez do Python do sistema, que o
Ubuntu 24.04 não deixa o `pip` alterar. O ambiente é `~/venv`; a aula 21 acrescenta uma segunda
ferramenta a ele.

```sh
python3 -m venv ~/venv
~/venv/bin/pip install locust==2.46.7
```

Essas duas linhas foram rodadas quando a máquina das transcrições foi montada. Confira o que você
tem:

```
ana@nft:~/locust$ ~/venv/bin/locust --version
locust 2.46.7 from /home/ana/venv/lib/python3.12/site-packages/locust (Python 3.12.3)
```

## Um locustfile

Crie uma pasta para ele e abra o arquivo com `mkdir -p ~/locust && nano ~/locust/locustfile.py`:

```schooling-example
{"language": "python", "file": "locust/locustfile.py", "parts": [{"code": "# locust/locustfile.py\nimport os, random\nfrom locust import HttpUser, between, events, task\n\n", "note": "Python comum, e o Locust é uma biblioteca qualquer importada do ambiente virtual. Tudo o que o Python faz um locustfile também faz: ler um arquivo, chamar uma função sua, importar outro módulo."}, {"code": "class Visitor(HttpUser):\n    wait_time = between(1, 3)\n\n    def on_start(self):\n        self.customer = f\"locust{random.randint(1, 10000)}\"\n", "note": "Um usuário é uma classe. `HttpUser` dá a ela o `self.client`, uma sessão HTTP que guarda a conexão e os cookies como um navegador. `wait_time = between(1, 3)` é o tempo de reflexão, uma espera aleatória depois de cada tarefa. `on_start` roda uma vez por usuário antes da primeira tarefa, aqui para dar a cada um um nome de cliente."}, {"code": "    @task(3)\n    def look_at_a_show(self):\n        show = random.randint(981, 1000)\n        with self.client.get(f\"/shows/{show}\", name=\"/shows/[id]\", catch_response=True) as r:\n            if r.status_code != 200 or not isinstance(r.json().get(\"left\"), int):\n                r.failure(f\"show answered {r.status_code}\")\n", "note": "Uma tarefa é um método com `@task`, e o número é o peso: esta é sorteada três vezes mais que uma de peso 1, então três em cada quatro tarefas olham um espetáculo. `name=` junta os vinte endereços numa linha só das estatísticas. Com `catch_response=True`, o bloco decide se a requisição conta como sucesso: um 200 sem um `left` numérico é marcado como falha."}, {"code": "    @task(1)\n    def book_a_seat(self):\n        order = {\"show_id\": random.randint(981, 1000), \"seat\": random.randint(1, 300),\n                 \"customer\": self.customer}\n        with self.client.post(\"/bookings\", json=order, catch_response=True) as r:\n            if r.status_code == 409:\n                r.success()\n            elif r.status_code != 201:\n                r.failure(f\"booking answered {r.status_code}\")\n", "note": "A reserva, sorteada uma vez em cada quatro. O Locust conta como falha qualquer status de 400 para cima por padrão, então o 409 de um assento já ocupado é marcado como sucesso à mão, e tudo o que não é 201 é marcado como falha."}, {"code": "\n@events.quitting.add_listener\ndef judge(environment, **kwargs):\n    total = environment.stats.total\n    p95 = environment.stats.get(\"/shows/[id]\", \"GET\").get_response_time_percentile(0.95)\n    if total.fail_ratio > 0.01 or p95 > int(os.environ.get(\"P95\", 200)):\n        print(f\"FAIL: errors {total.fail_ratio:.2%}, p95 of /shows/[id] {p95} ms\")\n        environment.process_exit_code = 1", "note": "O Locust não tem limites. O código de saída dele é 1 se alguma requisição falhou e 0 caso contrário, e um aprovado ou reprovado sobre um percentil precisa ser escrito. Esta função roda quando o teste termina, lê as estatísticas e põe o código de saída em 1 quando os erros passam de 1% ou o percentil 95 de `/shows/[id]` passa do limite: 200 ms, ou o valor da variável de ambiente `P95`."}]}
```

## Rodando sem a página web

Iniciado sem opções, o Locust abre uma página web na porta 8089 onde você digita o número de
usuários e aperta um botão. **Para um teste que precisa dar o mesmo veredito toda vez, rode-o sem
interface** (*headless*): `-u` é o número de usuários, `-r` quantos começam a cada segundo, `-t`
quanto dura o teste, e `--only-summary` guarda as estatísticas para o fim em vez de imprimi-las a
cada poucos segundos. Com a bilheteria rodando no primeiro terminal:

```
ana@nft:~/locust$ ~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary --csv boxoffice; echo "exit $?"
[2026-10-10 16:38:44,973] nft/INFO/locust.main: Starting Locust 2.46.7
[2026-10-10 16:38:44,974] nft/INFO/locust.main: Run time limit set to 20 seconds
[2026-10-10 16:38:44,975] nft/INFO/locust.runners: Ramping to 10 users at a rate of 2.00 per second
[2026-10-10 16:38:48,981] nft/INFO/locust.runners: All users spawned: {"Visitor": 10} (10 total users)
[2026-10-10 16:39:04,974] nft/INFO/locust.main: --run-time limit reached, shutting down
[2026-10-10 16:39:05,002] nft/INFO/locust.main: Shutting down (exit code 0)
Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
POST     /bookings                                                                         25     0(0.00%) |     54      11     123     61 |    1.25        0.00
GET      /shows/[id]                                                                       72     0(0.00%) |     19      10      45     18 |    3.60        0.00
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                        97     0(0.00%) |     28      10     123     20 |    4.84        0.00

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
POST     /bookings                                                                              61     66     71     73     97    110    120    120    120    120    120     25
GET      /shows/[id]                                                                            18     20     23     23     28     30     40     46     46     46     46     72
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                             20     23     28     31     65     73    110    120    120    120    120     97

exit 0
ana@nft:~/locust$ ls boxoffice*
boxoffice_exceptions.csv
boxoffice_failures.csv
boxoffice_stats.csv
boxoffice_stats_history.csv
```

**A primeira tabela traz as contagens e os tempos; a segunda, os percentis.** Leia as linhas antes
dos números. Foram 72 requisições de espetáculo e 25 reservas, perto dos três para um que os pesos
das tarefas pedem, e a linha `Aggregated` mistura os dois tipos, e por isso a mediana dela, de 20 ms,
não descreve nem os espetáculos, a 18 ms, nem as reservas, a 61 ms. As reservas carregam o pagamento
de 40 ms, e a linha `GET` traz os números de que fala o requisito da aula 1: um percentil 95 de
30 ms.

**O Locust é um modelo fechado.** Dez usuários, cada um esperando entre um e três segundos depois de
cada tarefa, mandam mais ou menos uma requisição a cada dois segundos cada, e a execução chegou a
4.84 requisições por segundo no total. Se a bilheteria ficasse lenta, cada usuário esperaria a
resposta antes da próxima espera, e a taxa cairia junto. `wait_time = constant_throughput(0.5)` dá a
cada usuário o ritmo de uma tarefa a cada dois segundos, levem as respostas o que levarem, o que
mantém a taxa até as próprias respostas passarem de dois segundos. Os percentis aparecem como
*approximated* porque o Locust arredonda cada tempo antes de contar: para o milissegundo abaixo de
100 ms, e para a dezena mais próxima daí até um segundo, e é por isso que as reservas mostram 110 e
120.

`--csv boxoffice` escreveu as mesmas estatísticas em arquivos, ao lado do locustfile, que é a forma
que uma planilha ou um pipeline querem: `boxoffice_stats.csv` tem as duas tabelas, e
`boxoffice_stats_history.csv` uma linha de totais a cada poucos segundos da execução.

O juiz no fim do arquivo também precisa funcionar no outro sentido. `P95=5` define um limite que
ninguém alcançaria:

```
ana@nft:~/locust$ P95=5 ~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary > fail.log 2>&1; echo "exit $?"
exit 1
ana@nft:~/locust$ grep -E 'FAIL|exit code' fail.log
[2026-10-10 16:39:25,524] nft/INFO/locust.main: Shutting down (exit code 1)
FAIL: errors 0.00%, p95 of /shows/[id] 29 ms
```

**O código de saída é 1, e o motivo aparece impresso.** Sem a função, o Locust teria saído com 0
aqui, porque nenhuma requisição falhou; um teste lento passa, a não ser que alguém tenha escrito o
que lento quer dizer.
