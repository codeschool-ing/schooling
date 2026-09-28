---
title: Listando os caminhos infelizes
version: 1
---

Antes de tratar erros, liste-os. Para cada ação que um usuário pode fazer, pergunte o que pode dar errado, e
decida qual deve ser a resposta. O loanbook tem duas ações, e esta é a lista inteira:

| o que acontece | erro de quem | a resposta |
|---|---|---|
| um endereço que não existe | do cliente | 404, *Nothing lives at …* |
| um corpo que não é JSON | do cliente | 400, *The body is not JSON.* |
| um número de item que não existe | do cliente | 404, *There is no item 9.* |
| emprestar sem nome, ou só com espaços | do usuário | 400, *Say who is borrowing it.* |
| emprestar um item que já está fora | de ninguém: é a regra | 409, *Projector 2 is already lent to…* |
| devolver um item que não está fora | de ninguém: é a regra | 409, *… is not out, so it cannot come back.* |
| o servidor está fora do ar | não é do usuário | a página diz isso, e o que fazer |
| algo que ninguém esperava | nosso: é um bug | uma linha no log do servidor |

A coluna do meio decide o resto. **Um erro do cliente ou do usuário recebe uma frase que diz como
corrigir.** **Uma regra recebe uma frase que diz qual regra, com os fatos**: não *conflito*, mas com quem
está o projetor e até quando. **Um erro nosso não recebe frase nenhuma** na resposta; vai para o log, onde a
pessoa que pode corrigir vai olhar.

A lista é curta porque o loanbook é pequeno. A sua será mais longa, e escrevê-la é o passo que encontra os
caminhos. Cada uma dessas linhas foi uma decisão; nenhuma foi descoberta por um usuário.
