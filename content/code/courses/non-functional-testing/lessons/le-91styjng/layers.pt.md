---
title: Quatro camadas, e onde olhar primeiro
version: 1
---

A aula 8 mediu quão lenta a bilheteria é. Esta aula descobre para onde vai o tempo, e "o servidor
está lento" não é resposta, porque uma requisição passa por várias coisas no caminho até a
resposta e qualquer uma delas pode ser a que está cheia. **Um gargalo é o único recurso que,
ficando mais rápido, deixaria a requisição inteira mais rápida**; acelerar qualquer outra coisa
não muda nada que um usuário consiga ver.

Ajuda pensar numa requisição como algo que atravessa quatro camadas, cada uma dentro da anterior:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-layers\" aria-label=\"Uma requisição GET /shows/990 seguida por quatro camadas, da esquerda para a direita. O cliente, o curl, mediu 11.5 ms do começo ao fim. Dentro disso, a rede: a conexão, a fila do kernel de conexões esperando para serem aceitas, e os pacotes da resposta. Dentro disso, a aplicação, cujo cabeçalho Server-Timing disse 10.7 ms no total. Dentro disso, o banco de dados, que levou 10.2 ms contando as reservas. Debaixo das quatro fica a infraestrutura: processadores, memória e disco, divididos entre o servidor e o gerador de carga. Cada camada aparece com a ferramenta que a enxerga: curl -w e nstat para a rede, Server-Timing para a aplicação, EXPLAIN QUERY PLAN para o banco, top, vmstat e free para a infraestrutura.\"><rect x=\"20.0\" y=\"30.0\" width=\"680.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"32.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cliente</text><text x=\"32.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl: 11.5 ms</text><text x=\"688.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">curl -w</text><rect x=\"60.0\" y=\"82.0\" width=\"600.0\" height=\"168.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"72.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rede</text><text x=\"72.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conexão, fila de aceite, pacotes</text><text x=\"648.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nstat</text><rect x=\"100.0\" y=\"134.0\" width=\"520.0\" height=\"106.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"112.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aplicação</text><text x=\"112.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Server-Timing total: 10.7 ms</text><text x=\"608.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Server-Timing</text><rect x=\"140.0\" y=\"186.0\" width=\"440.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco de dados</text><text x=\"152.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db: 10.2 ms</text><text x=\"568.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">EXPLAIN QUERY PLAN</text><rect x=\"20.0\" y=\"268.0\" width=\"680.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></rect><text x=\"32.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">infraestrutura, debaixo de todas as camadas</text><text x=\"32.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">processadores, memória, disco, divididos com o gerador de carga</text><text x=\"688.0\" y=\"284.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">top  vmstat  free</text></svg>", "caption": "Cada camada contém a de dentro, então o tempo de cada camada inclui o das camadas internas. A diferença entre duas delas é o tempo gasto no meio."}
```

- **O cliente** manda a requisição e espera o último byte da resposta. O relógio dele cobre tudo.
- **A rede** a carrega: a conexão, a fila do sistema operacional de conexões esperando para serem
  aceitas, os pacotes de ida e de volta. Numa máquina só ela quase não custa nada; pela internet
  ela é muitas vezes a maior parte.
- **A aplicação** lê a requisição e monta a resposta: aqui o `app.py`, a trava dele e a chamada
  ao provedor de pagamento.
- **O banco de dados** responde às consultas da aplicação.

Debaixo das quatro fica **a infraestrutura**: os processadores, a memória e o disco, divididos
entre tudo o que roda na máquina, o gerador de carga inclusive.

## Subtraia um relógio do outro

O jeito mais rápido de localizar o tempo é ler um relógio em duas fronteiras e subtrair. O
`app.py` já informa o seu: toda resposta leva um cabeçalho `Server-Timing` com o tempo do banco,
o tempo do pagamento e o total, como a aula 1 mostrou. Com o servidor rodando no outro terminal:

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=10.2, pay;dur=0.0, total;dur=10.7
ana@nft:~/boxoffice$ curl -si -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}' | grep Server-Timing
Server-Timing: db;dur=15.7, pay;dur=40.1, total;dur=58.2
ana@nft:~/boxoffice$ curl -s -o /dev/null -w 'connect %{time_connect}  first byte %{time_starttransfer}  total %{time_total}\n' localhost:8000/shows/990
connect 0.000293  first byte 0.011364  total 0.011461
```

