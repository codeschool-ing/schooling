---
title: O que "gerenciado" tira das suas mãos, e o que deixa
version: 1
---

**O RDS cuida da máquina e da manutenção de rotina do engine. Ele não cuida do seu banco de dados.** A
crença comum, a que mete uma empresa em apuros, é que passar para um banco gerenciado significa que
ninguém mais precisa entender de bancos. O que vai para a AWS é tudo o que fica por baixo do engine e
uma lista fixa de tarefas em volta dele. Tudo o que acontece dentro do engine fica exatamente onde
estava: com quem escreveu o esquema e as consultas.

O banco de pedidos da Quitanda hoje é um PostgreSQL num servidor no armário do escritório. Alguém
aplica as atualizações do sistema operacional quando lembra, um cron faz um dump do banco num disco ao
lado toda noite, e se o disco do servidor morre a loja fica fechada até alguém comprar outro e restaurar
o dump. Esse é o trabalho que o RDS assume, e é um trabalho de verdade:

| o RDS assume | continua seu |
|---|---|
| o hardware, e a troca dele quando falha | o esquema: tabelas, chaves, tipos, restrições |
| o sistema operacional, as atualizações e os patches de segurança | as consultas, e as lentas |
| instalar o engine, e as atualizações de versão secundária numa janela semanal | os índices, e os que faltam |
| backups automáticos, guardados por até 35 dias | os parâmetros: memória, log, timeouts |
| failover para um standby em outra zona, quando você paga por um | o número de conexões, e quem as abre |
| métricas: CPU, memória, armazenamento, conexões | a conta |

**A coluna da esquerda é o trabalho que é igual para todo banco**, e é por isso que um provedor pode
fazê-lo uma vez para um milhão de clientes. A da direita é o trabalho que é particular do seu, e é por
isso que nenhum provedor pode. O RDS vai lhe dizer, pelas métricas, que a CPU está em 95% desde
segunda-feira. Ele não vai dizer que um relatório que alguém criou na segunda lê a tabela `orders`
inteira a cada minuto, e não vai criar o índice. As lições 9 e 10 do `sql-databases` são esse trabalho,
e ele é o mesmo no RDS e no servidor do armário.

## O que você entrega em troca

**Não há shell na máquina.** Você nunca entra no sistema operacional de uma instância RDS, não pode
instalar um pacote nela e não pode ler um arquivo do disco dela; os logs saem pela API. O superusuário
do próprio engine também não é seu. No PostgreSQL, o usuário mestre é membro de uma role chamada
`rds_superuser`, que pode quase tudo o que um administrador faz dentro do banco e nada fora dele: nenhuma
extensão que não esteja na lista do RDS, nenhum arquivo gravado no servidor. A maioria das aplicações
nunca percebe. Uma aplicação que dependia de uma extensão própria, compilada no servidor antigo, percebe
no primeiro dia.

**A janela de manutenção é uma promessa de interrupção.** Cada instância tem meia hora semanal em que o
RDS pode aplicar um patch pendente, e alguns patches reiniciam o engine. Você escolhe quando a janela
cai e pode ver o que está pendente; não pode ter uma instância que nunca é reiniciada. Uma atualização
de versão principal, de PostgreSQL 16 para 17, nunca é aplicada sem você pedir enquanto a versão tem suporte.
Você a começa, depois de testar, porque uma versão principal pode mudar o comportamento de uma consulta.

## A linha, num lugar só

**Gerenciado transfere o risco operacional, não o risco de projeto.** Um disco que falha, um patch que
ninguém aplicou, um backup que ninguém testou: esses eram riscos da Quitanda e passam a ser da AWS. Uma
tabela projetada em torno da chave errada, uma consulta que lê um milhão de linhas para devolver dez, um
pool que abre duas mil conexões numa instância dimensionada para quatrocentas: esses eram da Quitanda e
continuam da Quitanda, e o RDS torna o último mais provável, porque criar uma instância maior é um
comando, e uma instância maior é o jeito caro de esconder um índice que falta.
