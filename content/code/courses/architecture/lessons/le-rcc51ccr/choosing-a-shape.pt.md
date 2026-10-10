---
title: Que formato para que força
version: 1
---

As aulas 1 a 3 já deram nome a cinco formatos. **Nenhum é o estágio seguinte de outro**; cada um é a
resposta a uma pergunta diferente, e um sistema de verdade costuma misturá-los. A Quitanda poderia
muito bem rodar como um monólito modular para a loja, um serviço de estoque para a equipe do depósito,
e três funções para a cola em volta.

| formato | responde a | custa |
| --- | --- | --- |
| monólito, modular | uma equipe, fronteiras ainda se mexendo, dados que precisam concordar na hora | tudo é implantado e escala junto |
| microsserviços | várias equipes que precisam lançar de forma independente; partes com carga ou necessidades muito diferentes | a rede, falha parcial, nenhuma transação entre serviços, a conta por serviço |
| SOA com barramento | integrar muitas aplicações existentes que não dá para mudar muito | uma equipe e um produto centrais no caminho de toda mudança |
| funções serverless | cola movida a eventos, carga em rajadas ou rara, tarefas agendadas | partidas a frio, limites de tempo de execução, custo por requisição com carga constante, acoplamento a uma plataforma |
| uma service mesh sobre os serviços | as mesmas tarefas de rede repetidas em muitos serviços e linguagens | um proxy por serviço, dois saltos por chamada, um plano de controle para manter |

## Os limites que decidem alguns casos

Funções carregam limites que decidem alguns casos sozinhos. O AWS Lambda, por exemplo, interrompe uma
execução depois de no máximo 15 minutos, e toda plataforma define algum máximo. Uma tarefa que roda por
uma hora não cabe, qualquer que fosse a conta. Uma função não guarda entre chamadas nada em que possa
confiar, então uma conexão WebSocket mantida aberta por minutos, aula 18, pertence a outro lugar. E os
gatilhos, as permissões e a configuração de cada plataforma são só dela, então um sistema feito de
cinquenta funções num provedor é um sistema que só muda para outro provedor com uma reescrita.

## A pergunta a fazer

Para cada parte do sistema, antes de escolher um formato: **que força essa parte sente?** Uma equipe
que precisa lançar sozinha, um padrão de carga, uma necessidade de runtime, uma integração com algo que
não pode mudar. A força escolhe o formato. Quando nenhuma força é nomeada, o formato mais barato que
funciona é o monólito da aula 1, e os doze fatores da aula 4 valem para ele tanto quanto para qualquer
outra coisa.
