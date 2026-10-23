---
title: Quando o GORM é a ferramenta certa
version: 1
---

As seções anteriores poderiam ser lidas como um argumento contra o GORM, e essa seria a lição errada.
**Cada armadilha era uma regra, aplicada com coerência**, e uma equipe que conhece as regras usa o GORM
com produtividade por anos. A pergunta é quais serviços compensam o esforço de aprendê-las.

## Onde ele se encaixa

- **Muitas tabelas, quase só criar, ler, atualizar e apagar.** Uma ferramenta interna ou um back end
  administrativo com trinta tabelas e um formulário para cada é exatamente aquilo para que um ORM foi
  inventado. O SQL dessas operações é tedioso, e o GORM o escreve corretamente.
- **Uma equipe vinda de Rails, Django ou Hibernate**, para quem modelos e associações são o jeito
  natural de pensar em dados.
- **Protótipos**, onde o `AutoMigrate` transformando uma struct em tabela numa chamada vale mais que um
  histórico de migrações de que ninguém precisa ainda.
- **Vários bancos**, se um produto precisa mesmo rodar em PostgreSQL e em MySQL, e o SQL precisa
  continuar portável.

## Onde ele atrapalha

- **Quando as consultas são o produto.** Relatórios, agregações, tudo que tem `GROUP BY` ou função de
  janela: a soma da seção 06 foi um `SELECT` em SQL e desajeitada pelo ORM.
- **Quando o desempenho é vigiado consulta por consulta.** Todo comando é gerado, então achar o lento
  quer dizer ler o log em vez do código, e o N+1 está a um laço de distância.
- **Quando as regras do próprio banco importam.** A tabela da seção 03 ficou sem a verificação de que
  `sold` fica dentro de `seats`; o boxoffice depende dessa regra mais do que de qualquer linha de Go.
- **Quando outros programas compartilham o banco.** O soft delete e as outras convenções do GORM moram
  no GORM.

## E o boxoffice

O boxoffice continua no código pgx da aula 6. Ele tem uma tabela até agora, uma segunda chegando na
aula 9, e a operação mais importante dele é um `UPDATE` escrito com cuidado cujo `WHERE` é o ponto
todo. **Um ORM esconderia justamente a linha que mais importa.** Isso não é um veredito sobre o GORM;
é o formato deste serviço em particular.

Existe um terceiro caminho, entre escrever cada scan à mão e deixar o ORM escrever o SQL: escrever o
SQL você mesmo e deixar uma ferramenta escrever o Go. Essa é a aula 8.
