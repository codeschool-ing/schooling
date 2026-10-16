---
title: Quanto uma instância custa num mês
version: 1
---

**Uma instância RDS é cobrada por duas coisas que rodam o tempo todo e uma que cresce**: a instância,
por hora, com ou sem alguém consultando; o armazenamento, por GiB alocado, cheio ou não; e os backups,
além de uma franquia. Não há cobrança por consulta nem por linha, o oposto dos serviços das lições 9 e
15, e isso quer dizer que um banco ocioso custa exatamente o que custa um ocupado. O bloco RDS da tabela
de preços:

```
ana@laptop:~/aws$ python3 prices.py rds
AWS public price list, sa-east-1, USD, excluding tax

RDS, USD per hour
  PostgreSQL, db.m7g.large, Single-AZ                   0.22100  hour
  MySQL, db.m7g.large, Single-AZ                        0.22100  hour
  MariaDB, db.m7g.large, Single-AZ                      0.22100  hour
  PostgreSQL, db.m7g.large, Multi-AZ                    0.44200  hour
  PostgreSQL, db.t4g.micro, Single-AZ                   0.03400  hour
  SQL Server Standard, db.m6i.large, licence in         1.08700  hour

RDS storage and backup, USD per GB-month
  gp3, Single-AZ                                        0.21900  GB-month
  gp3, Multi-AZ                                         0.43800  GB-month
  backup beyond the free allowance                      0.09500  GB-month
```

## Um mês são 730 horas

A AWS cobra por hora e a tabela cita por hora, e o mês que este curso usa é o que a AWS usa na própria
calculadora: 365 dias vezes 24 horas divididos por 12 meses, 730 horas. Quatro instâncias que a
Quitanda poderia rodar, com preços das linhas acima:

| instância | engine | instância por mês | armazenamento gp3 por mês | total |
|---|---|---|---|---|
| `db.t4g.micro`, 20 GiB | PostgreSQL | 0,034 × 730 = 24,82 | 20 × 0,219 = 4,38 | **29,20** |
| `db.m7g.large`, 100 GiB | PostgreSQL | 0,221 × 730 = 161,33 | 100 × 0,219 = 21,90 | **183,23** |
| `db.m7g.large` Multi-AZ, 100 GiB | PostgreSQL | 0,442 × 730 = 322,66 | 100 × 0,438 = 43,80 | **366,46** |
| `db.m6i.large`, 100 GiB | SQL Server Standard | 1,087 × 730 = 793,51 | 100 × 0,219 = 21,90 | **815,41** |

**A micro é para desenvolvimento, e para mais nada.** Duas vCPUs burstable e 1 GiB de memória bastam
para rodar as migrações e os testes contra um engine de verdade, e 29,20 por mês é menos do que o tempo
que alguém gastaria discutindo isso. Não é onde moram os pedidos da Quitanda.

**PostgreSQL, MySQL e MariaDB custam o mesmo na mesma máquina**: 0,221 por hora cada um numa
`db.m7g.large`. O engine é gratuito e o que tem preço é o trabalho da AWS, que é o mesmo para os três.
Então, entre os engines de código aberto, a escolha é sobre o banco e nunca sobre o preço.

**O Multi-AZ é exatamente o dobro**, a instância e o armazenamento, porque é uma segunda instância com um
segundo volume em outra zona, mantida em sincronia com a primeira. A lição 7 é o que essa segunda cópia
compra.

