---
title: Enviar o que a finalidade precisa, e um marcador para o resto
version: 1
---

O princípio da necessidade é fácil de aceitar e difícil de aplicar à mão: quem constrói o recurso de
resumo envia o ticket inteiro, porque o ticket inteiro é o que o código tem, e decidir campo a campo
é trabalho de outra pessoa. **O jeito de aplicá-lo é escrever a finalidade como a lista dos campos
de que ela precisa**, para que um campo que ninguém listou fique de fora sem que alguém precise
lembrar dele. No `~/guard` essa lista é o `purposes.json`:

```
ana@lab:~/guard$ cat data/purposes.json
{
 "summarise-dispute": {
  "what": "a summary of the dispute for the support agent, and a draft reply to the client",
  "needs": [
   "ticket",
   "job.title",
   "job.price_cents",
   "job.due",
   "messages"
  ],
  "pseudonymise": [
   "client.name",
   "freelancer.name"
  ]
 }
}
```

`needs` é o que o resumo precisa ler. `pseudonymise` é aquilo sobre o que ele precisa *falar* sem
conhecer: o resumo tem de dizer que o cliente e a freelancer discordam, e não precisa dos nomes para
dizer isso.

## A ferramenta recusa primeiro

O `guard minimise` aplica a finalidade ao ticket. Na primeira execução ele não grava nada:

```
ana@lab:~/guard$ guard minimise data/ticket-4471.json --purpose summarise-dispute; echo "exit $?"
purpose    summarise-dispute: a summary of the dispute for the support agent, and a draft reply to the client
kept       ticket, job.title, job.price_cents, job.due, messages
dropped    opened, client.cpf, client.email, client.phone, client.birth_date, client.address, freelancer.cpf, freelancer.pix_key, job.id
renamed    client.name -> <NAME_1>, freelancer.name -> <NAME_2>
sensitive  messages[1]: health (hospital, infection)  HOLD
in text    <NAME_2> x1, <PHONE_1> x1
NOTHING WRITTEN: sensitive data in the text. Remove it with --sensitive remove, or record the legal basis that allows sending it (LGPD art. 11) and change the purpose.
exit 3
ana@lab:~/guard$ ls outbox vault 2>&1
ls: cannot access 'outbox': No such file or directory
ls: cannot access 'vault': No such file or directory
```

Leia o relatório de cima para baixo. `kept` é a lista da finalidade. `dropped` é todo o resto, nove
campos nomeados um a um: os dois CPFs, o e-mail, o telefone, a data de nascimento e o endereço do
cliente, a chave Pix, o id do trabalho e a data de abertura do ticket. `renamed` trocou os dois nomes
por marcadores. `in text` é o texto livre: o cliente escreveu o primeiro nome da Juliana numa
mensagem e o próprio telefone em outra, e os dois também viraram marcadores.

**Os nomes nas mensagens puderam ser achados porque o ticket diz quais são.** A aula 21 mostrou que
nenhum padrão acha um nome em texto livre. Aqui os campos estruturados trazem `Marcos Teixeira` e
`Juliana Prado`, então a ferramenta sabe quais palavras procurar, primeiros nomes inclusive. Uma
terceira pessoa citada só numa mensagem, um advogado ou um parente, passaria, e esse limite pertence
à mesma frase que o resultado.

Depois vem a linha que o parou: `sensitive messages[1]: health (hospital, infection) HOLD`. O status
de saída é 3, e nem `outbox/` nem `vault/` existem. A próxima seção trata dessa linha. Aqui, use a
opção que ela nomeia:

```
ana@lab:~/guard$ guard minimise data/ticket-4471.json --purpose summarise-dispute --sensitive remove
purpose    summarise-dispute: a summary of the dispute for the support agent, and a draft reply to the client
kept       ticket, job.title, job.price_cents, job.due, messages
dropped    opened, client.cpf, client.email, client.phone, client.birth_date, client.address, freelancer.cpf, freelancer.pix_key, job.id
renamed    client.name -> <NAME_1>, freelancer.name -> <NAME_2>
sensitive  messages[1]: health (hospital, infection)  removed 1 sentence(s)
in text    <NAME_2> x1, <PHONE_1> x1
bytes      909 -> 542
wrote      outbox/TK-4471.json (to the provider), vault/TK-4471.json (stays here)
ana@lab:~/guard$ cat outbox/TK-4471.json
{
 "ticket": "TK-4471",
 "job": {
  "title": "Logo for a bakery",
  "price_cents": 120000,
  "due": "2026-09-10"
 },
 "messages": [
  {
   "from": "client",
   "text": "<NAME_2>, the logo was due on 10 September and I have nothing. I paid R$ 1.200,00."
  },
  {
   "from": "freelancer",
   "text": "[removed: a health matter] I can deliver by Friday."
  },
  {
   "from": "client",
   "text": "I don't care, I want my money back. Call me on <PHONE_1>."
  }
 ],
 "client": {
  "name": "<NAME_1>"
 },
 "freelancer": {
  "name": "<NAME_2>"
 }
}
```

