---
title: O curso, capítulo a capítulo
version: 1
---

Cada aula deste curso é uma pequena parte do ASVS, ensinada por dentro. A tabela as associa, no
nível da seção, para que um projeto que usa o curso ache os requisitos a verificar:

| aula | assunto | seções do ASVS 5.0.0 |
|---|---|---|
| 1 | onde a falha nasce | V2.1, V15.1 (documentar o que a aplicação deve fazer) |
| 2 | validação por lista de permissão | V2.2, e V1.1 para decodificar para a forma canônica uma vez |
| 3 | validação no cliente e no servidor | V2.2 |
| 4 | escape por contexto | V1.1, V1.2 |
| 5 e 6 | injeção | V1.2 |
| 7 | XSS | V1.2, V1.3, V3.2 |
| 8 | Content Security Policy | V3.4 |
| 9 | CSRF | V3.5 |
| 10 | sessões | V7.2 a V7.4, e V3.3 para cookies |
| 11 | senhas | V6.2 |
| 12 e 13 | controle de acesso, IDOR | V8.2, V8.3 |
| 14 | desserialização e upload | V1.5, V5.2, V5.3 |
| 15 | erros e logs | V13.4, V16.2 a V16.5 |
| 16 | segredos | V13.3 |
| 17 | dependências | V15.2 |
| 18 e 19 | revisão e verificações automáticas | como cada requisito acima é verificado |

### Duas seções, lidas junto com duas aulas

O encerramento de sessão é onde a aula 10 do curso encontra o V7.4 do padrão:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v7.4.
V7.4.1 (L1) Verify that when session termination is triggered (such as logout or expiration), the application disallows any further use of the session. For reference tokens or stateful sessions, this means invalidating the session data at the application backend. Applications using self-contained tokens will need a solution such as maintaining a list of terminated tokens, disallowing tokens produced before a per-user date and time or rotating a per-user signing key.
V7.4.2 (L1) Verify that the application terminates all active sessions when a user account is disabled or deleted (such as an employee leaving the company).
V7.4.3 (L2) Verify that the application gives the option to terminate all other active sessions after a successful change or removal of any authentication factor (including password change via reset or recovery and, if present, an MFA settings update).
V7.4.4 (L2) Verify that all pages that require authentication have easy and visible access to logout functionality.
V7.4.5 (L2) Verify that application administrators are able to terminate active sessions for an individual user or for all users.
```

O V7.4.1 é de nível 1 e diz aquilo de que trata a aula 10: quando uma sessão termina, **o servidor
para de aceitá-la**, e uma aplicação cujas sessões são tokens autocontidos precisa de mecanismo
extra para conseguir isso. O V7.4.3 é a mesma ideia aplicada a uma troca de senha.

E o assunto da aula 17, no V15.2:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v15.2.
V15.2.1 (L1) Verify that the application only contains components which have not breached the documented update and remediation time frames.
V15.2.2 (L2) Verify that the application has implemented defenses against loss of availability due to functionality which is time-consuming or resource-demanding, based on the documented security decisions and strategies for this.
V15.2.3 (L2) Verify that the production environment only includes functionality that is required for the application to function, and does not expose extraneous functionality such as test code, sample snippets, and development functionality.
V15.2.4 (L3) Verify that third-party components and all of their transitive dependencies are included from the expected repository, whether internally owned or an external source, and that there is no risk of a dependency confusion attack.
V15.2.5 (L3) Verify that the application implements additional protections around parts of the application which are documented as containing "dangerous functionality" or using third-party libraries considered to be "risky components". This could include techniques such as sandboxing, encapsulation, containerization or network level isolation to delay and deter attackers who compromise one part of an application from pivoting elsewhere in the application.
```

O V15.2.1 é de nível 1, e não diz "nenhuma vulnerabilidade conhecida". Diz que os componentes não
**ultrapassaram os prazos documentados de atualização e correção**: o projeto escreve em quanto tempo
age diante de um alerta, e depois cumpre. É a rotina da aula 17, escrita como um requisito que alguém
consegue verificar.
