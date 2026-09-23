---
title: As cinco coisas que dão errado, antes de qualquer regra
version: 2
---

A aula 2 nomeou as anomalias antes de nomear uma forma normal, porque uma regra cuja graça você não
enxerga é uma regra que você não consegue aplicar. A mesma ordem funciona aqui. Estes são os cinco
jeitos pelos quais duas transações rodando ao mesmo tempo produzem uma resposta que nenhuma das duas
produziria sozinha.

Em cada linha do tempo, o tempo corre para baixo e as duas colunas são duas conexões.

## Leitura suja

```localised
T1                                    T2
BEGIN
UPDATE products SET price = 5
                                      BEGIN
                                      SELECT price → 5      ← lê trabalho não confirmado
ROLLBACK                              usa o 5 para alguma coisa
```

A T2 leu um valor que nunca existiu. A T1 mudou de ideia, e o 5 nunca foi verdade — mas a T2 já o
imprimiu, mandou por e-mail, ou escreveu em outro lugar.

É a que todo mundo sabe nomear, e é a que você tem menos chance de encontrar: é proibida por padrão
em todo lugar em que você vá trabalhar, e o PostgreSQL não consegue produzi-la de jeito nenhum.

## Leitura não repetível

```localised
T1                                    T2
BEGIN
SELECT price → 10
                                      UPDATE products SET price = 12
                                      COMMIT
SELECT price → 12                     ← mesma linha, mesma transação, outra resposta
```

Nada de sujo aconteceu: os dois valores estavam confirmados e eram verdadeiros quando lidos. Mas a
T1 fez a mesma pergunta duas vezes dentro de uma transação e recebeu duas respostas, então qualquer
conta que use as duas é uma conta sobre dois momentos diferentes.

Importa mais no formato que as pessoas não percebem estar escrevendo — um relatório que roda seis
consultas e soma os resultados. Entre a consulta dois e a cinco o mundo andou, e o total não fecha
com nada.

## Leitura fantasma

```localised
T1                                    T2
BEGIN
SELECT count(*) FROM orders
  WHERE total > 100     → 12
                                      INSERT INTO orders (total) VALUES (500)
                                      COMMIT
SELECT count(*) FROM orders
  WHERE total > 100     → 13          ← uma linha apareceu dentro da faixa
```

A parente próxima da anterior, e a diferença vale guardar: uma leitura não repetível é **uma linha
que você já tinha visto mudando**, e um fantasma é **uma linha que você não tinha visto chegando**.
Elas são separadas porque impedir a primeira é barato — segure as linhas que você tocou — e impedir
a segunda significa bloquear linhas que ainda não existem, o que é um problema mais difícil.

## Atualização perdida

```localised
T1                                    T2
BEGIN                                 BEGIN
SELECT stock → 10
                                      SELECT stock → 10
UPDATE SET stock = 9                  (os dois leram 10, os dois subtraem um)
                                      UPDATE SET stock = 9
COMMIT                                COMMIT
```

Dois itens vendidos. O estoque diz nove. Uma venda sumiu e nada em nenhuma das transações estava
errado sozinho — cada uma leu um valor verdadeiro e escreveu uma consequência correta dele.

**Esta é a anomalia que você vai encontrar de verdade**, e ela não está na lista de três do padrão
SQL, o que é parte de por que ela fica sem nome por tanto tempo. Vem do formato ler-modificar-
escrever, em que um valor é buscado para dentro da aplicação, mudado lá, e devolvido.

A primeira correção é parar de fazer aritmética fora do banco:

```sql
UPDATE products SET stock = stock - 1 WHERE id = 7;
```

Uma instrução, leitura e escrita no mesmo fôlego, e duas delas rodam uma depois da outra porque uma
linha fica bloqueada pela duração da instrução que a escreve. A segunda correção, para quando a
decisão é genuinamente tomada na aplicação, é a seção `locking`.

## Desvio de escrita

```localised
T1                                    T2
BEGIN                                 BEGIN
SELECT count(*) FROM doctors
  WHERE on_call → 2                   SELECT count(*) FROM doctors
                                        WHERE on_call → 2
(dois de plantão, então posso sair)   (dois de plantão, então posso sair)
UPDATE doctors SET on_call = false    UPDATE doctors SET on_call = false
  WHERE id = 1                          WHERE id = 2
COMMIT                                COMMIT
```

Ninguém de plantão. Cada transação conferiu a regra, cada conferência era verdadeira quando rodou, e
cada uma escreveu numa **linha diferente** — então elas nunca colidiram, e não houve atualização
perdida.

Esta é a mais sutil das cinco e tem seção própria, porque é a que sobrevive ao nível de isolamento
que a maioria supõe estar protegendo.

## As cinco, numa tabela

| anomalia | o que acontece |
|---|---|
| leitura suja | você vê trabalho que nunca foi confirmado |
| leitura não repetível | uma linha que você leu muda embaixo de você |
| leitura fantasma | uma linha aparece numa faixa que você já tinha contado |
| atualização perdida | dois ler-modificar-escrever, e um sobrescreve o outro |
| desvio de escrita | duas decisões corretas que estão erradas juntas |

Cada uma delas é uma possibilidade real até algo impedir, e o que impede cada uma é a próxima seção.
Guarde os nomes: as configurações são definidas em termos deles, então um nível que você não
conseguia ler vira uma frase que você consegue.
