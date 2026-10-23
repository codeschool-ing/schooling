---
title: O que os papéis não respondem
version: 1
---

Um papel responde a *este tipo de pessoa pode fazer este tipo de coisa?* Sobram três perguntas, e
cada uma é um lugar comum de quebra do controle de acesso depois que os papéis estão certos.

### Qual registro?

A carla pode ler notas clínicas. Pode ler as de **todo** paciente? Numa rede de quatro clínicas, uma
fisioterapeuta atende os pacientes da sua clínica, ou da sua agenda. A rota
`/patients/<name>/notes` tira o paciente do endereço, e o decorador nunca olha para ele. **Uma
verificação de papel mais uma de posse** é o formato da maioria das regras reais, e a metade da posse
é a esquecida com mais frequência, porque a verificação de papel faz a rota parecer protegida. A
aula 13 trata exatamente disso, do lado do paciente.

### Por qual caminho?

Todo caminho de entrada precisa da mesma verificação. Uma rota que mostra as notas em HTML e outra
que as devolve em JSON para o aplicativo são duas rotas; uma exportação, uma busca e um painel de
"atividade recente" também mostram notas. **O dado vaza pela porta lateral**: a rota das notas está
trancada e o resultado da busca cita a primeira linha de toda nota. O teste de negar por padrão pega
uma rota sem regra; não consegue pegar uma rota com regra generosa demais. Revise cada caminho novo
para o mesmo dado contra a tabela da seção anterior.

### Quem mudou o quê?

As rotas mais sensíveis são as que mudam quem pode fazer o quê: conceder um papel, redefinir a senha
de alguém, desativar uma conta. Três hábitos valem para elas além da verificação de papel.

- **Registre quem agiu.** Toda mudança administrativa grava quem a fez, quando e o que mudou, num log
  que ninguém consegue editar. A aula 15 a põe entre os eventos de segurança que merecem uma linha.
- **Encerre as sessões afetadas.** Um papel retirado do bruno vale agora, não quando a sessão dele
  expirar, como disse a aula 10.
- **Recuse a mudança em si mesmo** onde importa. Um administrador que consegue se dar qualquer papel
  tem todos os papéis; uma segunda pessoa aprovando a concessão é a resposta habitual numa equipe
  grande o bastante para ter uma.

### Onde as verificações dão errado nos frameworks

O Flask deixa as verificações com você, e por isso esta aula pôde mostrá-las como código simples.
Frameworks maiores oferecem sistemas de permissão, e as mesmas três regras valem para eles. A falha
mais comum é um sistema de permissão configurado para as views e não para uma API acrescentada depois
ao lado delas, ou para o painel de administração ligado por padrão. **Seja qual for o framework, o
teste da quarta seção vai junto**: liste toda rota que a aplicação serve, e falhe em qualquer uma que
não declare quem pode usá-la.
