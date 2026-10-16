---
title: A resposta para quem gastou o quê
version: 1
---

**"Quem gastou o quê" são duas perguntas, e um relatório responde à primeira com muito mais
facilidade que à segunda.** Qual conta gastou é uma coluna, preenchida em toda linha. Qual time
gastou é uma tag, preenchida só onde alguém marcou o recurso e o faturamento ativou a chave. As
linhas em que isso não aconteceu não são um erro a limpar. São uma parte da resposta, **o resto sem
tag**, e um relatório que o esconde dá a cada time um número que soma menos que a fatura.

## Cada time, contado de dois jeitos

Duas perguntas, cada uma num arquivo próprio, porque uma pergunta de uma dúzia de linhas fica melhor
num arquivo que na linha de comando. Escreva as duas em `~/aws`:

```sh
cat > team.sql <<'EOF'
-- Each team's month, unblended and amortised, before tax and credits.
SELECT coalesce(json_extract(resource_tags, '$.user_team'), '(no team)') AS team,
       sum(line_item_unblended_cost) AS unblended,
       sum(CASE line_item_line_item_type
             WHEN 'SavingsPlanCoveredUsage' THEN savings_plan_savings_plan_effective_cost
             WHEN 'SavingsPlanNegation' THEN 0
             WHEN 'SavingsPlanRecurringFee' THEN 0
             ELSE line_item_unblended_cost
           END) AS amortised
FROM cur
WHERE line_item_line_item_type NOT IN ('Tax', 'Credit')
GROUP BY team
ORDER BY amortised DESC;
EOF
cat > remainder.sql <<'EOF'
-- What no team's tag claims, by account and usage type.
SELECT line_item_usage_account_id AS account,
       line_item_usage_type AS usage_type,
       sum(line_item_unblended_cost) AS unblended
FROM cur
WHERE json_extract(resource_tags, '$.user_team') IS NULL
  AND line_item_line_item_type NOT IN ('Tax', 'Credit', 'SavingsPlanRecurringFee')
GROUP BY account, usage_type
ORDER BY unblended DESC;
EOF
```

A primeira é o mês de cada time, antes de impostos e créditos, contado duas vezes. O **não
combinado** (*unblended*) soma as linhas como foram cobradas. O **amortizado** troca as três linhas
do Savings Plan pelo que a hora coberta custou na tarifa do plano,
`savings_plan_savings_plan_effective_cost`, então o custo do plano cai na linha que o usou:

```
ana@laptop:~/aws$ python3 ask.py team.sql
team       unblended  amortised
web           376.55     456.23
data          165.90     165.90
(no team)     210.82     131.14
```

