---
title: Saídas
version: 1
---

As entradas recebem a atenção porque os ataques chegam por elas. **As saídas são por onde o dado
sai, e um vazamento é uma saída que ninguém pretendia.** Mapeá-las pergunta, para cada fluxo que sai
dos sistemas da Vereda, o que ele leva, quem o recebe, e se ele leva mais do que precisa.

| saída | leva | recebida por | leva mais do que precisa? |
|---|---|---|---|
| páginas para o paciente | os agendamentos, pagamentos e exames do próprio paciente | o navegador do paciente | não, se a verificação de dono da T07 se sustentar |
| cobranças para o gateway | valor, id do agendamento, nome, CPF | o gateway | o CPF (aula 5, vinculação) |
| lembretes para o provedor de SMS | telefone, primeiro nome, horário, clínica | o provedor, depois o celular | o nome da clínica (T08) |
| mensagens de erro | o que o framework imprime numa falha | o navegador que a causou | muitas vezes: um stack trace cita arquivos, versões e consultas |
| logs | detalhes dos pedidos, às vezes o corpo | o serviço de logs, e quem os lê | endereços de e-mail e ids de agendamento em toda linha |
| e-mails mandados pelo portal | confirmações, trocas de senha | o provedor de e-mail do paciente | um link de troca de senha é uma credencial em trânsito |

### Três saídas que não estão no DFD

**Mensagens de erro.** Uma falha que imprime um stack trace no navegador é um ponto de saída levando
a disposição interna do sistema a quem causou o erro, de propósito ou não. O curso `secure-code`
(aula 15) trata do que nunca pode aparecer numa delas; o trabalho do mapa é notar que a saída
existe.

**Logs.** O portal registra todo pedido, e o corpo de um pedido inclui o e-mail do paciente no
login. Logs são guardados por mais tempo que a maioria dos dados, lidos por mais pessoas, e muitas
vezes mandados a um fornecedor. São uma saída com cauda longa.

**Tempo e existência.** Um formulário de login que responde "conta inexistente" mais rápido que
"senha errada" conta a um desconhecido se uma pessoa tem conta na Vereda, o que, numa clínica de
fisioterapia, é o fato de ela ser paciente. Isso também é uma saída, levada pela diferença entre
duas respostas, e não por nenhuma das duas.

### Minimizando

A regra para saídas é curta: **mande o mínimo que faz o trabalho.** Um lembrete precisa de um
horário; uma cobrança precisa de um valor e de uma referência; uma página de erro precisa de um
pedido de desculpas e de um id que o suporte consiga procurar. Tudo além disso é superfície que não
compra nada.
