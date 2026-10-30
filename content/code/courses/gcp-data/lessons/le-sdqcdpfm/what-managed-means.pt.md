---
title: O que "gerenciado" tira das suas mãos, e o que deixa
version: 1
---

**O Cloud SQL opera a máquina e a manutenção do motor. Ele não opera o seu banco de dados.** A crença
que mete uma empresa em apuros é a de que, indo para um banco gerenciado, ninguém mais precisa
entender de bancos de dados. O que passa para o Google é tudo que fica debaixo do motor e uma lista
fixa de tarefas em volta dele. Tudo que acontece dentro do motor continua exatamente onde estava: com
quem escreveu o esquema e as consultas.

O banco de pedidos da Quitanda hoje é um PostgreSQL num servidor num armário do escritório. Alguém
aplica as atualizações do sistema operacional quando lembra, um cron despeja o banco num disco ao lado
toda noite, e se o disco do servidor morre, a loja fecha até comprarem outro e restaurarem o dump. Esse
é o trabalho que o Cloud SQL assume, e é um trabalho de verdade:

| o Cloud SQL assume | continua sendo seu |
|---|---|
| a máquina e o disco, e trocá-los quando falham | o esquema: tabelas, chaves, tipos, restrições |
| o sistema operacional, suas atualizações e seus patches de segurança | as consultas, e as lentas |
| as versões menores do motor, aplicadas numa janela semanal | os índices, e os que faltam |
| backups diários automáticos e o log para recuperação a um ponto no tempo | as flags: memória, log, timeouts |
| um standby em outra zona, quando a instância é regional | o número de conexões, e quem as abre |
| métricas no Cloud Monitoring: CPU, memória, disco, conexões | a conta |

**A coluna da esquerda é o trabalho que é igual para todo banco**, e é por isso que um provedor pode
fazê-lo uma vez para um milhão de clientes. A coluna da direita é o trabalho que é particular do seu,
e é por isso que nenhum provedor pode. O Cloud Monitoring vai dizer que a CPU está em 95% desde
segunda-feira. Não vai dizer que um relatório que alguém criou na segunda lê a tabela `orders`
inteira a cada minuto, e não vai criar o índice. As aulas 9 e 10 de `sql-databases` são esse
trabalho, e ele é o mesmo no Cloud SQL e no servidor do armário.

## O que você abre mão em troca

**Não há shell na máquina.** Você nunca entra no sistema operacional de uma instância do Cloud SQL,
não instala pacote nela e não lê arquivo do disco dela; os logs saem pelo Cloud Logging. **O
superusuário do motor também não é seu.** No Cloud SQL para PostgreSQL, o usuário `postgres` com que a
instância é criada é membro de um papel chamado `cloudsqlsuperuser`, e a documentação do Google é
explícita: isso não é o atributo `SUPERUSER` do PostgreSQL. Ele cria bancos, papéis e as extensões da
lista suportada do Cloud SQL, e não escreve arquivo no servidor, não carrega extensão fora da lista e
não roda `ALTER SYSTEM`. A seção sobre flags mostra, num motor local, como essa última recusa aparece e
o que a substitui.

**A janela de manutenção é uma promessa de interromper você.** Cada instância tem uma hora semanal em
que o Google pode aplicar uma atualização, e uma atualização reinicia o motor. Você escolhe o dia e a
hora, pode declarar um período de bloqueio de até 90 dias em volta de uma temporada movimentada, e não
pode ter uma instância que nunca reinicia. O Google documenta a interrupção como curta, e muito mais
curta na edição Enterprise Plus da próxima seção; ainda assim é um momento em que conexões caem, e uma
aplicação que não reconecta descobre isso nessa hora. Uma atualização de versão **principal**, do
PostgreSQL 16 para o 17, não é aplicada por você: você a inicia, depois de testar, porque uma versão
principal pode mudar o comportamento de uma consulta.

## A linha, num lugar só

**Gerenciado move o risco operacional, não o risco de projeto.** Um disco que falha, um patch que
ninguém aplicou, um backup que ninguém testou: eram riscos da Quitanda e passam a ser do Google. Uma
tabela projetada em volta da chave errada, uma consulta que lê um milhão de linhas para devolver dez,
um pool que abre duas mil conexões numa instância dimensionada para quatrocentas: eram da Quitanda e
continuam sendo. O Cloud SQL torna a última mais provável, porque uma instância maior está a um comando
de distância, e uma instância maior é o jeito caro de esconder um índice que falta.

**Nada nesta aula cria uma instância do Cloud SQL.** Não existe emulador para ele, e nada no notebook
responde a `gcloud sql`. O que a aula faz em vez disso é rodar o motor que fica debaixo dele, o
PostgreSQL 16, na sua própria máquina, onde toda configuração que o Cloud SQL chama de flag pode ser
vista e mudada. O resto ela lê da documentação do Google e da referência da própria linha de
comando, que vem dentro do `gcloud` e não precisa de rede.
