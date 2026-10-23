---
title: O Vault num contêiner, e por que o modo dev fica no seu laptop
version: 1
---

**O Vault é um servidor que guarda segredos e decide, requisição por requisição, quem pode ler qual
deles.** Toda requisição leva um token do Vault; todo token leva policies; uma policy nomeia caminhos
e o que pode ser feito em cada um. Os segredos ficam em caminhos como `secret/linkbox/signing`, e nada
é lido sem um token cuja policy permita. A HashiCorp o publica, e os gerenciadores de segredos das
próprias nuvens (AWS Secrets Manager, Google Secret Manager, Azure Key Vault) seguem o mesmo modelo,
com os sistemas de identidade deles no lugar dos tokens do Vault.

Esta seção sobe um na sua máquina, a partir da imagem que o curso baixou junto com as outras,
`hashicorp/vault:2.1.2`.

### Subindo o servidor

Sem argumentos, a imagem sobe o **servidor de desenvolvimento** do Vault:

@@FENCE 1@@

`-p 127.0.0.1:8200:8200` publica a porta só na sua própria máquina, e `VAULT_ADDR` diz ao cliente de
linha de comando dentro do contêiner onde está o servidor. `VAULT_DEV_ROOT_TOKEN_ID` é uma
conveniência do modo dev que não existe em nenhum outro lugar: deixa você escolher o root token em
vez de receber um aleatório. A aula escolhe `dev-only-root`, um nome que diz o que é, por um motivo
que a aula 6 já deu. Um root token aleatório tem a forma de um token de verdade do Vault. Uma
transcrição que carrega um é um arquivo que os scanners de segredos, entre eles o push protection do
GitHub, recusam como credencial vazada, por mais morto que esteja o servidor por trás. O segundo
comando imprime o aviso que o Vault escreve ao subir, que já diz quase tudo o que vem a seguir.

### Do que o modo dev abre mão

**O modo dev é um servidor feito para ser jogado fora, e cada conveniência dele é um controle de
produção desligado.** Lendo o aviso linha por linha:

| modo dev | o que um Vault de produção faz no lugar |
|---|---|
| "runs entirely in-memory" | guarda os dados em armazenamento persistente, em geral o Raft integrado do Vault, em três ou cinco servidores |
| "starts unsealed with a single unseal key" | sobe **selado**: o armazenamento é cifrado e ele não consegue lê-lo até que portadores suficientes de partes da chave o desselem, ou que um serviço de chaves da nuvem faça isso automaticamente |
| o root token impresso no log | o root token é usado para configurar as primeiras policies e métodos de autenticação, e depois revogado |
| o listener não tem TLS | atende só por TLS, porque toda requisição leva um token |

Cada item importa por um motivo diferente. Um Vault que guarda segredos em memória perde todos quando
o contêiner para, o que vai bem numa aula e é um desastre num servidor de CI. Um root token num
arquivo de log é um token que faz qualquer coisa, num arquivo lido por quem lê logs. E um token
enviado por HTTP puro pode ser lido por qualquer um entre o cliente e o servidor, o que na sua
própria máquina é ninguém e numa rede não é.

Nada da configuração de produção roda neste curso. A documentação da HashiCorp a descreve, e o
ponto aqui é a frase com que o aviso termina: **o modo de desenvolvimento não deve ser usado em
produção**. Tudo o que esta aula monta em cima dele, a policy, o método de autenticação e a role, é
configurado do mesmo jeito num Vault de produção.

### Um cliente de linha de comando, emprestado do contêiner

A imagem traz o cliente de linha de comando do Vault além do servidor. Uma função de shell o empresta
ao seu terminal, e `vault` passa a se comportar como se estivesse instalado:

@@FENCE 2@@

`Sealed false` e `Storage Type inmem` são as duas primeiras linhas do aviso, confirmadas pelo próprio
servidor. A função roda o cliente dentro do contêiner, onde o modo dev deixou o root token pronto,
então **todo comando `vault` desta aula roda como root**. Esse é o operador configurando o Vault. O
pipeline nunca usa essa função: ele fala com o Vault por HTTP com `curl`, como um job de CI faz,
levando só o token que recebeu. Mantenha os dois papéis separados ao ler as capturas. A função dura
o tempo do terminal; um terminal novo precisa da linha de novo.

### A senha se muda

No modo dev, o Vault monta um armazenamento chave/valor em `secret/`. Coloque nele a senha de
assinatura do servidor de CI e confira se o que volta é o arquivo, byte a byte:

@@FENCE 3@@

O valor foi do arquivo para a linha de comando do Vault por `$(cat …)` e nunca foi impresso. A
comparação imprime `same` e mais nada, que é como conferir um segredo sem mostrá-lo.

Dois detalhes da saída importam na próxima seção. O armazenamento chave/valor guarda **versões**:
gravar o caminho de novo cria a versão 2 e mantém a versão 1, e é assim que um segredo trocado pode
voltar atrás. E o caminho que a API usa não é o que você digitou. `vault kv put secret/linkbox/signing`
grava em `secret/data/linkbox/signing`, a primeira linha da saída, porque a versão 2 do armazenamento
guarda dados, metadados e exclusões sob prefixos separados. **Uma policy é escrita contra o caminho
da API**, e uma policy para `secret/linkbox/signing` não concederia nada.

A senha agora está em dois lugares, o arquivo e o Vault, e de propósito. O arquivo é o que o
`ci/sign.sh` lê hoje. A seção em que o pipeline a lê do Vault, três seções adiante, diz o que precisa
mudar num servidor de CI de verdade antes de o arquivo poder sumir.
