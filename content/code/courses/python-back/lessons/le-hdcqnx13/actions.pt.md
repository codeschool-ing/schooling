---
title: Ações: fazer algo com as linhas que você marca
version: 1
---

A página de lista tem um menu de **ações**, e todo modelo começa com uma, *Delete selected*. Uma ação
é uma função que recebe as linhas marcadas na página como um QuerySet e faz algo com elas. Quem
organiza quer a lista de inscritos numa planilha, então o agenda tem uma que responde com um arquivo
CSV: `registrations_csv` no arquivo do admin, listada em `EventAdmin.actions`.

A página manda um POST com o nome da ação e os ids das linhas marcadas; o curl manda o mesmo, marcando
o Django Night e o Testing dojo:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -s -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&action=registrations_csv&_selected_action=1&_selected_action=3" http://127.0.0.1:8000/admin/events/event/
event,name,email,registered
django-night,Bruno,bruno@example.org,2026-10-16T23:11:13.033333+00:00
testing-dojo,Carla,carla@example.org,2026-10-16T23:11:19.992427+00:00
testing-dojo,Davi,davi@example.org,2026-10-16T23:11:19.995688+00:00
```

**O valor de retorno da função é a resposta**, então uma ação pode redirecionar, renderizar uma
página de confirmação ou, como esta, responder com um arquivo. Não devolver nada manda a pessoa de
volta para a lista. A consulta usa o `select_related` da aula 4, então o arquivo custa uma consulta
não importa quantas inscrições liste.

Dois hábitos para ações. Dê a cada uma uma `description`, porque é isso que o menu mostra. E lembre que
**uma ação roda sobre quantas linhas alguém marcar**, talvez todas as linhas da tabela, então uma que
muda dados deve ser rápida e idempotente, ou passar o trabalho para uma tarefa em segundo plano, que
é a aula 13.
