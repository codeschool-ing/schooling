---
title: Uma chamada de API, lida do jeito que a LGPD lê
version: 1
---

A intuição que a maioria dos desenvolvedores traz é que um fornecedor de modelo é infraestrutura,
como um banco de dados ou uma fila: um lugar por onde o dado passa a caminho de uma resposta, e
portanto algo sobre o que a lei de privacidade tem pouco a dizer. **A LGPD lê do outro jeito.**
Enviar um ticket à API de um fornecedor é tratamento, a palavra da lei para qualquer coisa feita com
dado pessoal, e o art. 5, X lista a transferência e a comunicação entre as operações que ela cobre.
Quem faz é outra empresa, nos computadores dela, e em geral fora do Brasil.

O ticket desta aula é do tipo que uma equipe de suporte gostaria que um modelo resumisse. Como tudo
no `~/guard`, ele foi escrito pelo curso, e as pessoas nele são inventadas:

```
ana@lab:~/guard$ cat data/ticket-4471.json
{
 "ticket": "TK-4471",
 "opened": "2026-09-18",
 "client": {
  "name": "Marcos Teixeira",
  "cpf": "529.982.247-25",
  "email": "marcos.teixeira@example.com.br",
  "phone": "+55 11 98765-4321",
  "birth_date": "1984-02-11",
  "address": "Rua Augusta 1500, ap 32, São Paulo"
 },
 "freelancer": {
  "name": "Juliana Prado",
  "cpf": "111.444.777-35",
  "pix_key": "juliana.prado@example.com"
 },
 "job": {
  "id": "4471",
  "title": "Logo for a bakery",
  "price_cents": 120000,
  "due": "2026-09-10"
 },
 "messages": [
  {
   "from": "client",
   "text": "Juliana, the logo was due on 10 September and I have nothing. I paid R$ 1.200,00."
  },
  {
   "from": "freelancer",
   "text": "Sorry, I was in hospital for a week with a kidney infection and couldn't work. I can deliver by Friday."
  },
  {
   "from": "client",
   "text": "I don't care, I want my money back. Call me on +55 11 98765-4321."
  }
 ]
}
```

Duas pessoas, dois CPFs, um telefone, um endereço, uma data de nascimento, uma chave Pix e uma
internação. A finalidade é um resumo para o atendente e um rascunho de resposta ao cliente, e a
pergunta que o resto da aula responde é quanto disso o resumo precisa.

## Os papéis

A lei classifica as partes desta chamada antes de perguntar qualquer outra coisa:

| | quem | o que a lei espera dele |
|---|---|---|
| **titular** | Marcos e Juliana | direitos sobre os próprios dados, art. 18 |
| **controlador** | a Tarefa, que decide por que e como o ticket é tratado | a base legal, a finalidade, as respostas aos titulares |
| **operador** | o fornecedor do modelo, que trata em nome da Tarefa | tratar só segundo as instruções do controlador, art. 39 |

A tabela vale enquanto o fornecedor fica no papel de operador. **Um fornecedor que usa os prompts
para uma finalidade própria**, como treinar os modelos dele, está decidindo algo sobre o dado que a
Tarefa não instruiu, e decidir a finalidade é o que um controlador faz. Se isso acontece está escrito
nos termos do fornecedor, e para muitos fornecedores numa configuração da conta. Precisa ser lido
antes do primeiro ticket enviado, porque o aviso de privacidade da Tarefa tem de dizer a Marcos e
Juliana quem recebe os dados deles e por quê.

## As quatro perguntas, aplicadas a esta chamada

**É dado pessoal?** O art. 5, I cobre informação sobre pessoa identificada ou *identificável*. Os
CPFs e os nomes são óbvios. As mensagens também: *"Call me on +55 11 98765-4321"* identifica quem
escreveu tão bem quanto um nome.

**Com qual base legal?** O art. 7 lista dez. Para uma disputa entre duas partes do próprio serviço da
Tarefa, a execução de contrato (art. 7, V) é a candidata comum, e o legítimo interesse (art. 7, IX)
outra; a escolhida precisa ser registrada. Uma base cobre uma finalidade, não um recurso: ela não se
estica sozinha para um uso novo do mesmo dado.

**Cada campo é necessário para essa finalidade?** O art. 6 lista os princípios, e dois deles decidem
esta aula: *finalidade*, tratar para um propósito específico e declarado, e *necessidade*, limitar o
tratamento ao mínimo que esse propósito exige. O resumo de um logo atrasado não precisa da data de
nascimento do Marcos. A próxima seção transforma esse princípio num arquivo.

**O dado sai do Brasil?** Se o fornecedor roda o modelo fora do país, enviar o ticket é uma
transferência internacional, e o art. 33 só a permite nos casos que lista: um país que a ANPD
reconhece como de proteção adequada, ou garantias que o controlador oferece, das quais a comum é um
contrato com as cláusulas-padrão da ANPD, publicadas na Resolução CD/ANPD nº 19 de 2024. Onde o
modelo roda faz parte, então, da escolha do fornecedor, junto com o preço e a qualidade.

Há mais uma pergunta na lista, e o ticket responde sim a ela: **algo ali é sensível?** A mensagem da
Juliana fala de hospital e de infecção, e dado de saúde é sensível pelo art. 5, II. Isso muda quais
bases legais estão disponíveis, e tem uma seção própria nesta aula.

*Esta aula lê a lei como ela estava em 2026. A LGPD e os regulamentos da ANPD mudam no ritmo de um
legislativo. Uma decisão sobre dado real é tomada com o texto atual, e com o encarregado da empresa,
a pessoa que a lei exige que o controlador nomeie justamente para essas perguntas (art. 41).*
