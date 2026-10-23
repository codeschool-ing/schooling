---
title: Uma lista de verificação que cabe numa tela
version: 1
---

Uma lista de verificação é útil quando é curta o bastante para ser usada em toda revisão e específica
o bastante para mudar o que o revisor olha. Listas longas de segurança são lidas uma vez e
arquivadas. Esta tem uma linha por aula do curso que um diff consegue mostrar, na ordem das cinco
perguntas:

| procure | a pergunta | aula |
|---|---|---|
| uma rota ou ação nova | há verificação de quem, e de quem é? | 1, 12, 13 |
| um valor de uma requisição | validado numa fronteira, contra uma lista de permissão? | 2 |
| um registro montado de uma requisição | montado só com campos conhecidos? | 3 |
| um valor escrito numa página | escapado pelo template, entre aspas, nunca marcado `safe`? | 4 |
| uma mudança de sessão ou cookie | flags mantidas, vida curta, encerrada no logout? | 10 |
| uma senha ou um token | com hash ou comparada com a ferramenta certa? | 11 |
| um erro ou linha de log | revela algo que um estranho não deveria ver? | 15 |
| uma chave, uma senha ou uma URL com credenciais | está no código ou no repositório? | 16 |
| `requirements.txt` | fixado, e auditado? | 17 |
| qualquer um dos acima | veio um teste junto? | 19 |

Duas coisas uma lista não faz. Não acha uma falha que ninguém listou, e é para isso que servem as
cinco perguntas da primeira seção. E não substitui conhecer o sistema: um revisor que sabe que
mensagens pertencem a pacientes vê o achado 1 na hora, e um que não sabe vê uma rota que funciona.

### O que uma máquina tira da lista

Algumas linhas da tabela podem ser verificadas sem uma pessoa: uma versão fixada que virou intervalo,
um alerta conhecido contra uma versão, uma string com cara de chave, um template marcado `safe`. A
aula 19 transforma isso em verificações automáticas que rodam antes de a revisão começar, para que a
meia hora do revisor vá para as perguntas que só uma pessoa responde: quem pode fazer isto, e de quem
é.
