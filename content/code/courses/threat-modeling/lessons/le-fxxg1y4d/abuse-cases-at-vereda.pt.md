---
title: Casos de abuso na Vereda
version: 1
---

Cruzar os principais casos de uso do portal com os atores desta aula deu à equipe dez casos de
abuso em uma hora. Cada um aponta a ameaça cuja história ele conta, e três deles contaram uma
história que nenhuma ameaça da lista tinha contado ainda.

| | caso de uso | ator | caso de abuso | ameaça |
|---|---|---|---|---|
| A1 | agendar uma sessão | testador de senhas vazadas | entra com uma senha vazada e vê os agendamentos e exames do paciente | T02 |
| A2 | agendar uma sessão | qualquer paciente | agenda e cancela em sequência, mandando um SMS a cada vez | T11 |
| A3 | ver os meus exames | paciente logado | muda o número do exame e baixa o laudo de outra pessoa | T07 |
| A4 | enviar um exame | paciente logado | envia arquivos até encher o armazenamento | T10 |
| A5 | receber lembrete | alguém próximo de um paciente | lê o lembrete no celular do paciente e descobre onde ele vai estar, e quando | T08 |
| A6 | cuidar da agenda | recepcionista curiosa | abre as anotações clínicas de um vizinho | T09 |
| A7 | cuidar da agenda | ex-funcionário | entra meses depois de sair, porque a conta ainda funciona | **nova: T15** |
| A8 | ver os meus agendamentos | alguém próximo de um paciente | entra com a senha do paciente e acompanha a agenda semana a semana | **nova: T16** |
| A9 | mudar o meu telefone | alguém próximo de um paciente | muda o número para que lembretes, e trocas de senha, vão para o celular dele | **nova: T17** |
| A10 | pagar uma sessão | qualquer paciente | paga, e depois manda um webhook forjado para o agendamento seguinte | T01 |

**Três ameaças novas**, e nenhuma precisou de tecnologia nova para ser achada. Cada uma veio de pôr um
ator ao lado de uma funcionalidade e perguntar o que essa pessoa faria com ela:

- **T15** (S, o console): contas de quem saiu da equipe não são desligadas.
- **T16** (I, entrar e agendar): quem sabe a senha de um paciente continua lendo a agenda dele, e
  nada avisa o paciente de que há outra sessão aberta.
- **T17** (S, entrar e agendar): mudar o número de telefone não pede uma segunda confirmação, então
  quem tiver uma sessão consegue desviar tudo o que prova identidade.

As três entram no `threats.csv` com os ids seguintes, registradas nos elementos que a aula aponta. A
A9 é a mais séria delas, e é um bom exemplo do que casos de abuso fazem: mudar o número de telefone é
uma funcionalidade que ninguém vê como segurança, e é a que entrega a conta.

### E uma que não é

A A10, pagar e depois forjar o webhook seguinte, é a T01 contada como história. Casos de abuso
repetem ameaças com frequência, e tudo bem: a repetição é a mesma falha descrita nas palavras da
funcionalidade que ela quebra, que é o que um dono de produto precisa ver antes de decidir onde ela
entra no backlog.
