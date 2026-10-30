---
title: Agindo, com o dono
version: 1
---

**Achar é a metade fácil. Agir com segurança tem quatro passos, e a loja aprendeu o segundo numa quinta-feira.**

1. **Ache o dono.** Pela tag, pelo `Caller` do deploy que criou o recurso no activity log (lição 21), ou perguntando no canal da equipe.
   Três dos quatro recursos ociosos não tinham tag `team`; `rg-test-ana` é uma pista, e o activity log confirma quem o criou.
2. **Confira contra o calendário da carga, não só a última quinzena.** A `vm-reports` fica ociosa 28 dias e é essencial em 2. O incidente
   da lição 15 foi um banco redimensionado à mão numa tarde que parecia calma e não era. Uma mudança de tamanho passa pela mesma revisão,
   a mesma esteira e o mesmo canário de qualquer outra mudança; o tamanho vai para o Bicep, não para o portal.
3. **Prefira a ação reversível.** Pare uma VM antes de apagá-la; tire um snapshot de um disco antes de apagá-lo; programe a `vm-reports`
   para ligar no dia 28 e desligar no dia 2 em vez de apagá-la. Uma VM desalocada para de pagar computação e mantém os discos.
4. **Anote o que foi economizado**, com o antes e o depois da exportação de custos da lição 24. Um redimensionamento que ninguém mediu é
   um boato, e o próximo é mais fácil de defender quando o último tem um número.

Para a loja, as decisões saíram assim: snapshot e deleção dos dois discos, deleção do `pip-test` e do `asp-shop-old` depois que os donos
concordaram, `vm-shop-batch` de oito vCPUs para duas pela esteira. E a `vm-reports` vai para um horário de liga e desliga com o Hybrid Benefit
ligado, da lição 22. Nenhuma dessas mudanças foi feita, porque nenhum desses recursos existe fora deste curso.
