---
title: Compartilhar indicadores sem estrago
version: 1
---

Indicadores saem da empresa quando ela compartilha o que aprendeu (aula 8), e chegam de outros. Quatro
hábitos evitam que essa troca cause estrago.

**Dê a todo indicador uma vida.** Um endereço usado para adivinhar senhas nesta semana pode ser reatribuído a
um cliente de banda larga residencial no mês que vem. Compartilhe-o com um `valid_until`, e tire do seu
próprio SIEM o que venceu, senão a regra que pegou um atacante em setembro bloqueia um desconhecido em
dezembro.

**Diga o que o indicador foi visto fazendo.** "203.0.113.200" sozinho convida a um bloqueio; "203.0.113.200,
recebeu 612 MB de um servidor de arquivos por HTTPS às 02:41 de 17 de setembro, depois de um acesso por SSH"
deixa quem recebe julgar a relevância e evitar bloquear algo de que depende.

**Cuidado com infraestrutura compartilhada.** Endereços de grandes provedores de nuvem, redes de entrega de
conteúdo e operadoras móveis são usados por milhares de clientes ao mesmo tempo, muitas vezes atrás de
tradução de endereços. Um indicador apontando para um deles bloqueia o inocente junto com o culpado. Prefira
domínios, comportamento ou nada.

**Desarme o que pessoas vão ler.** Escrito num relatório ou num chat, um indicador é tornado inerte para
ninguém clicar ou conectar por acidente: `203.0.113[.]66`, `hxxps://files.example[.]com`. Formatos para
máquinas, como o STIX, guardam o valor real, porque um SIEM precisa casá-lo exatamente.
