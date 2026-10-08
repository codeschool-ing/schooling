---
title: O sistema que este curso modela
version: 1
---

Um modelo de ameaças de sistema nenhum em particular ensina o vocabulário e nada mais, então todas
as aulas deste curso trabalham sobre o mesmo sistema. A **Vereda Fisioterapia** é uma pequena rede
de quatro clínicas de fisioterapia em São Paulo, inventada para este curso e para o curso
`cryptography` antes dele. Cerca de nove mil pacientes têm conta no portal, e as clínicas fazem
umas 1.800 sessões por semana.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-portal\" aria-label=\"Um esboço do portal do paciente da Vereda, antes de qualquer notação. Pacientes chegam ao portal pela internet; a equipe das clínicas usa um console separado, de dentro das clínicas. Os dois leem e escrevem no banco de prontuários, e os dois chegam aos arquivos de exames, onde ficam os PDFs enviados. Um worker de lembretes lê do banco as consultas de amanhã e pede a um provedor de SMS que mande uma mensagem. O portal cobra as sessões por um gateway de pagamento, que responde com um webhook.\"><rect x=\"20.0\" y=\"40.0\" width=\"130.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pacientes</text><text x=\"85.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(navegador, celular)</text><rect x=\"20.0\" y=\"240.0\" width=\"130.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">equipe da clínica</text><text x=\"85.0\" y=\"268.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(recepção, fisios)</text><rect x=\"250.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">portal</text><text x=\"320.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">portal.vereda.example</text><rect x=\"250.0\" y=\"240.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">console da equipe</text><rect x=\"470.0\" y=\"140.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">banco de</text><text x=\"530.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prontuários</text><rect x=\"470.0\" y=\"240.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos</text><text x=\"530.0\" y=\"268.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de exames</text><rect x=\"470.0\" y=\"40.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">worker de</text><text x=\"530.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lembretes</text><rect x=\"610.0\" y=\"40.0\" width=\"100.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor</text><text x=\"660.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de SMS</text><rect x=\"250.0\" y=\"140.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gateway de</text><text x=\"320.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pagamento</text><path d=\"M150.0 62.0 L250.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 262.0 L250.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M320.0 84.0 L320.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 62 L430 62 L430 150 L470 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 262 L430 262 L430 172 L470 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 252.0 L470.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390 74 L415 74 L415 280 L470 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M530.0 84.0 L530.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M590.0 62.0 L610.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">A aula 2 transforma este esboço num diagrama de fluxo de dados.</text></svg>", "caption": "O portal da Vereda como alguém o desenharia num quadro branco. Todas as aulas do curso modelam este sistema.", "same": ["portal", "portal.vereda.example"]}
```

### O que ele faz

- **Pacientes** entram em `portal.vereda.example`, marcam e cancelam sessões, pagam por Pix ou
  cartão e enviam os PDFs dos exames que o médico pediu: um laudo de raio X, uma ressonância.
- A **equipe das clínicas** (recepcionistas e fisioterapeutas) usa um **console da equipe**
  separado, em `console.vereda.example`. As recepcionistas cuidam da agenda; os fisioterapeutas
  leem os exames e escrevem as anotações clínicas depois de cada sessão.
- Um **worker de lembretes** roda toda noite, lê os agendamentos do dia seguinte e pede a um
  **provedor de SMS** que mande um lembrete a cada paciente.
- Um **gateway de pagamento** recebe o dinheiro. Quando um pagamento é confirmado, o gateway chama
  o portal de volta com um webhook, e o portal marca o agendamento como pago.
- O **banco de prontuários** guarda contas, agendamentos e anotações clínicas. Os **arquivos de
  exames** ficam num armazenamento de objetos ao lado dele.

### O que você já sabe sobre ele

Quatro fatos contados por quem o construiu, aos quais as aulas vão voltar:

1. O portal e o console da equipe rodam na conta de nuvem da Vereda e respondem pela internet. O
   console deveria ser alcançável só pela rede das clínicas.
2. O banco e o armazenamento de arquivos ficam numa rede privada dentro da mesma conta de nuvem.
3. O worker de lembretes se conecta ao banco com a senha do dono do banco, porque foi a senha que
   funcionou no dia em que ele foi escrito.
4. O handler do webhook marca um agendamento como pago quando um pedido diz isso. Ninguém
   verificou se ele confere que o pedido veio do gateway.

Essa lista já contém ameaças. A aula 2 desenha o sistema direito, a aula 3 acha o que pode dar
errado com ele, e até a aula 12 cada um desses fatos terá sido corrigido ou terá uma decisão
assinada dizendo por que não foi.

### As pessoas

Quatro pessoas da Vereda aparecem nos exemplos, e os papéis importam mais que os nomes:

| | papel | o que sabe |
|---|---|---|
| ana | desenvolvedora, escreveu a maior parte do portal | o código, e onde estão os atalhos |
| bruno | operações, meio período | a conta de nuvem, as redes, os backups |
| carla | consultora de segurança, dois dias por mês | as ameaças, e como outros sistemas se machucaram |
| daniel | cuida da operação das clínicas | o que o negócio aguenta, e o que não aguenta |

daniel está na lista de propósito. Decidir quais riscos a Vereda aceita é uma decisão de negócio,
e a aula 12 trata de fazer quem é dono dela assiná-la.
