---
title: O que a governança decide
version: 1
---

Oito aulas depois, este curso construiu regras de acesso, cifragem, chaves, pseudônimos, uma
classificação, um registro de consentimento, um registro de pedidos, um inventário de sistemas de IA.
Cada um foi decisão de alguém. **Governança de dados é o arranjo que diz quem toma essas decisões,
como, e como qualquer pessoa consegue saber que elas foram tomadas.** Não é uma ferramenta nem um
departamento. É a resposta a "quem decidiu isto, e onde está escrito?"

A referência de costume é o *Data Management Body of Knowledge* (DMBOK) da DAMA, que põe a governança
no centro de dez outras áreas — qualidade, metadados, segurança, arquitetura, e assim por diante — e
a define como o exercício de autoridade e controle sobre a gestão dos dados. A distinção útil que ele
traça é entre **governança**, que decide, e **gestão**, que executa as decisões. Escolher que CPFs
ficam só como texto cifrado foi governança; o `ALTER TABLE` da aula 5 foi gestão.

## Três perguntas que esta aula responde com tabelas

- **Quem responde por este dado?** Um dono por tabela, e um curador que cuida dela. Seção 3.
- **O dado presta?** Medido, com regras que rodam e um histórico de cada execução. Seções 4 a 8.
- **O que ele significa, e de onde veio?** Metadados guardados ao lado do dado, e linhagem lida do
  registro do próprio banco. Seções 9 e 10.

O padrão é o mesmo que o curso usa desde a aula 2: **uma decisão que mora numa tabela pode ser
consultada, testada e auditada; uma decisão que mora numa página de wiki só pode ser acreditada.**
Toda resposta abaixo termina como linhas em que alguém pode dar `SELECT`.

## O que ela não é

Governança não é aprovação para tudo. Um programa em que toda coluna nova espera três semanas por um
comitê ensina as pessoas a guardar dados onde o comitê não vê — uma planilha, um bucket particular —,
e esse dado fica pior governado do que antes. O objetivo é o contrário: decidir as regras uma vez,
transformá-las em verificações que rodam sozinhas, e gastar o tempo das pessoas nos casos que as
verificações não resolvem. A classificação da aula 6 é o modelo: uma linha por coluna, escrita por
quem acrescenta a coluna, e uma consulta que faz o deploy falhar se ninguém a escreveu.
