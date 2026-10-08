---
title: Erradicação: o que ficou, e a entrada
version: 1
---

A aula 13 deixou a empresa contida: o `files` só alcança o backup, `203.0.113.66` está bloqueado, e a conta do
bruno está bloqueada. Nada disso removeu coisa alguma. A **erradicação** remove duas coisas, e uma resposta que
faz só uma delas vai ter de ser feita de novo:

1. **O que ficou para trás.** Um invasor que entrou uma vez costuma garantir que vai entrar de novo. Na quinta,
   a linha do tempo da aula 12 mostra isso: um login com a senha do bruno, e depois, às 03:05:22, um login com
   uma **chave**. Alguém adicionou essa chave enquanto estava lá dentro.
2. **A entrada.** A quinta começou com uma senha adivinhada num servidor que aceitava senhas da internet
   inteira. Remova a chave e deixe isso, e o próximo palpite também funciona.

Os lugares onde coisas ficam para trás num servidor Linux são uma lista curta, e auditá-los é uma lista de
conferência de quem defende, que não depende de saber o que o invasor fez:

| onde | contra o que comparar |
|---|---|
| `authorized_keys` em toda pasta pessoal, e o do root | um inventário de chaves aprovadas |
| as contas no `/etc/passwd`, e quem está no grupo `sudo` | a lista de funcionários, e quem deveria ser administrador |
| tarefas agendadas: crontabs, timers do systemd | o que o dono do servidor diz que ele roda |
| serviços que iniciam no boot | o padrão de instalação daquele servidor |
| arquivos alterados recentemente em pastas do sistema | o registro do próprio gerenciador de pacotes (`dpkg --verify`) |

A coluna da direita é a parte difícil. Uma auditoria compara contra **um registro do que deveria estar lá**, e
uma empresa sem esse registro não consegue distinguir a chave de um invasor da chave de um colega. Por isso a
próxima seção começa escrevendo o registro.

**Todo item é copiado, recebe um hash e é registrado antes de ser removido.** A chave no arquivo do bruno é
evidência: a impressão digital dela pode aparecer no servidor de outra vítima, e o grupo de compartilhamento
da aula 8 ia querer saber. Apagá-la às pressas, sem guardar nada, ganha um minuto e perde isso.

No registro da quinta, a auditoria dos dois hosts achou um item: uma chave no `authorized_keys` do bruno no
`gw` que o bruno não reconheceu quando perguntaram a ele pessoalmente. Ela foi copiada para a pasta do
incidente com o hash, e então removida.
