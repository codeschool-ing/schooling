---
title: ALTER TABLE, e o que ele custa
version: 1
---

Criar uma tabela é fácil porque nada depende dela ainda. Mudar uma é o trabalho.

```sql
ALTER TABLE invoices ADD COLUMN notes text;
ALTER TABLE invoices DROP COLUMN notes;
ALTER TABLE invoices RENAME COLUMN notes TO remarks;
ALTER TABLE invoices ALTER COLUMN total TYPE numeric(14,2);
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
ALTER TABLE invoices ADD CONSTRAINT invoices_total_not_negative CHECK (total >= 0);
```

Cada um deles é uma linha. Não são um custo.

## Três velocidades, e saber qual é qual é a habilidade

**Instantâneo — só catálogo.** A tabela não é lida, nenhuma linha se move, e termina em
milissegundos, tenha ela dez linhas ou dez bilhões:

- `ADD COLUMN` sem default, ou com default constante (desde o PostgreSQL 11)
- `DROP COLUMN` — o dado não é removido, a coluna é marcada como ida e o espaço é recuperado depois
  pelo vacuum
- `RENAME` qualquer coisa
- `SET DEFAULT`, `DROP DEFAULT`
- alargar um `varchar(n)` para um `n` maior, ou para `text`

**Uma varredura completa — toda linha é lida, nenhuma é reescrita.** Proporcional à tabela:

- `ADD CONSTRAINT … CHECK` — toda linha existente tem que satisfazer
- `SET NOT NULL` — toda linha existente tem que ser não nula
- `ADD FOREIGN KEY` — todo valor existente tem que existir do outro lado

**Uma reescrita completa — toda linha é escrita de novo**, e a tabela precisa de aproximadamente o
dobro do tamanho em disco livre enquanto isso acontece:

- `ALTER COLUMN … TYPE` na maioria dos casos, incluindo `integer` para `bigint`
- `ADD COLUMN` com default **volátil**, como `DEFAULT gen_random_uuid()`, porque cada linha precisa de
  um valor diferente

## O lock é o que importa

Velocidade não é bem a questão. **`ALTER TABLE` pega um lock `ACCESS EXCLUSIVE`**, que bloqueia tudo
— toda leitura, toda escrita, de todo mundo — enquanto roda.

Numa tabela pequena isso são alguns milissegundos e ninguém nota. Numa tabela de cem milhões de
linhas uma reescrita são minutos, e por esses minutos **a aplicação está fora do ar**, não lenta.

E existe uma falha pior, que é a que de fato causa quedas:

> **`ALTER TABLE` espera pelo lock, e tudo que chega atrás dele espera também.**

Um `SELECT` demorado basta. Seu `ALTER` entra na fila atrás dele, e toda consulta que chega depois
entra na fila atrás do seu `ALTER` — inclusive as rápidas, que estariam bem. Um comando que levaria
dois milissegundos derruba o site porque foi paciente.

A mitigação é recusar-se a esperar:

```sql
SET lock_timeout = '3s';
ALTER TABLE invoices ADD COLUMN notes text;
```

Agora ou ele pega o lock rápido ou desiste, e desistir é o resultado que você quer. Você tenta de novo
quando a consulta longa terminar, e nada entrou na sua fila enquanto isso.

## `ADD COLUMN` com default não é mais o que era

Vale saber porque o conselho antigo ainda é repetido em todo lugar.

Antes do PostgreSQL 11, `ADD COLUMN … DEFAULT 'x'` reescrevia a tabela inteira, então o conselho
padrão era: acrescente aceitando nulo, preencha em lotes, depois defina o default. **Desde a 11, um
default constante é guardado no catálogo e as linhas existentes são informadas conforme são lidas** —
então é instantâneo.

Um default **volátil** ainda reescreve, porque cada linha genuinamente precisa do próprio valor. É
essa a linha: `DEFAULT 'draft'` é instantâneo, `DEFAULT gen_random_uuid()` é reescrita.

## Derrubar, e o que vai junto

```sql
DROP TABLE invoices;                    -- recusado se algo a referencia
DROP TABLE invoices CASCADE;            -- derruba as restrições que referenciam também
```

`CASCADE` aqui **não** apaga linhas em outras tabelas. Ele derruba as *restrições* que apontam para
esta tabela, deixando silenciosamente aquelas tabelas com colunas que não referenciam nada. Isso é
pior do que parece: o dado sobrevive, a regra não, e ninguém é avisado.

E os dois jeitos de esvaziar uma tabela não são intercambiáveis:

| | |
|---|---|
| `DELETE FROM invoices` | linha a linha, dispara gatilhos, pode ser desfeito, deixa linhas mortas para o vacuum |
| `TRUNCATE invoices` | reinicia a tabela, muito rápido em qualquer tamanho, não dispara gatilhos de linha, e continua transacional no PostgreSQL |

O `TRUNCATE` ser transacional é específico do PostgreSQL e genuinamente útil — você pode dar `BEGIN`,
truncar, carregar e `COMMIT`, e os leitores veem o conteúdo antigo até o commit. No MySQL ele comita
implicitamente e não há volta.

## A regra para um sistema no ar

> **Antes de rodar qualquer `ALTER TABLE` numa tabela que importa, saiba qual das três velocidades
> ele é, e defina um `lock_timeout`.**

Qual mudança é qual não é coisa para deduzir sob pressão — é uma tabela que você consulta, e é a
acima. A próxima seção é o que fazer quando a mudança de que você precisa está na terceira categoria
e a tabela é grande demais para parar.
