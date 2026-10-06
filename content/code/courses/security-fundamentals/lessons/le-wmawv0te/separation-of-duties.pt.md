---
title: Segregação de funções
version: 1
---

O menor privilégio limita o que uma conta faz. A **segregação de funções** limita o que uma pessoa faz
sozinha, dividindo uma tarefa sensível de modo que ela precise de duas pessoas para se completar.

O caso clássico é dinheiro. Se a mesma pessoa pode cadastrar um fornecedor novo, aprovar uma nota dele
e mandar o pagamento, uma fraude precisa de uma pessoa desonesta, ou de uma senha roubada. Divida esses
três passos entre duas pessoas e a mesma fraude precisa das duas, o que é bem menos provável, ou de duas
senhas roubadas, que é o dobro do trabalho e o dobro da chance de ser notado.

Na livraria:

| tarefa | primeiro passo | segundo passo |
|---|---|---|
| pagar um fornecedor | o financeiro lança a nota | um dos sócios aprova o pagamento |
| mudar uma regra de firewall | a ana escreve | outra pessoa revisa antes de carregar |
| criar um administrador | a ana cria a conta | os sócios aprovam o pedido por escrito |
| mudar os dados bancários de um cliente para um reembolso | o atendimento registra o pedido | o financeiro confirma com o cliente por telefone |

A última linha é onde acontece muita fraude de verdade. "Por favor, atualizem nossa conta bancária",
num e-mail com cara de fornecedor, é um dos golpes mais comuns contra pequenos negócios, e a defesa não
tem nada de técnico: uma segunda pessoa, um telefone conhecido, uma ligação antes de o dinheiro sair.

### Ideias vizinhas

**Controle duplo**, ou **regra das duas pessoas**, é a forma mais forte: as duas pessoas precisam agir
juntas para a tarefa acontecer, como duas chaves giradas ao mesmo tempo. Bancos usam isso em cofres; a
versão de TI é uma mudança que não pode ir para produção até uma segunda pessoa aprová-la no sistema.

**Quem faz e quem confere** (*maker and checker*) é a forma do dia a dia: uma pessoa prepara, outra
verifica. Um pull request que não pode ser integrado sem revisão é isso embutido numa ferramenta.

**Rodízio de funções** e **férias obrigatórias** vêm do mesmo raciocínio ao contrário. Algumas fraudes
precisam do fraudador presente todo dia para continuar escondidas, e são descobertas poucos dias depois
de outra pessoa assumir o trabalho.

### O que isso custa a uma loja pequena

Com nove pessoas, segregação estrita nem sempre é possível: às vezes só uma pessoa sabe fazer a tarefa.
Aí a segregação vira **detectiva em vez de preventiva**, um controle compensatório nos termos da aula 4.
A ana carrega as mudanças de firewall ela mesma, e toda mudança vai para um log que os sócios leem uma
vez por semana. A segunda pessoa chega depois do fato em vez de antes, o que é mais fraco e ainda muito
melhor que ninguém.
