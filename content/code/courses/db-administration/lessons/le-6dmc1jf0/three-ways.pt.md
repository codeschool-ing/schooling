---
title: Um pacote, um contêiner e um serviço gerenciado
version: 1
---

Seja qual for o jeito de instalar, **o servidor é o mesmo programa**: um processo chamado
`postgres`, um diretório de arquivos de dados, um arquivo de configuração e um log. O que muda
entre os três jeitos de ter um é quem é dono de cada uma dessas quatro coisas, e isso decide o que
você consegue fazer quando algo dá errado.

## Um pacote

Um **pacote** é o servidor compilado pelo distribuidor do seu sistema operacional e instalado pelo
gerenciador de pacotes dele. No Ubuntu é `apt install postgresql`, e o que chega é um programa em
`/usr/lib/postgresql/16/bin`, um serviço que o systemd sobe no boot, um diretório de dados em
`/var/lib/postgresql` e um arquivo de configuração em `/etc/postgresql`. As correções de segurança
chegam junto com as demais atualizações do sistema.

As quatro coisas são suas. Você lê qualquer arquivo, muda qualquer ajuste, reinicia o serviço,
enche o disco e vê o que acontece. Ninguém mais vai perceber uma falha antes de você, e ninguém
mais vai consertá-la.

## Um contêiner

Um **contêiner** é o mesmo programa empacotado numa imagem junto com as bibliotecas de que
precisa, rodado pelo Docker ou pelo Podman como um processo isolado. A imagem oficial
`postgres:16` sobe um servidor com um comando, e jogá-lo fora é mais um.

As quatro coisas continuam suas, mas moram em outro lugar. O diretório de dados é um **volume**
que o runtime de contêineres guarda para você, e o arquivo de configuração fica dentro dele. O log
vai para a saída padrão do contêiner em vez de um arquivo. Não há unidade do systemd: é o runtime
que decide quando o servidor sobe e para. Um contêiner é excelente numa máquina de
desenvolvimento ou num teste que precisa de um servidor limpo a cada execução. Num servidor de
produção ele acrescenta uma camada que alguém precisa entender às três da manhã.

## Um serviço gerenciado

Um **serviço gerenciado** é um servidor que outra pessoa roda para você: Amazon RDS, Google Cloud
SQL, Azure Database for PostgreSQL e muitos provedores menores. Você recebe um endereço, uma porta
e um usuário, e nunca vê a máquina.

O que você abre mão é da maior parte deste curso. **Não há shell no servidor**, então não há
diretório de dados para olhar nem arquivo de log para ler, a não ser pelo console do provedor.
**Não há superusuário de verdade**: o provedor fica com esse papel e entrega a você um com menos
direitos. O arquivo de configuração vira um formulário ou uma chamada de API, e alguns parâmetros
nem são oferecidos. Em troca, backups, failover e upgrades de versão menor viram um ajuste em vez
de um projeto.

## Quem responde pelo quê

| | pacote | contêiner | serviço gerenciado |
|---|---|---|---|
| instala correções de segurança | você, com `apt` | você, baixando uma imagem nova | o provedor |
| lê os arquivos de dados | você | você, pelo volume | ninguém além do provedor |
| muda qualquer parâmetro | você | você | só os que o provedor oferece |
| detém o superusuário | você | você | o provedor |
| reinicia um servidor travado | você | você | o provedor, ou um botão |

Duas coisas continuam suas em todas as colunas: **os papéis e grants dentro do banco**, e **o
esquema** — quais são as tabelas e como elas mudam. Um serviço gerenciado roda o autovacuum para
você, mas não tem como saber que uma das suas tabelas precisa de outro ajuste. As lições 11 a 17 e
a 22 valem para os três.

**Este curso usa um pacote**, numa máquina sua, porque é o único dos três em que tudo de que o
curso fala está na sua frente. A próxima seção monta essa máquina.
