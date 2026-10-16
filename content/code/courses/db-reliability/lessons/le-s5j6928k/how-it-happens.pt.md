---
title: Como surgem dois primários
version: 1
---

**Split-brain** são dois servidores aceitando escritas para o mesmo banco de dados ao mesmo tempo,
cada um acreditando ser o primário. A lição 15 criou um com um reboot. O gerenciador de cluster da
lição 16 existe para impedir exatamente isso, e impede, com uma premissa por baixo: a de que um
primário que **não consegue renovar** a chave de líder vai perceber e parar.

Perceber exige um processo que esteja rodando. Três eventos comuns param o processo e deixam o banco
de dados rodando:

- **Uma pausa.** O hipervisor suspende uma máquina virtual para um snapshot ou uma migração, o processo
  espera um disco que parou de responder, ou a máquina está sobrecarregada demais para escaloná-lo. A
  pausa termina minutos depois e o processo continua de onde estava, sem saber que o tempo passou.
- **Uma partição.** A máquina do primário perde a conexão com o etcd e mantém a conexão com parte dos
  servidores de aplicação.
- **Uma queda só do gerenciador.** O processo do Patroni morre e o PostgreSQL, um processo separado,
  continua atendendo.

Em todos os casos a chave de líder expira, uma réplica a pega e se promove, e o primário antigo
continua recebendo escritas de quem consegue alcançá-lo. O gerenciador de cluster fez tudo certo. O que
falta é um jeito de garantir que o primário antigo **parou de fato** antes que o novo comece, e isso
se chama **fencing**.

A próxima seção provoca o primeiro caso de propósito.
