---
title: Onde as verificações rodam, e o que elas não veem
version: 1
---

O `check.sh` foi escrito para que o mesmo comando rode num notebook e num servidor. **O servidor é
onde vale**: um pipeline que o roda a cada pull request, e bloqueia o merge quando falha, é uma
verificação que ninguém esquece nem pula.

::: track devsecops
Esse pipeline é o assunto do curso `secure-pipeline` da sua trilha, que o monta na sua própria
máquina e acrescenta o que esta aula não traz: varredura de segredos, varredura de imagens de
contêiner e as regras de quando uma verificação falhando pode bloquear um lançamento. Esta aula
apresenta as verificações; aquele curso as opera.
:::

::: track *
Qualquer serviço de integração contínua roda um script como este a cada mudança; a aula o mantém
como um comando só justamente para que levá-lo para lá seja uma linha de configuração.
:::

### O que essas três ferramentas não veem

| o quê | por que as ferramentas não veem | o que pega |
|---|---|---|
| uma rota que nunca verifica de quem é o dado que entrega | nada no código é uma "chamada arriscada"; a falha é uma linha ausente | um teste que enuncia a recusa, e a revisão da aula 18 |
| um requisito que ninguém escreveu | não há código para varrer | ler a história, aula 1 |
| uma falha que só aparece com a aplicação rodando | ferramentas estáticas leem texto, não comportamento | testes contra a aplicação rodando |
| um alerta ainda não publicado | o pip-audit relata o que é conhecido | a rotina da aula 17, rodada de novo amanhã |

A terceira linha tem uma família de ferramentas própria: **testes dinâmicos de segurança de
aplicação**, ou DAST, que enviam requisições a uma aplicação rodando e examinam as respostas. O OWASP
ZAP é o gratuito mais conhecido. Ele deve ser apontado para uma cópia da sua própria aplicação num
ambiente de teste, e não foi executado para este curso.

### Uma execução verde é um piso

Um `check.sh` passando diz que os testes que você escreveu passam, que nenhum padrão arriscado que o
bandit conhece está presente, e que nenhum alerta publicado corresponde às suas versões. Isso vale
muito, e é um piso, não um certificado. **O que fica acima do piso é o assunto do curso inteiro**:
saber que recusas uma aplicação deve, e escrever o teste que pede cada uma.
