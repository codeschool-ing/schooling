---
title: A aplicação tem um endereço, não um primário
version: 1
---

Todo failover até aqui terminou com uma frase do tipo "o novo primário está na 5434". A aplicação não
leu essa frase. Ela tem uma string de conexão com um endereço dentro, e depois do failover esse
endereço é um servidor morto, uma réplica só de leitura ou, o pior caso, um primário antigo que voltou.
A lição 15 deixou isso para cá; o Patroni escolheu um novo líder na lição 16 e não contou para ninguém
além do etcd.

Há quatro lugares para guardar a informação de onde está o primário, e cada um muda uma coisa
diferente quando ele muda:

| abordagem | o que muda num failover | o que a aplicação faz |
|---|---|---|
| **no cliente**: vários hosts na string de conexão | nada | tenta cada host e fica com o que aceita escrita |
| **proxy**: HAProxy ou parecido, na frente | o backend que o proxy escolhe | conecta num endereço fixo |
| **IP virtual**: um endereço que passa de uma máquina para outra | o próprio endereço | conecta num endereço fixo |
| **DNS**: um nome que passa a apontar para outro lugar | um registro DNS | conecta num nome, e precisa resolvê-lo de novo |

As quatro têm em comum a parte que mais importa: **as conexões abertas no momento de um failover
caem**, e nenhum truque de endereço conserta isso. O que a aplicação faz em seguida, reconectar e
tentar de novo ou mostrar um erro, é código da aplicação, e é o assunto da última seção.

Esta lição monta as duas primeiras sobre o cluster da lição 16, três nós Patroni nas portas 5441 a
5443 com o `pg1` como líder, e explica as outras duas, que precisam de mais de uma máquina para serem
mostradas com honestidade.