**As duas colunas discordam em exatamente 79,68, a taxa do plano no mês**, e a discordância é a
lição. Sem combinar, a instância do time web sob o plano parece de graça. O uso coberto e a negação
dele se anulam, e os 79,68 ficam na linha da taxa, que não tem tag, então caem em `(no team)`.
Amortizados, os 79,68 vão para o time web, onde as horas foram usadas, e o resto encolhe na mesma
medida. O time de dados não comprou nada adiantado e é igual nos dois. Este mês o plano cobriu a
instância dele em toda hora. Num mês com horas paradas, a parte não usada da taxa seria um custo
próprio, que o `team.sql` teria de manter em vez de zerar. **Para "quem gastou o quê", o amortizado
é a coluna honesta.** Ele cobra um compromisso do uso que ele cobriu, e não de quem calhou de
comprá-lo. O não combinado continua a coluna certa para "quanto pagamos este mês", que é uma
pergunta do financeiro e não dos times.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-amortise\" aria-label=\"O mês de cada time no relatório inventado, em dólares, antes de impostos e créditos, contado de dois jeitos. Web: 376,55 sem combinar, 456,23 amortizado. Data: 165,90 dos dois jeitos. Sem time: 210,82 sem combinar, 131,14 amortizado. A diferença, 79,68 dólares, é a taxa do Savings Plan, que o não combinado deixa sem tag e o amortizado põe no time web que a usou.\"><path d=\"M80.0 250.0 L690.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"72.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"72.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"72.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"72.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"80.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dólares, antes de impostos e créditos</text><rect x=\"130.0\" y=\"99.4\" width=\"52.0\" height=\"150.6\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"90.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">376,55</text><rect x=\"192.0\" y=\"67.5\" width=\"52.0\" height=\"182.5\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">456,23</text><text x=\"187.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web</text><rect x=\"320.0\" y=\"183.6\" width=\"52.0\" height=\"66.4\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"174.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">165,90</text><rect x=\"382.0\" y=\"183.6\" width=\"52.0\" height=\"66.4\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"408.0\" y=\"174.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">165,90</text><text x=\"377.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data</text><rect x=\"510.0\" y=\"165.7\" width=\"52.0\" height=\"84.3\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"156.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">210,82</text><rect x=\"572.0\" y=\"197.5\" width=\"52.0\" height=\"52.5\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">131,14</text><text x=\"567.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">(sem time)</text><rect x=\"520.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"538.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não combinado</text><rect x=\"520.0\" y=\"50.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"538.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">amortizado</text><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">dados inventados, do cur.csv; os 79,68 que mudam de lugar são a taxa do Savings Plan</text></svg>", "caption": "O amortizado tira a taxa do plano de ninguém e a põe no time cujas horas ela cobriu."}
```

## O resto, linha por linha

```
ana@laptop:~/aws$ python3 ask.py remainder.sql
account       usage_type                    unblended
444455556666  SAE1-NatGateway-Hours             67.89
777788889999  SAE1-BoxUsage:m7i.large           24.10
444455556666  SAE1-NatGateway-Bytes             18.60
111122223333  SAE1-PublicIPv4:InUseAddress       7.30
444455556666  SAE1-PublicIPv4:IdleAddress        7.30
777788889999  USE1-APIRequest                    3.00
777788889999  SAE1-PublicIPv4:InUseAddress       1.75
111122223333  USE1-APIRequest                    1.20
```

**131,14 dólares que nenhuma tag de time reivindica, e cada linha tem uma conta e um tipo de uso que
dizem o que ela é.** As maiores linhas são o NAT gateway de staging da lição 14, as horas e os bytes
dele, e uma instância do sandbox sem tag. Nada disso é misterioso. É sem dono. A última consulta põe
o resto ao lado do uso de cada conta:

```
ana@laptop:~/aws$ python3 ask.py "SELECT line_item_usage_account_id AS account, sum(line_item_unblended_cost) AS usage, sum(CASE WHEN json_extract(resource_tags, '$.user_team') IS NULL THEN line_item_unblended_cost ELSE 0 END) AS untagged FROM cur WHERE line_item_line_item_type = 'Usage' GROUP BY account"
account        usage  untagged
111122223333  382.55      8.50
444455556666  227.06     93.79
777788889999   63.98     28.85
```

O uso de produção está quase todo reivindicado, 8,50 sem tag de 382,55. O de staging é 93,79 de
227,06, **41%**. Esse número diz à loja por onde começar a pôr tags, e onde as políticas de tag da
lição 13 e uma SCP exigindo `team` teriam valido a pena.

## Showback, chargeback, e o jeito da AWS de rodar isto

O que uma loja faz com a resposta tem dois nomes. **Showback** manda a cada time o seu número, todo
mês, e nenhum dinheiro se move: o ponto é que as pessoas que ligam máquinas vejam quanto as máquinas
custam. **Chargeback** vai além e põe o custo no orçamento de cada time, uma fatura interna. Isso
faz o número importar, e faz de cada regra por trás dele um motivo de discussão. Nos dois casos as
regras têm de ser escritas antes de o primeiro relatório sair:

- **o resto sem tag** pertence a alguém, por uma regra: ao dono da conta, ou dividido entre os times
  na proporção do que eles reivindicaram;
- **compromissos** são cobrados amortizados, do uso que cobriram, para que o time que comprou o plano
  para todos não seja o time que parece caro;
- **linhas compartilhadas**, imposto, suporte e créditos, também são divididas por uma regra, em geral
  na proporção do uso de cada time, porque nenhuma tag vai reivindicá-las.

No tamanho de uma organização real, o relatório são milhões de linhas de Parquet num bucket. O jeito
da AWS de consultá-lo é o **Amazon Athena**, que roda SQL direto sobre arquivos no S3, com o
**Amazon QuickSight** desenhando os painéis que um time de fato abre. Nenhum dos dois foi rodado
para este curso, porque os dois precisam do relatório real para ler. O SQL acima mudaria pouco: o
Athena lê o mapa `resource_tags` com a sintaxe dele em vez de `json_extract`, e o `GROUP BY` fica.
Agrupar contas e tags em unidades de negócio por regra, sem reescrever cada consulta, é o que fazem
as **Cost Categories**, e a lição 24 de `aws-operations` as constrói.
