---
title: Os arquivos do banco, e a cifragem transparente de dados
version: 1
---

**Um banco de dados guarda suas tabelas em arquivos comuns, e o que está numa tabela está nesses
arquivos, de forma legível, a menos que algo os cifre.** Quem copia o diretório de dados, um backup
ou um snapshot do disco obtém os dados sem nem entrar no banco.

## Lendo uma tabela sem pedir ao banco

O banco do laboratório da Vereda tem uma tabela `patients`, montada na próxima seção. Depois que um
checkpoint grava a tabela em disco, o arquivo da tabela pode ser lido com o `strings`, que imprime
qualquer sequência de caracteres legíveis num arquivo binário:

```
ana@lab:~/lab$ psql -c CHECKPOINT
CHECKPOINT
ana@lab:~/lab$ strings /var/lib/postgresql/16/main/$(psql -Atc "SELECT pg_relation_filepath('patients')") | grep -oE 'Marina Duarte|Joao Pires|111\.444\.777-35' | sort | uniq -c
      2 Joao Pires
      2 Marina Duarte
```

Os nomes dos dois pacientes estão lá, duas vezes cada: o PostgreSQL mantém versões antigas das linhas
atualizadas até o `VACUUM` recuperá-las, então um arquivo também guarda o que uma tabela não mostra
mais. O CPF **não** está lá, porque a próxima seção cifra essa coluna. Todo o resto da tabela, e de
todas as outras tabelas, pode ser lido por quem tiver o arquivo, no servidor, nos backups e em
qualquer cópia de qualquer um dos dois.

## Cifragem transparente de dados

A **TDE** (*transparent data encryption*) cifra os arquivos do banco à medida que o banco os grava e
os decifra à medida que lê, então nem a aplicação nem as consultas mudam: daí *transparente*. O SQL
Server, o Oracle e o MySQL a oferecem, e bancos gerenciados na nuvem (Amazon RDS, Azure SQL, Cloud
SQL) cifram o armazenamento por padrão. O PostgreSQL comunitário não tem TDE embutida; as
implantações se apoiam na cifragem de disco da seção anterior, ou numa distribuição que a acrescenta.

A TDE impede exatamente um tipo de roubo: o dos **arquivos**. Arquivos de dados copiados, um backup
roubado, um disco descartado. Ela não faz nada contra quem consegue rodar uma consulta, porque o
banco decifra para toda sessão autorizada, e isso inclui:

- um administrador do banco, ou qualquer um que obtenha as credenciais de um administrador;
- uma conta de aplicação usada por injeção de SQL;
- um `pg_dump` ou `mysqldump`, que produz um dump **sem cifragem**, a menos que o dump seja depois
  cifrado como um arquivo à parte.

Esse último ponto é onde muitos esquemas de backup falham em silêncio: o banco está "cifrado em
repouso", o dump noturno é gravado em texto claro num bucket, e é o bucket que vaza.

## Onde a chave mora decide tudo

Uma chave de TDE guardada no arquivo de configuração do mesmo servidor é copiada junto com os
arquivos de dados por quem copiar o servidor, o que reduz a TDE à ofuscação da aula 11. Implantações
sérias mantêm a chave mestra da TDE num serviço de gestão de chaves ou num HSM, a quem o banco pede
para desembrulhar suas chaves na inicialização. A última seção desta aula monta esse arranjo.
