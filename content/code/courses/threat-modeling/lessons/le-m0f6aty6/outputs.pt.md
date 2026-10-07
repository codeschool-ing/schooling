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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l06-minimise\" aria-label=\"Duas saídas, cada uma levando um item a mais do que precisa. A cobrança mandada ao gateway leva o valor, o id do agendamento, o nome e o CPF; o CPF é o item de que ela não precisa. O lembrete mandado ao provedor de SMS leva o telefone, o primeiro nome, o horário e a clínica; o nome da clínica é o item que revela o tratamento, a T08.\"><text x=\"20.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cobrança ao gateway</text><rect x=\"20.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">valor</text><rect x=\"170.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">id do agendamento</text><rect x=\"320.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nome</text><rect x=\"470.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">CPF</text><text x=\"620.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">não precisa</text><text x=\"20.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lembrete ao provedor de SMS</text><rect x=\"20.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">telefone</text><rect x=\"170.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primeiro nome</text><rect x=\"320.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">horário</text><rect x=\"470.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">clínica (T08)</text><text x=\"620.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">não precisa</text><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">mandar o mínimo que faz o trabalho</text></svg>", "caption": "Todo item além do que o trabalho pede é superfície que não compra nada, e numa clínica normalmente é dado pessoal.", "same": ["CPF"]}
```