909 bytes viraram 542, e o que foi cortado é o que identificava pessoas. A ordem das chaves mudou,
porque a ferramenta monta a caixa de saída a partir da lista da finalidade; um modelo que lê JSON não
é afetado por isso.

## Os marcadores e o cofre

O segundo arquivo fica na máquina da Tarefa:

```
ana@lab:~/guard$ cat vault/TK-4471.json
{
 "<NAME_1>": "Marcos Teixeira",
 "<NAME_2>": "Juliana Prado",
 "<PHONE_1>": "+55 11 98765-4321"
}
```

O fornecedor recebe `<NAME_1>`; a Tarefa guarda o que `<NAME_1>` significa. Uma resposta que usa os
marcadores pode voltar a usar os nomes. A resposta abaixo **foi escrita pelo curso, não por um
modelo**; ela faz as vezes do que um fornecedor devolveria, para que o último passo tenha sobre o que
trabalhar:

```
ana@lab:~/guard$ cat data/reply-4471.txt
Summary: <NAME_1> paid R$ 1.200,00 for a logo due on 10 September and has received nothing. <NAME_2> says a health matter stopped the work and offers to deliver by Friday. <NAME_1> wants a refund and asked to be called on <PHONE_1>.

Draft reply to the client: Hello <NAME_1>, I'm sorry the logo for your bakery is late. <NAME_2> has offered to deliver it by Friday. If you would rather not wait, answer this message and we will start the refund today.
ana@lab:~/guard$ guard restore vault/TK-4471.json data/reply-4471.txt
Summary: Marcos Teixeira paid R$ 1.200,00 for a logo due on 10 September and has received nothing. Juliana Prado says a health matter stopped the work and offers to deliver by Friday. Marcos Teixeira wants a refund and asked to be called on +55 11 98765-4321.

Draft reply to the client: Hello Marcos Teixeira, I'm sorry the logo for your bakery is late. Juliana Prado has offered to deliver it by Friday. If you would rather not wait, answer this message and we will start the refund today.
```

O atendente lê o texto restaurado, com os nomes e o telefone de volta no lugar, e o fornecedor não
viu nenhum deles. O `guard restore` também acusa um marcador que o cofre não conhece, como um
`<NAME_3>` que um modelo inventou, e sai com status 4 em vez de deixá-lo passar.

## Pseudonimizado não é anônimo

É tentador chamar a caixa de saída de anonimizada, e a lei traça a linha exatamente onde essa
tentação erra. **Dado anonimizado não é dado pessoal** pelo art. 12, mas só enquanto a anonimização
não puder ser revertida com esforço razoável. O cofre reverte esta num único comando, então para a
Tarefa a caixa de saída é *pseudonimizada*, o termo que o art. 13, §4 define: dado que não pode mais
ser associado a uma pessoa sem informação adicional que o controlador guarda separada. Dado
pseudonimizado continua dado pessoal, com todas as obrigações que vêm junto.

Mesmo assim, o que a técnica compra é real. O fornecedor não tem CPF, endereço nem nome, então um
vazamento no fornecedor, ou um fornecedor que guarda os prompts mais do que devia, expõe muito menos.
E o que sobra ainda pode identificar alguém: `TK-4471`, um logo para uma padaria, R$ 1.200,00, 10 de
setembro. Ninguém fora da Tarefa consegue usar o número do ticket, mas numa cidade pequena uma padaria
com o logo atrasado pode ser uma padaria só. Minimizar baixa o risco; não chega a zero, e o cofre
precisa ser apagado quando a retenção do próprio ticket acaba, porque ele é a chave de tudo o que a
caixa de saída escondeu.