Leia as três linhas em ordem. Na consulta ao espetáculo 990, o banco levou 10.2 ms de um total do
servidor de 10.7: **o banco é quase tudo**. A reserva passou 15.7 ms no banco e 40.1 ms pagando,
55.8 ms de um total de 58.2; os 2.4 ms que sobram são código que o `Server-Timing` não mede, o
`INSERT` e o commit entre eles. Um número que não está dentro de nenhuma parte nomeada continua
sendo um número, e a subtração é como você o percebe.

A última linha pede ao `curl` o relógio dele, em três pontos. `time_connect` é quando a conexão
ficou aberta, 0.293 ms depois do início; `time_starttransfer` é o primeiro byte da resposta, em
11.364 ms; `time_total` é o último, em 11.461 ms. Entre a conexão e o primeiro byte o cliente
estava esperando o servidor, então **o cliente e o servidor concordam, e a rede quase não soma
nada aqui**. Quando o tempo do cliente e o total do servidor discordam muito, a diferença foi
gasta fora da aplicação, e "Rede e infraestrutura" mostra um caso em que discordam. O `curl` tem
mais desses pontos, `time_namelookup` para a consulta de DNS e `time_appconnect` para o aperto de
mão do TLS entre eles; nenhum importa em `127.0.0.1` sem TLS, então nenhum aparece aqui.

## O método USE

Os relógios dizem qual camada. Para achar qual recurso dentro de uma camada está cheio, o **método
USE** de Brendan Gregg faz três perguntas a cada recurso, de hardware ou de software:

| | a pergunta | para um processador |
|---|---|---|
| **utilização** | quanto do tempo ele ficou ocupado? | o `%CPU` de cada processo, o número `id` (ocioso) caindo |
| **saturação** | quanto trabalho ficou esperando por ele? | mais threads prontas para rodar do que processadores |
| **erros** | ele recusou ou descartou alguma coisa? | raramente, para um processador; muitas vezes, para uma fila ou uma rede |

Os recursos são os óbvios, processadores, memória, disco e rede, e os que um programa cria para
si mesmo: **uma trava, um pool de conexões, uma fila**. Um recurso de software não tem `%CPU` nem
contador no `top`, e por isso se esconde bem: ele satura enquanto todo o hardware parece ocioso.

Rode uma carga e olhe os processadores enquanto ela roda. A linha abaixo inicia oito workers em
segundo plano por doze segundos, com `&`, e dois segundos depois pede ao `top` dois retratos com
dois segundos de intervalo, guardando a linha que resume os processadores e as linhas dos dois
programas Python. `-c` mostra a linha de comando de cada um, que é como se distingue o servidor
do gerador, os dois sendo `python3`. O primeiro retrato não tem nada antes dele para comparar,
então leia o segundo:

```
ana@nft:~/boxoffice$ python3 measure.py 8 12 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep -E 'Cpu\(s\)|python3 [am]'; wait
%Cpu(s): 57.5 us, 40.0 sy,  0.0 ni,  2.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
     13 ana       20   0  906264  34448  11632 S 180.0   0.2   0:03.89 python3 app.py
     43 ana       20   0  616004  18308   9712 S   0.0   0.1   0:00.15 python3 measure.py 8 12
%Cpu(s): 56.7 us, 29.6 sy,  0.0 ni,  8.6 id,  3.2 wa,  0.0 hi,  1.1 si,  0.9 st 
     13 ana       20   0 1020912  33628  11632 S 212.5   0.2   0:08.14 python3 app.py
     43 ana       20   0  616004  18340   9712 S   6.5   0.1   0:00.28 python3 measure.py 8 12
ana@nft:~/boxoffice$ head -4 load.txt
8 workers, 12.0 s: 2206 requests, 183.5 per second
status: 200 x2206
ms          count    mean  median     p90     p95     p99     max
all          2206    43.5    41.4    65.1    74.2    92.5   126.4
```

No segundo retrato o `python3 app.py` está usando 212.5% de um processador, mais de dois dos
quatro, e o `measure.py` 6.5%. A linha `%Cpu(s)` diz que a máquina estava 8.6% ociosa. Essa linha
cobre o computador inteiro em que as transcrições foram gravadas, que estava fazendo outro
trabalho ao mesmo tempo, então a sua vai mostrar mais ociosidade; os números por processo são os
da própria bilheteria. **O servidor está usando os processadores e o gerador não**: a utilização
está alta, no processo da camada da aplicação. O `Server-Timing` já disse qual parte dela. A seção
seguinte trata dessa parte.