**A licença é a maior parte da conta do SQL Server.** Uma `db.m6i.large` tem as mesmas 2 vCPU e 8 GiB da
`db.m7g.large` e custa 1,087 por hora contra 0,221: 4,9 vezes mais, e a diferença é a licença da
Microsoft, que o RDS inclui e cobra por hora. Uma empresa com SQL Server no armário paga essa diferença
todo mês em que continua com ele, o argumento comercial mais forte para trocar de engine em vez de só
de servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Custo mensal de quatro instâncias RDS em São Paulo, 730 horas, dividido em instância e armazenamento gp3. db.t4g.micro PostgreSQL com 20 GiB: 24,82 mais 4,38, 29,20. db.m7g.large PostgreSQL com 100 GiB: 161,33 mais 21,90, 183,23. A mesma em Multi-AZ: 322,66 mais 43,80, 366,46. db.m6i.large SQL Server Standard com licença incluída e 100 GiB: 793,51 mais 21,90, 815,41.\" data-fig=\"l06-monthly\"><defs><marker id=\"arr-l06-monthly\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"220.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.t4g.micro</text><text x=\"220.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL, 20 GiB</text><rect x=\"230.0\" y=\"40.0\" width=\"12.8\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"242.8\" y=\"40.0\" width=\"2.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"253.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">29.20</text><text x=\"220.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m7g.large</text><text x=\"220.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL, 100 GiB</text><rect x=\"230.0\" y=\"90.0\" width=\"83.1\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"313.1\" y=\"90.0\" width=\"11.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"332.4\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">183.23</text><text x=\"220.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m7g.large</text><text x=\"220.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL Multi-AZ, 100 GiB</text><rect x=\"230.0\" y=\"140.0\" width=\"166.2\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"396.2\" y=\"140.0\" width=\"22.6\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"426.8\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">366.46</text><text x=\"220.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m6i.large</text><text x=\"220.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL Server Standard, 100 GiB</text><rect x=\"230.0\" y=\"190.0\" width=\"408.7\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"638.7\" y=\"190.0\" width=\"11.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"658.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">815.41</text><line x1=\"230.0\" y1=\"236.0\" x2=\"650.0\" y2=\"236.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"230.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"650.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">815.41</text><text x=\"440.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD por mês, 730 horas</text><rect x=\"470.0\" y=\"38.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">instância</text><rect x=\"570.0\" y=\"38.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"588.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">armazenamento</text></svg>", "caption": "O mesmo tamanho de máquina: a licença do SQL Server é a maior parte da conta, e o Multi-AZ dobra as duas partes.", "same": ["PostgreSQL, 20 GiB", "PostgreSQL, 100 GiB", "PostgreSQL Multi-AZ, 100 GiB", "SQL Server Standard, 100 GiB"]}
```

## O armazenamento é alocado, não usado

**Você paga pelos 100 GiB que pediu**, no dia em que pede, com o banco guardando 3 GiB ou 99. O
armazenamento no RDS cresce e não encolhe: `modify-db-instance` aumenta a alocação sem reinício, e o
autoscaling de armazenamento aumenta por você quando o espaço livre fica curto, até um teto que você
define. Diminuir significa levar os dados para uma instância nova com um volume menor. Então aloque
para o próximo ano, não para os próximos cinco, e defina o teto do autoscaling.

**Os backups são gratuitos até o tamanho do banco.** A AWS documenta uma franquia de armazenamento de
backup igual ao armazenamento provisionado na região, e cobra 0,095 por GiB-mês além dela. Sete dias de
backups automáticos de um banco de 100 GiB que muda devagar ficam dentro da franquia; trinta e cinco dias
de um banco que se reescreve toda noite, não. A lição 7 mostra o que são os backups, e os snapshots
manuais, guardados até alguém apagá-los, são onde essa linha costuma crescer.

## Os dois jeitos de pagar menos

**Uma instância parada continua pagando o armazenamento.** `stop-db-instance` para a cobrança por hora
da máquina, e o RDS liga a instância de novo sozinho depois de sete dias, um limite documentado que pega
quem queria parar um banco de teste por um mês. Para uma instância necessária só no horário comercial,
pará-la à noite compensa; para uma que só será necessária daqui a um mês, um snapshot e uma exclusão
compensam, e a lição 7 restaura a partir de um.

**Um compromisso é o outro jeito**, uma Reserved Instance por um ou três anos em troca de um preço por
hora menor, e é uma decisão sobre o negócio mais do que sobre o banco. A lição 14 do `aws-foundations`
lê a conta com ela, e nenhum preço desta lição inclui uma.
