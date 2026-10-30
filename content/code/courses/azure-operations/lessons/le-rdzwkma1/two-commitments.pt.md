---
title: Dois jeitos de se comprometer, e o que cada um compra
version: 1
---

**O Azure dá desconto em computação com que você se compromete antes, de dois jeitos que diferem no que te prendem.**

| | **reserva** | **savings plan para computação** |
|---|---|---|
| você se compromete com | um tipo de recurso, família de tamanho e região, como VMs da série D v5 em `brazilsouth` | um valor por hora, em USD, entre serviços de computação e regiões |
| vale para | só o uso que corresponde | qualquer computação elegível: VMs, planos premium do App Service, Container Apps, Functions premium |
| prazo | 1 ou 3 anos | 1 ou 3 anos |
| desconto | o maior dos dois | menor, pela flexibilidade |
| se o uso muda | troca por outra reserva dentro de limites | vale automaticamente para o que estiver rodando |

Os dois são aplicados por hora: **uma hora de compromisso sem uso correspondente se perde**, não passa adiante. Esse é todo o
risco, e é o motivo de a próxima seção medir antes de comprar.

Um compromisso tem um **escopo**: um grupo de recursos, uma assinatura, ou compartilhado na conta de cobrança. O escopo
compartilhado usa horas sem correspondência onde houver uso compatível, o que aumenta o aproveitamento; um grupo de recursos só
mantém o custo onde uma equipe o enxerga. A loja usa escopo compartilhado e a alocação da lição 24 para repassar o custo.

Os dois são comprados, não implantados: são objetos de cobrança, e nenhum foi comprado para este curso. As taxas e porcentagens
desta lição são **ilustrativas**, números redondos de formato plausível, porque a lista de preços estava fora de alcance (a lição
1, seção 03). A Microsoft publica os descontos reais por tamanho e região; eles variam, e uma calculadora com os números reais vem
antes de qualquer compra.
