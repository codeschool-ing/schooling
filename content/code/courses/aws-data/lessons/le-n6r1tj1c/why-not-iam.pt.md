---
title: Por que IAM e políticas de bucket deixam de bastar
version: 1
---

**O IAM e uma política de bucket decidem quem pode ler um objeto, e as perguntas de um lake são
sobre tabelas, colunas e linhas.** Uma política consegue dizer "este papel pode ler as chaves em
`curated/orders/`". Não consegue dizer "este papel pode ler os pedidos mas não o telefone dos
clientes", porque o telefone é uma coluna, e uma coluna está dentro do objeto. Quem pode ler o
arquivo lê cada byte dele. É todo o motivo de o Lake Formation existir, e vale a pena ver isso antes
de qualquer outra coisa.

Os pedidos curados da Quitanda trazem um telefone para o entregador. Monte um dia deles, com números
que não pertencem a ninguém:

```sh
mkdir -p lake
cat > lake/part-0.csv <<'EOF'
order_id,customer_id,total_cents,phone
01-1,c-17,4590,+55 11 90000-0017
01-2,c-03,12800,+55 11 90000-0003
01-3,c-22,990,+55 11 90000-0022
EOF
```

Com o moto rodando no terminal dele e as quatro linhas de "Seu laboratório, em resumo" da lição 1
digitadas neste, ponha o arquivo onde a camada curada guarda os pedidos, e leia-o de volta como
qualquer principal com `s3:GetObject` naquela chave leria:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp lake/part-0.csv s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv
upload: lake/part-0.csv to s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv -
order_id,customer_id,total_cents,phone
01-1,c-17,4590,+55 11 90000-0017
01-2,c-03,12800,+55 11 90000-0003
01-3,c-22,990,+55 11 90000-0022
```

**Todas as colunas voltaram, os telefones junto com o resto.** Não existe requisição ao S3 que
devolva três colunas de um CSV e deixe a quarta de fora; o objeto é a unidade que o S3 conhece. Um
analista que precisa dos totais por cliente e não tem nada a ver com telefones recebe os telefones
mesmo assim, enquanto a permissão estiver escrita no IAM.

## O que é preciso só com o IAM

**Dar a um time uma tabela pelo IAM quer dizer conceder duas coisas, em dois serviços que não sabem
nada um do outro.** Uma é o catálogo: `glue:GetTable`, `glue:GetPartitions` e parentes no banco e na
tabela, para que o Athena descubra o que a tabela é. A outra são os dados: `s3:GetObject` e
`s3:ListBucket` no prefixo da tabela, para que ele consiga ler os arquivos. Falte a primeira e a
consulta falha antes de começar; falte a segunda e ela falha no primeiro arquivo. As duas são
escritas por papel, por tabela ou por prefixo.

**É a aritmética que deixa de escalar.** A Quitanda tem seis times e quarenta tabelas na camada
curada. Toda mudança de quem pode ler o quê é uma edição numa política JSON no IAM, às vezes em
duas. E "quem consegue ler a coluna de telefone?" não tem resposta a não ser ler toda política e toda
política de bucket e descobrir quais prefixos cada uma cobre. Nada no IAM consegue esconder uma
coluna. O remendo de sempre é uma segunda cópia da tabela sem a coluna, em outro prefixo, e uma
segunda cópia é uma segunda coisa para manter em dia, pagar e proteger.

## Os níveis de que um lake precisa

**Uma permissão para um lake tem de conseguir parar num banco, numa tabela, numa coluna, numa linha
ou numa única célula.** O IAM para no objeto e no prefixo, que estão um nível abaixo da tabela num
sentido e acima dela em outro: um prefixo guarda os arquivos de uma tabela inteira, e um arquivo
guarda todas as colunas das linhas que tem. O Lake Formation acrescenta os níveis que o IAM não tem,
e faz isso se pondo entre o motor de consulta e os arquivos, que é a próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois aninhamentos lado a lado. À esquerda, S3 e IAM: um bucket, quitanda-curated-prod, contém um prefixo, curated/orders/, que contém um objeto, part-0.csv, com todas as colunas e todas as linhas num pedaço só; o objeto é a menor coisa que o IAM nomeia. À direita, o Glue Data Catalog e o Lake Formation: o banco curated contém a tabela orders, desenhada como uma grade de quatro colunas, order_id, customer_id, total_cents e phone, por três linhas; o Lake Formation chega a uma coluna, uma linha ou uma célula. A coluna phone está destacada.\" data-fig=\"l18-levels-pt\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3 e IAM</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bucket</text><text x=\"310\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-curated-prod</text><rect x=\"36\" y=\"60\" width=\"268\" height=\"166\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefixo</text><text x=\"294\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">curated/orders/</text><rect x=\"52\" y=\"90\" width=\"236\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">objeto</text><text x=\"278\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">part-0.csv</text><text x=\"170\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">todas as colunas,</text><text x=\"170\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">todas as linhas,</text><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">num pedaço só</text><text x=\"170\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a menor coisa que o IAM nomeia</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Glue Data Catalog e Lake Formation</text><rect x=\"380\" y=\"32\" width=\"320\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">banco</text><text x=\"690\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">curated</text><rect x=\"396\" y=\"60\" width=\"288\" height=\"166\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tabela</text><text x=\"674\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders</text><rect x=\"406\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">order_id</text><rect x=\"474\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">customer_id</text><rect x=\"542\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">total_cents</text><rect x=\"610\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">phone</text><rect x=\"406\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-1</text><rect x=\"474\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-17</text><rect x=\"542\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">4590</text><rect x=\"610\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0017</text><rect x=\"406\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-2</text><rect x=\"474\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-03</text><rect x=\"542\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">12800</text><rect x=\"610\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0003</text><rect x=\"406\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-3</text><rect x=\"474\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-22</text><rect x=\"542\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">990</text><rect x=\"610\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0022</text><text x=\"540\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma coluna, uma linha, uma célula</text></svg>", "caption": "O telefone está dentro do objeto, então o IAM não consegue escondê-lo: quem lê o arquivo lê a coluna. O catálogo vê o mesmo arquivo como uma tabela, e é nesse nível que o Lake Formation concede.", "same": ["bucket"]}
```
