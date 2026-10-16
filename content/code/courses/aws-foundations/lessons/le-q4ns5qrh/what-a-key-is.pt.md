---
title: O que é uma chave de acesso, e por onde as chaves vazam
version: 1
---

**Uma chave de acesso é uma senha para a API que não tem segundo fator, não vence e não faz ideia de
onde está sendo usada.** Quem tem as duas strings é o usuário do IAM, de qualquer computador da
internet, até alguém apagar a chave. As lições 10 e 11 a substituíram para máquinas e para pessoas;
esta lição é sobre os casos em que nada a substituiu, e sobre o que fazer no dia em que uma escapa.

A imagem errada comum é que uma chave é segura porque é longa. **A chave nunca é adivinhada; ela é
copiada.** O comprimento a protege de um atacante que tenta strings, e ninguém faz isso. O atacante
que importa acha uma chave que foi anotada em algum lugar, e daí em diante o comprimento não conta.

## Duas strings, e o que elas fazem

Uma chave é um par. O **id da chave de acesso**, `AKIA` e mais dezesseis caracteres numa chave de
longo prazo, não é segredo: ele nomeia a chave, e aparece em toda requisição e em toda linha do
CloudTrail. A **chave secreta**, de quarenta caracteres, nunca é enviada a lugar nenhum. O cliente a
usa para assinar cada requisição, como a lição 26 mostra byte a byte, e a AWS confere a assinatura
com a cópia dela.

O que o par não tem é a lista que deixa o resto deste curso confortável:

| | uma chave de acesso | uma sessão de role (lições 9 a 11) |
|---|---|---|
| vence | nunca, até ser apagada | em minutos ou horas |
| segundo fator | nenhum; a chave sozinha basta | herdado de quem abriu a sessão |
| presa a um lugar | não; funciona de qualquer rede | a quem teve permissão de assumir a role |
| aparece no CloudTrail como | o usuário do IAM | a role, com um nome de sessão |

**Duas chaves por usuário é o limite**, e a próxima seção mede o moto aplicando-o. A segunda vaga
existe por um único motivo: trocar a chave sem parar o programa que usa a primeira.

## Por onde as chaves vazam

Chaves raramente vazam pela AWS. **Elas vazam por tudo o mais que uma pessoa toca**, e quatro lugares
respondem pela maioria dos casos que a AWS e o GitHub publicam:

- **um repositório.** Uma chave colada num arquivo de configuração, num teste, num notebook ou num
  `.env` que foi commitado uma vez e removido depois. Apagar a linha não apaga o commit, e um
  repositório público é lido por varredores minutos depois de um push;
- **uma imagem.** Uma imagem de contêiner construída com `COPY . .` a partir de um diretório que
  tinha `~/.aws` ou um `.env`, depois enviada a um registry. Cada camada é um tar que qualquer um que
  consiga baixá-la abre;
- **um log.** Um programa que imprime o ambiente quando falha, um job de CI que roda com `set -x`, um
  relatório de erro que anexa a requisição que estava fazendo. A chave vai parar onde os logs vão,
  que costuma ser um lugar com acesso mais fraco que a conta;
- **um laptop.** O `~/.aws/credentials` é um arquivo de texto simples. Um laptop roubado, um
  diretório pessoal sincronizado, um backup num drive compartilhado: cada um é uma cópia da chave.

Os quatro têm a mesma forma. **Uma chave é uma string, e strings são copiadas** por ferramentas a
que ninguém disse que aquilo era segredo.

## As alternativas, que vêm primeiro

Então a regra é que uma chave é o **último recurso**: a resposta depois que toda outra resposta foi
descartada. Para cada tipo de programa, o curso já tem uma:

| quem chama a AWS | em vez de uma chave | onde |
|---|---|---|
| uma pessoa num teclado | o IAM Identity Center e o `aws sso login` | lição 11 |
| um programa no EC2 | um instance profile | lição 10 |
| um contêiner no ECS ou um pod no EKS | uma task role, o Pod Identity ou o IRSA | lição 10 |
| um pipeline de CI (GitHub Actions, GitLab) | o token OIDC do pipeline, trocado por uma role | lição 10 |
| um programa em outra conta da AWS | uma role que ele assume entre contas | lição 9 |
| um servidor no escritório, fora da AWS | o IAM Roles Anywhere, com um certificado | citado aqui |

A última linha é a que puxa as pessoas para uma chave, e ela também tem resposta. O **IAM Roles
Anywhere** deixa uma máquina fora da AWS assumir uma role apresentando um certificado X.509 emitido
por uma autoridade certificadora em que a conta confia; as credenciais que ela recebe vencem como
qualquer outra sessão de role. Ele exige uma autoridade certificadora e a disciplina de manter uma,
e é por isso que algumas organizações ainda recorrem a uma chave ali. Este curso o cita e não o
executa: o moto 5.2.3 responde toda chamada de `rolesanywhere` com um erro interno.

O que sobra depois da tabela é pouco. **Um programa fora da AWS, numa máquina a que a organização
não consegue dar um certificado, chamando a AWS num horário fixo**: o sistema de um fornecedor que
envia um arquivo toda noite, um equipamento antigo com um campo para chave de acesso e nada mais. A
loja tem um desses, o sistema de contabilidade do escritório, e a próxima seção lhe dá uma chave e a
troca.
