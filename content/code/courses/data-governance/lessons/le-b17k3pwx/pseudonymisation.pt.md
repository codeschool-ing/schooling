---
title: Pseudônimos para análise
version: 1
---

Os analistas da Ipê querem estudar comportamento de compra: com que frequência um cliente volta, como
uma cesta muda ao longo de um ano. Eles precisam saber que dois pedidos são do **mesmo** cliente, e
nunca **de qual** cliente. Esse é o trabalho de um **pseudônimo**: um código que substitui a
identidade, de forma consistente, para que os registros ainda se juntem.

O primeiro rascunho é o que todo mundo escreve:

```sql
-- A FIRST DRAFT of the analysts' export: the customer replaced by an md5.
SET ROLE ipe_owner;
COPY (
  SELECT md5(o.customer_id::text) AS customer_ref,
         date_trunc('month', o.ordered_at)::date AS month,
         o.total_cents
  FROM sales.orders o WHERE o.customer_id IS NOT NULL
  ORDER BY o.order_id LIMIT 3
) TO STDOUT WITH (FORMAT csv, HEADER true);
```

```
ana@lab:~/gov$ psql -X -q -f naive.sql
customer_ref,month,total_cents
c81e728d9d4c2f636f067f89cc14862c,2026-01-01,5990
c81e728d9d4c2f636f067f89cc14862c,2021-07-01,690
eccbc87e4b5ce2fe28308fd9f2a7baf3,2023-09-01,7970
ana@lab:~/gov$ psql -X -q -Atc "SELECT customer_id FROM generate_series(1, 6012) AS customer_id WHERE md5(customer_id::text) = '$(psql -X -q -At -f naive.sql | sed -n 2p | cut -d, -f1)'"
2
```

A exportação troca `customer_id` pelo MD5 dele e parece opaca — 32 caracteres hexadecimais. O
segundo comando é o que qualquer um com a exportação faz em menos de um segundo: passar pelo hash
todo id possível, de 1 a 6.012, e ver qual bate. **Cliente 2.** Um hash sem chave de um valor de um
intervalo pequeno e conhecido não é um pseudônimo, é o valor escrito de outro jeito. O mesmo vale
para o hash de um CPF, de um e-mail ou de um telefone: o espaço é grande para uma pessoa e pequeno
para um computador.

## Um pseudônimo com chave

O conserto é o que o índice do CPF usou: um HMAC com chave, uma chave que os analistas não têm. Uma
chave separada, porque o propósito é separado — um pseudônimo de análise nunca deve se juntar ao
índice do suporte:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-analytics-ref
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791344086]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-analytics-ref
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-analytics-ref input=$(printf '2' | base64); echo
vault:v1:5Vv5pnFMJl2xg+behW50khtDjpaUnl6g+cJbyySjvL4=
```

O mesmo cliente 2 agora vira um texto que ninguém calcula sem `ipe-analytics-ref`, que nunca sai do
OpenBao. Uma exportação feita com ela mantém todo join de que um analista precisa e não lhe dá
caminho de volta.

## O que um pseudônimo ainda é

**Dado pseudonimizado é dado pessoal.** A LGPD define a pseudonimização, no artigo sobre estudos em
saúde pública (art. 13, §4º), como o tratamento depois do qual um dado não pode mais ser associado a
uma pessoa *senão pelo uso de informação adicional mantida separadamente pelo controlador* — e a Ipê
tem essa informação: a chave, e a tabela de clientes. A GDPR diz o mesmo com outras palavras
(aula 8).

Então uma exportação pseudonimizada reduz o risco e mantém toda obrigação:

- o acesso dos analistas a ela continua sendo acesso a dado pessoal, decidido pelas regras da
  aula 2;
- o pedido de um cliente de ter seus dados eliminados (aula 7) alcança a exportação também;
- e **o pseudônimo não esconde o que viaja com ele.** Uma exportação com um pseudônimo, uma cidade,
  uma faixa etária e todas as compras é um perfil; se uma dessas compras for incomum o bastante, o
  perfil é uma pessoa. A próxima seção mede quão depressa isso acontece.
