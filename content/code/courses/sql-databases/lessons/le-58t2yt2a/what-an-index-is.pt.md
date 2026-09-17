---
title: O que um índice de fato é
version: 1
---

```sql
CREATE INDEX ON customers (email);
```

Essa instrução faz algo físico. Ela constrói **uma segunda cópia da coluna `email`, mantida em
ordem, com um ponteiro ao lado de cada valor para a linha de onde ele veio.**

Não é uma configuração. Não é uma dica para o planejador. É uma estrutura, em disco, que precisa ser
escrita e mantida em dia, e é por isso que todo o resto desta aula é uma troca e não uma melhoria de
graça.

## Por que estar em ordem é o truque inteiro

Sem ela, achar `ana@example.com` em um milhão de linhas significa ler um milhão de linhas. Não há
atalho, porque dado fora de ordem não tem atalho — a linha que você quer pode estar em qualquer
lugar.

Com ela, o banco abre a cópia ordenada no meio, compara, e joga metade fora. Depois metade daquilo.
Vinte desses passos chegam a uma linha em um milhão, e trinta chegam a uma em um bilhão.

```
1 000 linhas          ~10 passos
1 000 000 linhas      ~20 passos
1 000 000 000 linhas  ~30 passos
```

Olhe essa tabela por um segundo, porque ela explica o formato de tudo o que vem depois: **mil vezes
mais dado custa dez passos a mais.** Uma varredura da mesma tabela custa mil vezes mais trabalho.
Essa distância é o que um índice compra, e é por isso que o ganho cresce com a tabela em vez de
ficar igual.

## A árvore B, rapidamente

A cópia ordenada não é uma lista plana — uma lista plana teria que ser reescrita toda vez que uma
linha fosse inserida no meio. É uma **árvore B**: uma árvore rasa de blocos, em que cada bloco
guarda uma faixa de valores e ponteiros para os blocos de baixo.

```
                  [ f   m   s ]
                 /    |    |    \
        [a..e] [f..l] [m..r] [s..z]
```

Três ou quatro níveis bastam para centenas de milhões de linhas, e cada nível é a leitura de um
bloco. Uma inserção vai para o bloco certo, e só divide um bloco quando ele está cheio — então a
árvore se mantém equilibrada sem ser reconstruída.

É este o tipo de índice padrão em todos os bancos deste curso, e quando alguém diz "um índice" sem
qualificar, é dele que está falando.

## O que ele consegue responder

Como a cópia está em ordem, ela serve a mais de um formato de pergunta:

```sql
WHERE email = 'ana@example.com'      -- achar um valor
WHERE email > 'm'                    -- achar uma posição e ler para a frente
WHERE created_at BETWEEN … AND …     -- achar o começo, ler até o fim
ORDER BY email                        -- ler em ordem, sem precisar ordenar
WHERE email LIKE 'ana%'               -- um prefixo é uma faixa: de 'ana' até 'anb'
```

Este último vale guardar. `LIKE 'ana%'` é uma varredura de faixa e é rápido; `LIKE '%ana'` não é,
porque a cópia está ordenada pelo começo da string e nada sobre o fim dela está em ordem. É o mesmo
fato, e a seção depois da próxima é uma lista de coisas que são esse mesmo fato disfarçado.

## E o que custa seguir o ponteiro

Uma entrada de índice guarda o valor e um ponteiro, então responder a `SELECT * FROM customers WHERE
email = …` são dois passos: achar a entrada, e depois buscar a linha para a qual ela aponta. Essa
segunda busca é uma leitura aleatória em outro lugar do disco, e numa consulta que devolve muitas
linhas é a parte cara.

O que prepara duas coisas a que esta aula volta. **Uma consulta que só quer as colunas indexadas
pode pular o segundo passo por completo** — isso é o índice de cobertura. E **uma consulta que
teria que seguir o ponteiro para metade da tabela sai melhor lendo a tabela**, que é a razão honesta
de um planejador ignorar um índice perfeitamente bom.
