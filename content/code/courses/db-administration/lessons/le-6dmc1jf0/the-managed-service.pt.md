---
title: O que um serviço gerenciado tira, e o que deixa
version: 1
---

O serviço gerenciado é o terceiro jeito, e é onde muitos dos servidores de que você vai cuidar por
dinheiro já moram. **Nada nesta seção foi rodado para o curso**: ela descreve o que os grandes
provedores documentam, e os detalhes mudam com os produtos deles. O formato não muda.

## O que você recebe

Você cria uma **instância** num console web ou com uma chamada de API: a versão maior, o tamanho da
máquina, o tamanho do disco, uma região e uma senha. Alguns minutos depois você tem um nome de host
e uma porta. Conecta nele com o mesmo `psql` que acabou de instalar, pela rede e com senha, e dali
em diante SQL é SQL.

## O que não é seu

**A máquina.** Não há shell. Você não lista o diretório de dados, não lê o `postgresql.conf` nem
olha os processos do servidor. A lição 4 e a maior parte das lições 5, 9 e 19 não têm equivalente
lá.

**O superusuário.** O provedor fica com ele. Seu primeiro papel tem a maioria dos poderes
administrativos — no Amazon RDS ele é membro de um papel chamado `rds_superuser`, no Azure de
`azure_pg_admin` —, mas não todos. Tudo o que deixaria você chegar ao sistema operacional pelo
banco é recusado: ler arquivos do servidor, carregar bibliotecas arbitrárias, algumas extensões.

**O arquivo de configuração.** Ele vira um **parameter group** ou uma lista de flags do servidor no
console. Alguns parâmetros podem ser mudados, outros são fixos, e os de memória costumam vir
escritos como fórmulas sobre o tamanho da máquina que você escolheu. Uma mudança que precisa de
reinício é aplicada quando o provedor reinicia a instância, muitas vezes numa janela de manutenção
combinada de antemão.

**O log.** Ele existe, e você o lê pelo console do provedor ou baixa. O que ele registra continua
sendo decidido pelos parâmetros da lição 19.

## O que continua seu

Tudo o que fica **dentro** do banco: os papéis e seus grants, os privilégios padrão, o esquema e
como ele muda enquanto a aplicação roda, se o autovacuum está dando conta de uma tabela em
particular, se as estatísticas que o planejador usa estão atuais. Um serviço gerenciado roda o
autovacuum; ele não sabe que a sua tabela `events` recebe quarenta milhões de linhas por dia e
precisa de outros limiares. As lições 11 a 17 e a 22 são trabalho seu onde quer que o servidor
more.

Também são suas as decisões que o console só executa: qual versão maior, quando passar para a
próxima, que tamanho a máquina precisa ter. Um provedor faz o upgrade da sua versão menor por você.
Ele não lê as notas da próxima versão maior para avisar quais das suas consultas vão mudar de
plano.

## Por que o curso não usa um

Porque um serviço gerenciado esconde justamente as partes do servidor que este curso explica. O
melhor jeito de entender o que faz o botão de "storage autoscaling" ou de "point-in-time restore"
de um provedor é ter montado, uma vez, a coisa que ele automatiza, numa máquina em que dava para
ver. Depois deste curso, um serviço gerenciado é um conjunto de decisões que alguém tomou por você,
e você consegue lê-las.
