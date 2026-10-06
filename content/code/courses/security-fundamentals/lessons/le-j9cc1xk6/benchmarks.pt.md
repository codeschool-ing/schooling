---
title: Benchmarks: um checklist por produto
version: 1
---

Os CIS Controls dizem "configure com segurança todo sistema" (controle 4) sem dizer como, porque o como
depende do sistema. Esse é o trabalho de uma segunda publicação do CIS, com um nome parecido que confunde:
os **CIS Benchmarks**.

Um **CIS Benchmark** é um guia detalhado de configuração para um produto: um para Ubuntu Linux, um para
Windows Server, um para um banco de dados específico, um servidor web, um navegador, as configurações da
conta de um provedor de nuvem. Cada um é uma lista longa de recomendações, e cada recomendação traz:

- a **configuração** e o valor a usar;
- a **justificativa**: que ataque ou erro ela evita;
- como **auditar**: o comando ou a tela que mostra o valor atual;
- como **corrigir**: a mudança que põe o valor certo;
- o **impacto**: o que a mudança pode quebrar.

Eles são escritos e revistos por voluntários e fabricantes trabalhando juntos, e por isso se chamam
benchmarks de consenso, e são gratuitos para uso não comercial.

### Dois níveis

A maioria dos benchmarks divide as recomendações em dois **perfis**:

| perfil | intenção |
|---|---|
| **Nível 1** | a base prática: configurações que melhoram a segurança com pouco impacto no uso do sistema |
| **Nível 2** | defesa em profundidade para ambientes de alta segurança: configurações mais rígidas que podem quebrar alguma funcionalidade |

O Nível 1 é por onde todo mundo começa. O Nível 2 é escolhido de propósito, item por item, onde o risco
justifica o custo à usabilidade: a tensão da aula 1 entre confidencialidade e disponibilidade, de novo.

### Por que um checklist

Um servidor instalado do zero vem configurado para **conveniência**, e não para segurança. Isso não é
descuido do fabricante: um padrão precisa funcionar para todo mundo, e a escolha mais compatível muitas
vezes é a mais permissiva. A aula 2 chamou isso de vulnerabilidade de configuração, o tipo que não precisa
de defeito nenhum. Um benchmark é a lista de cada lugar onde o padrão conveniente e a configuração segura
diferem, escrita uma vez por gente que estudou o produto, para que cada administrador não precise
redescobri-los.

A propriedade mais valiosa de um benchmark, porém, é que **cada item pode ser conferido por uma
máquina.** "O root não pode entrar por SSH" vira um comando que imprime o valor atual, e uma verificação
vira um script que roda toda noite. A próxima seção escreve quatro verificações assim para o servidor SSH
da loja, no estilo de um benchmark, e não copiando um: o CIS Benchmark de verdade para Ubuntu tem
centenas de recomendações, e publicar o texto dele cabe ao CIS. A aula 2 de `defense-hardening` aplica os
benchmarks direito, com as ferramentas que os conferem em escala.
