---
title: Uma cadeia de filtros, cada um nomeado no veredito
version: 1
---

Cada aula anterior construiu uma verificação: dados pessoais na aula 21, moderação na aula 16, schemas e
lista de hosts na aula 19. A tentação é escolher a melhor e confiar nela. **Cada uma tem um ponto cego
que outra cobre**, e a defesa prática é pô-las em fila, para que uma resposta só chegue ao cliente depois
de todas a aprovarem. Isso costuma se chamar defesa em profundidade, e a única coisa nova de que precisa é
uma ordem e o registro de qual camada decidiu.

O `guard filter` passa quatro camadas sobre uma resposta, nesta ordem: dados pessoais e segredos, o
marcador canário da última seção, moderação em 0.5, e a lista de hosts. As respostas foram **escritas
pelo curso**; nenhum modelo as produziu.

```
ana@lab:~/guard$ cat data/pipeline-outputs.jsonl
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl
layers: personal-data -> canary -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  BLOCK system prompt marker CANARY-7F3A-TAREFA in the reply: ALERT
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

Duas de seis passam. Cada bloqueio nomeia a camada, e o nome é o que torna a cadeia manutenível: uma
reclamação sobre uma resposta bloqueada vai à camada que a bloqueou, e quem lê o log distingue um falso
positivo da moderação de um CPF que estava mesmo lá.

## A ordem é uma decisão

Uma resposta é parada pela primeira camada que objeta, então a ordem decide qual motivo fica registrado e
o que as camadas seguintes chegam a ver. Três regras resolvem isso na Tarefa:

- **As camadas que indicam um incidente vão primeiro.** Um CPF numa resposta, ou o marcador do prompt de
  sistema, pode exigir que uma pessoa aja, e o registro precisa dizer isso mesmo que a moderação também
  fosse bloquear.
- **Barato antes de caro.** As verificações de padrão rodam em microssegundos; um endpoint de moderação é
  uma chamada de rede que custa dinheiro. Uma resposta já bloqueada não precisa ser pontuada.
- **A mesma cadeia em todo caminho.** Uma resposta que chega ao cliente por uma segunda rota, como um
  resumo por e-mail, passa pelas mesmas camadas, ou essa rota vira o desvio de todas elas.

## O que cada camada não vê

| camada | pega | deixa passar |
|---|---|---|
| dados pessoais | formatos com aritmética: CPF, cartão, telefone, e-mail, chaves | nomes, endereços, tudo o que é escrito em palavras (aula 21) |
| canário | o prompt de sistema repetido palavra por palavra | as mesmas instruções parafraseadas (esta aula) |
| moderação | as palavras que o classificador aprendeu | ironia, truques de grafia, outros idiomas (aula 16) |
| lista de hosts | links para hosts que ninguém aprovou | uma página nociva num host aprovado |

Ler a tabela descendo a última coluna é o ponto: nenhuma das perdas é coberta pela mesma camada, e
algumas não são cobertas por nenhuma, e é por isso que uma pessoa ainda lê uma amostra do que passa, além
do que é bloqueado.
