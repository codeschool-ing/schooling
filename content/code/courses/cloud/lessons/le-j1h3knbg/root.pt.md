---
title: O dono da conta, e por que ele fica na gaveta
version: 1
---

Toda conta de nuvem começa com uma identidade: o e-mail e a senha que a abriram. A AWS a chama de
**usuário root**. Ele pode fazer tudo na conta, e nenhuma política de permissões dentro da conta
consegue limitá-lo, porque políticas são a forma de a conta limitar suas identidades e o root é a
única para a qual elas não foram escritas. Tudo o que esta lição monta é um conjunto de freios, e o
root é a identidade que não tem nenhum.

## "Só tem eu aqui, então vou usar o root"

Essa é a imagem comum, e ela é razoável na primeira tarde: uma pessoa, uma conta, uma senha. Ela dá
errado de três jeitos que não têm nada a ver com quantas pessoas existem.

**Um erro não tem teto.** Toda sessão aberta como root é uma sessão em que um clique errado, um script
rodado no terminal errado ou um cookie de navegador roubado podem fazer qualquer coisa, inclusive
encerrar a conta. Uma identidade com direitos de administrador é quase tão forte, mas pode ser
limitada, observada e removida; o root só pode ser protegido.

**O log não distingue as pessoas.** O log de auditoria (a última seção de leitura desta lição)
registra a identidade que fez cada chamada. No dia em que uma segunda pessoa entra e recebe a mesma
senha, toda entrada diz "root", e a pergunta "quem apagou o banco de dados na terça" não tem resposta
que o log possa dar.

**O dono também é o caminho de volta.** Algumas tarefas precisam do usuário root e de mais nada.
Encerrar a conta é uma; outra é remover uma política de bucket escrita para negar a todos, que deixou
todas as identidades de fora, administradores incluídos. Se o root é a identidade do dia a dia, a
senha e o segundo fator dele ficam nos mesmos lugares, e o mesmo vazamento perde a conta e o jeito de
recuperá-la.

## O que fazer com ele

Ponha-o numa gaveta, e faça uma gaveta boa:

- uma senha longa e aleatória guardada num gerenciador de senhas, nunca digitada de memória;
- um segundo fator nele — uma chave de segurança física se você tiver, um app autenticador se não;
- nenhuma chave de acesso para o root, nunca; se a conta tiver alguma, apague. Uma chave do root é uma
  senha sem segundo fator, utilizável de qualquer lugar, para tudo;
- o e-mail da conta apontando para uma caixa que a organização controla, como um endereço
  compartilhado `cloud-owner@`, e não a caixa de uma pessoa, para que ele sobreviva à saída dela.

Depois crie a identidade com que você realmente trabalha, que é o assunto das duas seções seguintes.
Se o trabalho precisa de direitos totais, dê direitos totais a essa identidade; ainda é melhor que o
root, porque ela pode ser limitada depois, aparece no log com o próprio nome, e removê-la não remove
a conta.

A mesma forma existe em todo provedor com outro nome, embora nenhum deles seja exatamente o mesmo
objeto que o root. No Google Cloud é o superadministrador do Google Workspace ou do Cloud Identity da organização; no Azure, a
função de Administrador Global no Microsoft Entra ID. Numa organização com muitas contas AWS também
existe um jeito de pôr limites acima do usuário root de cada conta-membro, a partir da organização que
é dona dela. Esse é o assunto do `aws-foundations`, e não muda o conselho: o usuário root é para as
poucas coisas que só ele faz.
