---
title: Escolhendo onde cifrar
version: 1
---

Cada camada desta aula protege contra uma pessoa diferente, e nenhuma substitui outra. A decisão
não é qual usar, e sim a quais ameaças um conjunto de dados precisa sobreviver — e depois o custo de
cada camada, porque o custo é real.

| camada | protege contra | não protege contra | custa |
|---|---|---|---|
| **TLS, `verify-full`** | qualquer um no caminho da rede, e um servidor se passando pelo verdadeiro | qualquer um nas pontas | um certificado para emitir e renovar; um cliente configurado para conferi-lo |
| **certificados de cliente** | uma senha de programa roubada | uma chave privada roubada | uma CA, e renovação numa cadência |
| **criptografia de volume** | um disco, um snapshot ou um servidor que sai do seu controle | todo leitor com login; toda cópia feita pelo banco | quase nada em execução; uma chave para gerir |
| **backups e exportações cifrados** | a cópia que viaja mais longe e vive mais | leitores do banco em execução | uma chave que precisa durar tanto quanto o backup |
| **criptografia de coluna no banco** | cópias do dado sem a chave | o banco, os administradores, os logs | a chave passa pelo servidor; nada de índice nem busca no texto claro |
| **criptografia na aplicação** | o banco e todo mundo com acesso a ele | a aplicação e quem a controla | consultas não filtram nem fazem join no valor; a aplicação precisa de um serviço de chaves |

Três regras saem da tabela.

**Cifre em trânsito e em repouso em toda parte, por padrão.** As duas são baratas, as duas protegem
contra ameaças que ninguém consegue descartar, e o custo de errar é uma notificação de incidente
(aula 7). Não existe conjunto de dados para o qual "ninguém nunca vai roubar o disco" seja uma
decisão de projeto.

**Cifre valores individuais só onde a ameaça é quem está dentro.** Criptografia de uma coluna na
aplicação significa que o banco não consegue buscar, ordenar, fazer join nem agregar essa coluna —
um CPF cifrado assim deixa de achar um cliente pelo CPF sem uma segunda coluna, com chave,
construída para isso (os tokens da aula 5 são essa coluna). É certo para os poucos valores cuja
exposição a um administrador de banco já seria um incidente, e errado como padrão.

**Toda camada termina numa chave, e a chave decide contra quem a camada realmente protege.** Um
volume cifrado com uma chave guardada no mesmo disco não protege de ninguém; um backup cifrado com
uma chave no mesmo bucket não protege de ninguém; uma coluna cifrada com a chave na consulta não
protege de ninguém que leia um log. Onde as chaves moram, quem pode usá-las e como são trocadas é a
aula 4 inteira.
