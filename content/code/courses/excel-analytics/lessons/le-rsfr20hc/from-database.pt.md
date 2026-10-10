---
title: Um banco de dados, descrito em vez de executado
version: 1
---

**Uma conexão com banco de dados pede três coisas que um arquivo nunca pede: onde está o servidor,
quem é você e qual tabela você quer.** Depois disso a consulta é como qualquer outra, com uma
diferença que faz os bancos de dados valerem o trabalho: o servidor pode fazer o trabalho das suas
etapas antes que uma única linha chegue ao seu computador.

**Esta seção não foi executada, e não tem números.** O curso não lhe dá um banco de dados para
conectar, e o computador em que foi escrito não tem Excel. O que segue descreve as caixas de diálogo
e o que cada escolha significa, para que, na primeira vez que você as encontrar, no trabalho ou no
curso `sql-databases` (posição 5 da trilha de BI), você saiba o que está sendo pedido.

## As caixas de diálogo, em ordem

Os bancos de dados ficam em **Dados › Obter Dados › Do Banco de Dados**. O da própria Microsoft,
**Do Banco de Dados do SQL Server**, é o mais comum no trabalho e um bom modelo para os demais; os
outros aparecem no mesmo menu ou em **De Outras Fontes**, conforme a versão e o que estiver instalado.

1. **Servidor.** O nome ou endereço da máquina em que o banco roda, que quem o administra lhe passa,
   como `db.example.com` ou `SERVER01\SALES`. Opcionalmente o nome do **Banco de dados** e, em
   **Opções avançadas**, uma caixa para uma instrução SQL sua.
2. **Credenciais.** Como você prova quem é. O SQL Server oferece o seu login do **Windows**, um
   usuário e senha do **Banco de dados** ou uma **Conta da Microsoft**. O Excel guarda a resposta para
   aquele servidor no seu computador, não dentro da pasta de trabalho, então um colega que abrir o seu
   arquivo vai ter de informar as dele. **Dados › Obter Dados › Configurações da Fonte de Dados** é
   onde uma credencial salva é trocada ou apagada.
3. **O Navegador.** A mesma janela da seção 05 desta aula, listando as tabelas e os modos de exibição
   que o seu login pode ler. Marque um e escolha **Transformar Dados**.

Alguns bancos de dados precisam de um driver próprio instalado no seu computador antes que o Excel
consiga falar com eles. Quando falta um, o conector avisa, e a documentação do banco diz qual driver
instalar.

## O servidor faz o trabalho

Suponha que a loja virtual da Café Serra guardasse os pedidos num banco de dados em vez de mandar
arquivos mensais, e que a tabela de pedidos tivesse chegado a um milhão de linhas com os anos. Você se
conecta, filtra `Date` para 2026 e remove quatro colunas de que não precisa.

Com um arquivo, o Power Query leria o milhão de linhas inteiro e depois jogaria a maior parte fora.
Com um banco de dados ele faz coisa melhor: traduz as suas etapas numa única pergunta em **SQL**, a
linguagem do banco, e o servidor responde, mandando de volta só as linhas de 2026 e só as colunas que
você manteve. Isso se chama **dobra de consulta** (query folding), e é por isso que uma consulta sobre
uma tabela grande pode ser rápida. Clique com o botão direito numa etapa e escolha **Exibir Consulta
Nativa** (View Native Query) para ver o SQL em que ela virou; se o item estiver acinzentado, a etapa
não dobrou, e dali em diante o próprio Excel faz o trabalho.

Dois hábitos mantêm a consulta dobrando:

- **Filtre e remova colunas cedo.** Etapas que o banco entende, como filtros, escolha de colunas,
  ordenação e agrupamento, dobram; uma etapa sem equivalente em SQL interrompe a dobra, e toda etapa
  depois dela roda no Excel sobre as linhas que voltaram.
- **Prefira o Navegador à caixa de SQL.** Uma instrução digitada em **Opções avançadas** é enviada do
  jeito que está, e as etapas que você acrescenta depois dela são feitas no Excel, não pelo servidor.
  É a ferramenta certa quando você já tem a consulta exata; é o lugar errado para começar.

## O que perguntar antes de conectar

Um banco de dados no trabalho pertence a alguém, e três perguntas a essa pessoa economizam uma
tarde:

- qual **servidor e banco** usar;
- qual **login** você deveria ter: um pessoal, nunca uma senha compartilhada dentro de uma pasta de
  trabalho;
- se existe uma **cópia somente leitura** feita para relatórios, para que a sua atualização não deixe
  lento o sistema que recebe os pedidos.
