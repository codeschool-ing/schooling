---
title: Os requisitos do portal
version: 1
---

A ana e a carla escreveram os requisitos numa tarde, ameaça por ameaça, com o daniel respondendo às
perguntas que eram decisões e não engenharia. Quantos logins falhos são demais, de que tamanho um
exame pode ser, por quanto tempo uma conta da equipe sem uso pode ficar aberta.

| id | ameaças | requisito | verificado por |
|---|---|---|---|
| R01 | T01 | O portal só aceita um webhook de pagamento quando a assinatura do gateway sobre o corpo é válida. | teste |
| R02 | T01 | O portal só marca um agendamento como pago quando o valor e o agendamento do webhook batem com uma cobrança em aberto. | teste |
| R03 | T02 | O login do paciente permite no máximo 10 tentativas falhas por conta por hora. | teste |
| R04 | T02 | O cadastro e a troca de senha recusam senhas que aparecem em listas conhecidas de vazamentos. | teste |
| R05 | T03 | O login da equipe exige segundo fator toda vez. | teste |
| R06 | T15 | Uma conta da equipe sem uso por 30 dias é desativada automaticamente. | teste |
| R07 | T04 | A credencial de armazenamento do portal cria arquivos de exames e não consegue sobrescrevê-los nem apagá-los. | revisão |
| R08 | T05 | Toda mudança numa anotação clínica é guardada como versão nova, com autor e horário. | teste |
| R09 | T06 | Todo cancelamento registra a conta que o fez e quando. | teste |
| R10 | T07 | O portal devolve um exame só ao paciente a quem ele pertence e responde a qualquer outro pedido como se o exame não existisse. | teste |
| R11 | T08 | Um lembrete contém só a data, o horário e como cancelar. | revisão |
| R12 | T09 | O papel de recepcionista não abre anotações clínicas nem exames. | teste |
| R13 | T10 | Um upload maior que 20 MB ou que não seja PDF é recusado. | teste |
| R14 | T11 | Uma conta dispara no máximo 5 lembretes por dia. | ainda não |
| R15 | T12 | O console da equipe só responde a pedidos vindos da rede das clínicas. | revisão |
| R16 | T13 | A conta de banco do worker de lembretes lê agendamentos e nada mais. | revisão |
| R17 | T16 | Pacientes veem as sessões abertas e conseguem encerrar qualquer uma. | ainda não |
| R18 | T16, T17 | Entrar de um dispositivo novo ou mudar o telefone manda um e-mail ao paciente. | teste |
| R19 | T17 | Mudar o telefone exige um código mandado ao número antigo. | teste |

Dezenove requisitos para dezessete ameaças, e vale notar quatro coisas na lista.

**A T14 não tem nenhum.** O PDF preparado que ataca o visualizador num computador da clínica precisa
de um visualizador novo ou de uma regra de que a equipe nunca baixe exames, e nenhuma das duas coisas
pôde ser decidida numa tarde. A ameaça fica na lista sem requisito, o que é permitido, e a aula 12 é
onde ela recebe uma decisão com nome e data.

**Dois requisitos ainda não têm verificação.** O R14 limita lembretes e o R17 mostra ao paciente as
sessões abertas. Os dois são claros e testáveis; ninguém escreveu o teste, porque nenhuma das duas
funcionalidades existe ainda. Dizer "ainda não" na coluna é o estado honesto, e é o que uma aula
seguinte consegue conferir que mudou.

**Quatro são verificados por revisão, não por teste.** R07, R11, R15 e R16 tratam de uma permissão
de armazenamento, de um modelo de mensagem, de uma regra de rede e de uma conta de banco. Um teste
unitário no código do portal não enxerga nenhum deles. Uma revisão é mais fraca que um teste, porque
acontece quando alguém lembra de fazer, e a aula 15 transforma algumas delas em verificações que
rodam a cada mudança.

**O R02 veio de uma dependência, não do STRIDE.** A conferência do valor existe porque a aula 6
perguntou o que acontece se o próprio gateway for comprometido. Ela cobre a T01 de um jeito que a
assinatura não cobre, e teria passado despercebida num modelo que só perguntasse sobre o remetente
do webhook.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l08-verified-by\" aria-label=\"Como os 19 requisitos são verificados. Por teste: 13. Por revisão: 4, R07, R11, R15, R16. Ainda não: 2, R14 e R17.\"><rect x=\"40.0\" y=\"50.0\" width=\"442.0\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"261.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um teste: 13</text><text x=\"261.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R01, R10, R13 …</text><rect x=\"490.0\" y=\"50.0\" width=\"136.0\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma revisão: 4</text><text x=\"558.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R07 R11 R15 R16</text><rect x=\"634.0\" y=\"50.0\" width=\"68.0\" height=\"50.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ainda não: 2</text><text x=\"668.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R14 R17</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">“ainda não” escrito é o estado honesto; um branco seria lido como feito</text></svg>", "caption": "A maioria dos requisitos pode ser testada a cada mudança. Os de redes e permissões de nuvem precisam de uma pessoa, e dois ainda não precisam de ninguém."}
```

### Guardados no repositório

A tabela mora em `requirements.csv`, ao lado do `threats.csv`, em inglês, com as mesmas colunas. A
coluna `threats` cita um ou mais ids de ameaça separados por espaço, que é a ligação que a próxima
seção usa. Um `verified by` vazio é como "ainda não" fica escrito:

```
(.venv) ana@vm:~/tm/portal-model$ cat requirements.csv
id,threats,requirement,verified by
R01,T01,The portal accepts a payment webhook only when the gateway's signature over its body verifies.,test
R02,T01,The portal marks a booking paid only when the webhook's amount and booking match an open charge.,test
R03,T02,Patient sign-in allows at most 10 failed attempts per account per hour.,test
R04,T02,Sign-up and password changes refuse passwords found in known breach lists.,test
R05,T03,Staff sign-in requires a second factor every time.,test
R06,T15,A staff account unused for 30 days is disabled automatically.,test
R07,T04,The portal's storage credential can create exam files and cannot overwrite or delete them.,review
R08,T05,Every change to a clinical note is kept as a new version with its author and time.,test
R09,T06,Every cancellation records the account that made it and when.,test
R10,T07,The portal returns an exam only to the patient it belongs to and answers any other request as if it did not exist.,test
R11,T08,A reminder text contains only the date and time and how to cancel.,review
R12,T09,The receptionist role cannot open clinical notes or exams.,test
R13,T10,An upload larger than 20 MB or not a PDF is refused.,test
R14,T11,An account triggers at most 5 reminder messages a day.,
R15,T12,The staff console answers only requests from the clinics' network.,review
R16,T13,The reminder worker's database account can read bookings and nothing else.,review
R17,T16,Patients see their open sessions and can end any of them.,
R18,T16 T17,Signing in from a new device or changing the phone number sends the patient an e-mail.,test
R19,T17,Changing the phone number needs a code sent to the old number.,test
```
