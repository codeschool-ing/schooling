---
title: Um log responde perguntas, e cada pergunta tem um prazo
version: 1
---

O ponto de partida comum é registrar cada chamada inteira e guardar, porque disco é barato e
ninguém depura uma resposta que foi jogada fora. A primeira metade está certa. A segunda trata o log
como um artefato técnico, e **um log de prompts é um depósito do que os seus usuários digitaram**,
inclusive coisas que eles nunca deveriam ter digitado e que você nunca pediu.

O laboratório desta aula é o `~/guard`, montado pelo `bash lab.sh reset` a partir do diretório do
curso. Ele guarda o log de chamadas do assistente da Tarefa, um marketplace brasileiro inventado onde
clientes contratam freelancers. Todo registro ali, prompts e respostas, foi escrito pelo curso;
nenhum modelo os produziu. Eis um, do último dia do log:

```
ana@lab:~/guard$ head -1 logs/raw/2026-09-29.jsonl
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
```

Ninguém pediu ao cliente o e-mail nem o CPF. Ele ofereceu os dois, porque uma caixa de chat convida
a isso, e o log guardou os dois porque guarda tudo.

## Comece pelas perguntas

Um log se paga respondendo perguntas. Quatro aparecem em quase toda equipe que roda um modelo em
produção, e cada uma precisa de uma parte diferente do registro:

| pergunta | o que ela exige | por quanto tempo |
|---|---|---|
| por que o assistente disse *aquilo* a este cliente? | o prompt e a resposta palavra por palavra, o modelo, o id da requisição | até a reclamação poder chegar: dias ou semanas |
| alguém está abusando do assistente? | a conta, o horário, texto suficiente para reconhecer o padrão | a duração de uma investigação |
| as respostas estão piorando? | muitos exemplos de prompts e respostas, mas não quem os escreveu | meses, para comparar duas versões |
| quanto isto custa, e está ficando lento? | contagens: chamadas, tokens, milissegundos | anos, para tendências e orçamento |

**O texto é o que torna um registro perigoso, e quem precisa dele são as perguntas de vida mais
curta.** A pergunta de custo não precisa de texto nenhum. A de qualidade precisa de texto, mas não
de identidade. Só a depuração e o abuso precisam dos dois, e os dois tratam de fatos recentes.

Esse é o argumento inteiro a favor de **camadas**: a mesma chamada gravada em depósitos separados,
cada um com o que um tipo de pergunta exige e cada um com o seu limite. O laboratório tem três:

```
ana@lab:~/guard$ ls logs
metrics
raw
redacted
ana@lab:~/guard$ head -1 logs/metrics/2026-09-29.jsonl
{"day": "2026-09-29", "surface": "chat", "calls": 2, "in_tokens": 845, "out_tokens": 89, "ms_max": 1090}
ana@lab:~/guard$ cat retention.json
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
```

A linha de métricas responde à pergunta de custo de 29 de setembro e não contém nada sobre ninguém.
Ela pode ser guardada por dois anos, mostrada num painel e enviada a um fornecedor de monitoramento
sem mais cuidado. A linha bruta não pode ser tratada assim.

## O que o registro deveria trazer e este não traz

Olhe de novo o registro bruto pensando na depuração. Ele nomeia o modelo, mas não a versão das
instruções que o assistente estava seguindo. **Uma resposta não se explica sem o prompt de sistema
que a produziu**, e o prompt de sistema muda mais do que o modelo. Registrar o texto inteiro dele em
cada chamada repete os mesmos milhares de tokens milhões de vezes; registrar um identificador de
versão, com os prompts guardados em controle de versão, custa poucos bytes.

O mesmo vale para tudo o que é idêntico entre chamadas: as definições de ferramentas, os parâmetros
de busca, a temperatura. Registre uma referência à configuração e guarde a configuração uma vez.

## O que nenhuma camada pode guardar

Algumas coisas não são questão de prazo. O código de segurança de um cartão é o caso mais claro: o
PCI DSS, o padrão que as bandeiras impõem a quem lida com dados de cartão, proíbe guardá-lo depois
que o pagamento foi autorizado, de qualquer forma, criptografado ou não. Um cliente que o digita num
chat de suporte o entregou ao log, e nenhum limite de retenção torna aceitável guardá-lo. O mesmo
vale para credenciais: uma chave de API colada num chat precisa ser revogada pelo dono, e um log que
a guarda está guardando uma chave que funciona.

O assistente da Tarefa responde do jeito certo a uma chave colada, e o log mostra por que essa
resposta é necessária. O `guard redact`, assunto da próxima seção, imprime um registro com o que ele
reconhece substituído:

```
ana@lab:~/guard$ guard redact logs/raw/2026-06-02.jsonl
rq-0008  prompt  The integration keeps failing. Here's my key so you can test: [SECRET]
         output  Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.
```

A camada bruta ainda tem a própria chave, por trinta dias. A redação protege as cópias que vivem
mais; ela não desfaz a colagem, e é por isso que a resposta pede que a chave seja revogada em vez de
prometer esquecê-la.

**Toda camada é dado pessoal enquanto puder ser ligada a uma pessoa.** Pela LGPD, que a aula 12
aplica às chamadas de modelo, a camada com redação ainda nomeia uma conta, e uma conta é uma pessoa.
Um cliente que pede a exclusão dos dados dele está perguntando sobre os logs também. As camadas
tornam esse pedido mais barato de atender; não tiram os logs do alcance dele.
