---
title: O que conta como segredo
version: 1
---

Um segredo é qualquer coisa que **dá acesso ou prova identidade**, de forma que um desconhecido que o tenha
possa agir como você ou como o seu sistema. Configuração é qualquer coisa que **muda como o programa se
comporta** sem dar acesso a nada. As duas são tratadas de formas diferentes, e confundi-las causa os dois
tipos de erro.

| segredo: nunca no repositório | configuração: pode ter um padrão no commit |
|---|---|
| senhas de um banco, de uma conta de e-mail, de uma página de administração | a porta em que o servidor escuta |
| chaves de API e tokens de serviços pagos ou privados | o caminho do arquivo do banco |
| a chave que assina sessões ou cookies | quantos dias dura um empréstimo |
| chaves privadas, de SSH ou de certificados TLS | o nome do site, uma chave de funcionalidade |
| uma string de conexão com senha dentro | uma string de conexão sem senha |

**O loanbook não tem segredo nenhum.** Sem contas, então sem chave de sessão; SQLite, então sem senha de
banco; sem e-mail, então sem senha de e-mail. Isso não é acaso. **O segredo mais barato de proteger é aquele
que você decidiu não precisar**, e vários cortes da aula 6 removeram um segredo junto com uma
funcionalidade.

A maioria dos projetos não tem essa sorte. Um app que chama uma API de previsão do tempo, manda e-mail ou
guarda arquivos na nuvem tem uma chave, e o resto desta aula é sobre mantê-la fora.
