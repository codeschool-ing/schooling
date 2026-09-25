---
title: Configurando um programa de e-mail
version: 1
---

Tudo acima é o que um programa de e-mail faz atrás de uma tela de configuração. Para a conta da Ana,
essas configurações são:

| | servidor | porta | segurança | usuário |
|---|---|---|---|---|
| entrada, IMAP | `mail.example.com` | 993 | SSL/TLS | `ana` |
| saída, SMTP | `mail.example.com` | 587 | STARTTLS | `ana`, com a senha |
| entrada, POP3 | `mail.example.com` | 995 | SSL/TLS | só onde o IMAP não for opção |

**Nada disso foi digitado num programa de e-mail para esta aula**; são os valores que as seções 04, 06 e 07 usaram, dispostos como
o Outlook, o Thunderbird, o Mail da Apple e um celular os pedem. A maioria dos programas tenta adivinhá-los
pelo endereço, e quando o palpite falha, são estes que se digitam. Dois erros cobrem a maior parte das
ligações. Um é o servidor de saída na porta 25, que muitas redes bloqueiam para computadores comuns. O
outro é "nenhuma" escolhida para a cifragem, que alguns servidores recusam e outros aceitam, mandando a
senha às claras.

Empresas no Microsoft 365 ou no Google Workspace veem os mesmos protocolos com outros nomes, e configuram
SPF, DKIM e DMARC no DNS com os valores que a página de administração do provedor dá. Os cabeçalhos, a
devolução e as três conferências se leem exatamente como aqui.
