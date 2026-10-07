---
title: O que uma marca d'água não vê
version: 1
---

A lição 4 terminou com três buracos na extração incremental, cada um achado no laboratório:

- **uma exclusão não deixa nada para trás**, então nenhum `updated_at` a encontra — o apagamento do
  cliente 1880;
- **uma linha confirmada tarde se esconde abaixo da marca d'água** — o pedido do caixa lento;
- **uma atualização que a origem esquece de marcar com horário é invisível** para sempre.

Há um quarto que o laboratório não encenou porque é ainda mais discreto. **Uma marca d'água vê cada
linha como ela está agora, não o que aconteceu com ela.** Um pedido feito às 10:00 e estornado às
15:00 é extraído naquela noite uma vez, como estornado. O warehouse nunca fica sabendo que ele um dia
esteve concluído, e uma pergunta como "quantas vendas foram estornadas no mesmo dia?" não tem
resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-two-views\" aria-label=\"Um pedido durante um dia. Às 10:00 ele é inserido como concluído; às 15:00 é atualizado para estornado. Uma extração por marca d'água à noite lê a tabela uma vez e vê uma linha, estornada. A captura de mudanças lê o log e vê duas mudanças, a inserção e a atualização, na ordem em que foram confirmadas.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um pedido, um dia</text><path d=\"M40.0 60.0 L680.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"200.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10:00 INSERT concluído</text><circle cx=\"420.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"420.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15:00 UPDATE estornado</text><path d=\"M620.0 48.0 L620.0 72.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"620.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">noite</text><rect x=\"40.0\" y=\"130.0\" width=\"300.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">marca d'água: lê a tabela</text><rect x=\"80.0\" y=\"176.0\" width=\"220.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma linha: estornado</text><rect x=\"380.0\" y=\"130.0\" width=\"300.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">captura de mudanças: lê o log</text><rect x=\"400.0\" y=\"170.0\" width=\"125.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><rect x=\"535.0\" y=\"170.0\" width=\"125.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE</text><text x=\"530.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">duas mudanças, em ordem de confirmação</text></svg>", "caption": "Uma tabela guarda o presente. O log guarda o que aconteceu, que é o único lugar onde a venda concluída ainda existe."}
```

Os quatro têm a mesma causa: o pipeline está perguntando às *tabelas*, e uma tabela só guarda o
presente. **A captura de dados de mudança pede ao banco o seu histórico** — cada inserção,
atualização e exclusão, na ordem em que foram confirmadas — e o banco vem guardando esse histórico o
tempo todo, pelos seus próprios motivos.

## Onde o histórico já está

Antes de mudar uma única página de uma tabela, o PostgreSQL escreve o que vai fazer no **log de
escrita antecipada**, o WAL. É assim que ele sobrevive a uma queda: depois de uma falta de energia ele
reproduz o log desde o último checkpoint e volta para onde estava. As réplicas são mantidas em dia do
mesmo jeito, recebendo o log e reproduzindo-o.

O WAL é escrito para o banco, nos termos do banco — páginas, deslocamentos, bytes — e não serve
diretamente a um pipeline. A **decodificação lógica** é o recurso que o transforma de volta em
linhas: *esta transação inseriu este pedido, com estes valores*. Um pipeline de captura de mudanças é
um leitor desse fluxo, e ele recebe cada mudança, exclusões incluídas, em ordem de confirmação, sem
nenhuma consulta às tabelas.

O resto desta lição monta um à mão contra a loja, só com o PostgreSQL e cinquenta linhas de Python,
e depois diz o que as ferramentas de produção para isso — o Debezium e o Kafka Connect entre elas —
acrescentam por cima.
