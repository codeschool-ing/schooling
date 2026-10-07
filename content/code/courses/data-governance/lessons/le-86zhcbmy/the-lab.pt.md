---
title: O seu laboratório, e três jeitos de montá-lo
version: 1
---

**Ninguém aprende controle de acesso lendo um grant.** Aprende quando uma consulta que deveria
funcionar responde `permission denied`, ou quando uma que deveria falhar devolve seis mil linhas.
Então toda aula aqui é executada, numa máquina que você mesmo monta. A plataforma não dá máquina
nenhuma: o laboratório é seu, e as próximas três seções o montam do zero, com todo comando e todo
arquivo na página.

É uma máquina Linux com:

- **PostgreSQL 16**, num cluster próprio chamado `gov` na porta 5433, com o banco da Ipê, `ipe`:
  três schemas — `sales`, `health` e `support` — e sete tabelas, carregadas com 6.012 clientes e
  sete anos de pedidos. A seção 4 monta o cluster e a seção 5, os dados.
- **Uma pequena autoridade certificadora** do próprio laboratório, que a aula 3 cria para o banco
  ter um certificado que um cliente consiga conferir.
- **OpenBao**, um servidor de gestão de chaves, que a aula 4 instala e inicia.

Tudo roda no **Ubuntu 24.04**. Toda transcrição deste curso foi gravada nele, e os comandos supõem os
nomes de pacote e os caminhos dele. Outro Linux funciona se você traduzir os nomes dos pacotes; os
caminhos nas transcrições aí vão ser outros.

## Três jeitos de rodar

**Numa máquina virtual — o recomendado.** Uma máquina virtual com Ubuntu 24.04, 2 GB de memória e
10 GB de disco livre basta, no VirtualBox, no UTM num Mac, no Hyper-V ou em qualquer hipervisor que
você já tenha. O laboratório acrescenta um usuário, um servidor de banco, um servidor de chaves, um
arquivo de sudoers e duas linhas no `/etc/hosts`: exatamente o tipo de mudança que você não quer no
computador em que trabalha, e numa máquina virtual um erro custa um snapshot. A aula 4 de
`virtualization` monta uma no VirtualBox, se você nunca montou. **Custo para o seu computador**: a
memória e o disco acima enquanto ela roda, e nada depois que você a apaga.

**Instalado num Linux seu.** Dá, se ele roda Ubuntu 24.04 — ou Windows, pelo WSL com uma
distribuição Ubuntu 24.04. Leia a seção 4 antes de rodá-la: ela escreve no `/etc/hosts`, no
`/etc/postgresql-common/user_clusters` e num arquivo de sudoers, e se algum desses é um arquivo com
que você se importa, use a máquina virtual. Uma parte da aula 3, abrir um volume cifrado, precisa do
device-mapper do kernel, que o WSL não oferece; aquela aula diz isso onde importa. **Custo**: uns
300 MB de pacotes, e mudanças em arquivos do sistema que você tem de desfazer à mão.

**Online, na máquina de outra pessoa.** Uma pequena máquina virtual na nuvem com Ubuntu 24.04,
1 vCPU e 2 GB de memória, acessada por SSH — de um terminal ou da página do provedor, no navegador.
Qualquer provedor serve; o curso não depende de nenhum, e camadas gratuitas vêm e vão. **Custo**:
nada no seu computador, uma conta num provedor, e dinheiro ou uma cota gratuita pelas horas em que
ela roda. Toda linha deste laboratório é inventada, então nada real é mandado a lugar nenhum, mas
desligue a máquina quando não estiver estudando.

Seja qual for a escolha, os comandos do resto do curso são os mesmos.
