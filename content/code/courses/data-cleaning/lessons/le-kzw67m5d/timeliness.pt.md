---
title: Atualidade: a partir de quando?
version: 1
---

**A atualidade pergunta se o dado é recente o bastante para a pergunta que se faz a ele.** Todo
arquivo é uma fotografia tirada num momento, e o momento raramente vem escrito nela. Um arquivo de
clientes exportado de manhã está completo para tudo o que aconteceu antes do café e calado sobre
tudo depois.

A pergunta mais útil a fazer a qualquer arquivo é, portanto, **de quando é isto?** O arquivo de
clientes não diz. O site escreve as datas de cadastro num formato que ordena direito, então a mais
recente delas é uma boa estimativa:

```
ana@lab:~/clean$ psql -c "SELECT max(signed_up) FROM raw.customers WHERE signup_channel = 'site'"
    max     
------------
 2025-12-10
(1 row)
```

O último cadastro pelo site que o CRM conhece é de 10 de dezembro. Os pedidos vão até 31 de
dezembro. Qualquer cliente que se cadastrou nessas três semanas e depois comprou tem pedidos num
arquivo e nenhuma conta no outro. Contando os pedidos cujo cliente falta:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS orders, count(DISTINCT customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)"
 orders | customers 
--------+-----------
    246 |        32
(1 row)
```

246 pedidos de 32 clientes não pertencem a ninguém que o arquivo de clientes conheça. Por mês:

```
ana@lab:~/clean$ psql -c "SELECT left(ordered_at, 7) AS month, count(*) AS orders FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id) GROUP BY 1 ORDER BY 1"
  month  | orders 
---------+--------
 2025-01 |     19
 2025-02 |     18
 2025-03 |     15
 2025-04 |     24
 2025-05 |     13
 2025-06 |     26
 2025-07 |     22
 2025-08 |     19
 2025-09 |     13
 2025-10 |     16
 2025-11 |     16
 2025-12 |     45
(12 rows)
```

Todo mês tem alguns, entre 13 e 26, e dezembro tem 45. O gráfico por dia mostra onde os extras
começam:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-export-gap\" aria-label=\"Pedidos por dia em dezembro de 2025 cujo cliente falta no customers.csv. Até o dia dez, quando o arquivo de clientes foi exportado, metade dos dias não tem nenhum e nenhum dia tem mais de dois. Do dia treze em diante, todo dia tem entre um e quatro.\"><path d=\"M70.0 50.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 240.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 202.0 L690.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 202.0 L70.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M70.0 164.0 L690.0 164.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 164.0 L70.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"164.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M70.0 126.0 L690.0 126.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 126.0 L70.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"126.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M70.0 88.0 L690.0 88.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 88.0 L70.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M70.0 50.0 L690.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 50.0 L70.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos sem cliente</text><path d=\"M70.0 240.0 L690.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 240.0 L80.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M160.0 240.0 L160.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"160.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M260.0 240.0 L260.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"260.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M360.0 240.0 L360.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M460.0 240.0 L460.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"460.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M560.0 240.0 L560.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M680.0 240.0 L680.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><text x=\"380.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dia de dezembro de 2025</text><rect x=\"72.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"112.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"132.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"152.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"232.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"312.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"332.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"352.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"372.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"392.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"412.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"432.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"452.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"472.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"492.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"532.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"552.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"572.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"592.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"612.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"632.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"652.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"672.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M270.0 240.0 L270.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"270.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">customers.csv exportado</text></svg>", "caption": "O arquivo de clientes para em 10 de dezembro e os pedidos não. Depois dessa linha, os pedidos de um cliente novo não têm conta a que pertencer."}
```

**Neste ponto o arquivo não está errado; está velho.** Toda conta que ele lista está lá, e as que
faltam simplesmente chegaram depois da fotografia. Pedir ao time do CRM uma exportação tirada
depois de 31 de dezembro traz esses clientes de volta, e nenhuma limpeza conseguiria isso.

## E os órfãos que não são questão de tempo

Os meses antes de dezembro também têm órfãos, num ritmo constante, e esses clientes não eram novos.
Perguntado, o time do CRM explica que doze contas foram apagadas a pedido dos titulares, como a LGPD
permite a qualquer pessoa pedir. Os pedidos ficam, porque uma venda é um registro fiscal; a pessoa
não. A aula 11 decide o que um relatório deve fazer com pedidos assim, e a aula 7 do
`data-governance` trata da lei por trás deles.

Duas causas, um sintoma. Isso é comum o bastante para virar hábito: **quando uma regra falha,
separe as falhas por alguma coisa — um mês, um canal, uma origem — antes de decidir o que
significam.** Uma taxa uniforme costuma querer dizer uma causa em todo lugar, e um pico quer dizer
que algo aconteceu num dia que alguém sabe nomear.

## Latência e idade

Dois números descrevem a atualidade, e vale mantê-los separados:

- **latência** é quanto tempo depois de um evento o dado o mostra. O arquivo de pedidos mostra um
  pedido no mesmo dia; o CRM, para quem lê esta exportação, mostra um cliente novo com até três
  semanas de atraso;
- **idade** é quão velho é o registro mais novo no momento em que você o usa. Em 5 de janeiro, a
  exportação do CRM tem 26 dias.

Qual dos dois importa depende, de novo, da pergunta. Para um relatório anual, a idade de um arquivo
de clientes quase não importa, desde que ele tenha sido tirado depois do fim do ano. Para uma lista
de clientes a ligar esta tarde, é tudo.
