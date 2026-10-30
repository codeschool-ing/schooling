---
title: Rotação, e quem de fato muda a senha
version: 1
---

**A rotação no Secret Manager é um lembrete, não uma ação.** Quando chega `next_rotation_time`, o Secret Manager
publica uma mensagem com o tipo de evento `SECRET_ROTATE` no tópico do segredo, avança `next_rotation_time` em
`rotation_period`, e não faz mais nada. A senha fica igual até algo assinante do tópico mudá-la. Esta seção vem da
documentação do Google; nada nela foi executado.

## O job de rotação, passo a passo

O job da loja é uma função do Cloud Run assinante de `shop-secret-rotation`. Para a senha do banco ele faz quatro
coisas, numa ordem escolhida para nada quebrar no meio:

1. **Criar a senha nova no banco**, como segunda credencial do mesmo usuário, ou como usuário novo com as mesmas
   permissões, enquanto a antiga ainda funciona.
2. **Acrescentá-la como versão nova** de `shop-db-password`. Daí em diante, `latest` é a senha nova.
3. **Esperar** até toda instância a pegar: o arquivo montado muda, e a API reconecta com o valor novo na próxima
   vez que uma conexão falhar ou for reciclada.
4. **Revogar a senha antiga** no banco, e **desabilitar** a versão antiga no Secret Manager. Destruí-la uma semana
   depois, quando nada a tiver pedido.

A ordem é o desenho inteiro. Revogar primeiro (o passo 4 antes do 2) quebra toda instância em execução de uma vez;
pular a espera quebra as instâncias que não recarregaram. **Desabilitar antes de destruir** pelo mesmo motivo: uma
versão desabilitada de que alguém ainda precisava pode ser reabilitada em segundos, e uma destruída não.

## O acesso é auditado

Todo acesso a uma versão é registrado no Cloud Audit Logs como entrada de acesso a dados, quando o log de acesso a
dados está ligado para o Secret Manager: que conta leu que versão, quando. É assim que "quem leu a senha do banco no
mês passado?" tem resposta, e assim que uma versão que ninguém leu em trinta dias pode ser destruída com confiança.
Um alerta baseado em log (lição 10) para acesso de qualquer conta que não seja a da própria API transforma esse
registro numa notificação.

## Quando um segredo vazou

Uma senha achada num log, num repositório ou num chat é tratada como conhecida por todos, pense-se o que for da
chance. Os passos são a rotação acima, rodada agora em vez de no prazo: uma versão nova, as instâncias recarregadas,
a senha antiga revogada no banco e a versão dela desabilitada. Tirar a senha de onde ela vazou vem depois, e não
substitui nada disso: o histórico de um repositório, a retenção de um bucket de log e a busca de um chat guardam
cópias muito depois de a linha ser apagada.
