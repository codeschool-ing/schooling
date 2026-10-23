---
title: Menor privilégio é uma distância que se mede
version: 1
---

**Menor privilégio não é uma propriedade que uma política tem no dia em que é escrita. É a distância
entre o que uma identidade pode fazer e o que ela de fato faz, e essa distância cresce sozinha se
ninguém a mede.** A aula 7 do curso `cloud` escreveu a regra: comece da negação implícita e
acrescente só o que o trabalho precisa. Esta aula trata de uma conta em que essa regra não foi
seguida, que é a maioria delas.

A imagem errada é a de que permissões se definem uma vez, como a fechadura de uma porta. Elas se
comportam mais como um chaveiro. Um desenvolvedor precisa ler um grupo de logs durante um incidente,
e uma política ganha `logs:*`. Uma prestadora precisa dar a política de relatórios a cada analista
novo, e ganha o direito de anexar políticas a usuários. Cada concessão resolveu um problema real num
dia real. **Ninguém abre chamado para remover uma permissão que não está causando erro**, então o
chaveiro só fica mais pesado.

## Concedido contra usado

Duas listas descrevem toda identidade:

| | de onde vem | como muda |
|---|---|---|
| **concedido** | as políticas anexadas ao usuário, aos grupos dele ou ao papel | cresce toda vez que alguém resolve um problema |
| **usado** | o que as requisições da identidade de fato fizeram, como o provedor registrou | acompanha o trabalho, e encolhe quando o trabalho para |

Menor privilégio é o trabalho de aproximar a primeira lista da segunda. A direção importa: você não
chega à lista do usado raciocinando, porque ninguém lembra quais de quarenta ações um processo chama
no último dia do mês. Você a lê em registros.

A AWS guarda três tipos de registro que ajudam, e cada um responde a uma pergunta diferente:

- **quando uma chave foi usada pela última vez**, por chave de acesso, com o serviço e a região dessa
  requisição. Responde "esta chave está morta?", e as duas últimas seções desta aula a usam;
- **quando cada serviço foi acessado pela última vez**, por usuário, grupo ou papel: a aba *Access
  Advisor* do console do IAM, ou `generate-service-last-accessed-details` na linha de comando.
  Responde "quais destas concessões nunca foram exercidas?";
- **o IAM Access Analyzer**, que lê o CloudTrail e consegue apontar permissões sem uso ou rascunhar
  uma política a partir das ações que um papel realmente chamou num período que você escolhe.

**O moto guarda o primeiro e não os outros dois.** Ele registra o último uso de uma chave, como as
transcrições desta aula mostram, enquanto `generate-service-last-accessed-details` responde com um
erro interno do servidor e as descobertas de acesso sem uso do Access Analyzer não existem nele. O que
o segundo e o terceiro fazem vem da documentação da AWS e não foi executado.

## Nem toda permissão a mais tem o mesmo tamanho

Um usuário que lê um bucket a mais do que precisa tem uma distância. Um usuário que pode **mudar
permissões** não tem teto nenhum, porque a primeira coisa que um portador indesejado dessa chave
faria seria se conceder o resto. Por isso uma revisão não começa pela maior política; começa por
qualquer identidade que possa escrever no IAM.

O curso `cloud` chamou `iam:*` de acesso de administrador com outro nome. Não é só `iam:*`. Uma
única ação de aparência estreita basta quando é a ação certa, e duas seções adiante uma faz
exatamente isso no seu laboratório. A seção seguinte lista as ações a procurar, tiradas de uma lista
que a própria AWS publica.
