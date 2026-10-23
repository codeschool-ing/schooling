---
title: Sandboxes que outra pessoa roda
version: 1
---

**Um sandbox online roda um arquivo suspeito numa máquina virtual descartável e registra o que ele
fez.** A aula 12 montou uma versão pequena disso na sua própria máquina: rodar um programa onde ele não
pode fazer mal e observar o que ele tenta. Serviços como o any.run e o Joe Sandbox fazem o mesmo em
escala, com Windows e outros sistemas, um conjunto completo de programas de documentos e navegadores
instalado e um relatório escrito para analistas. Nenhum foi acessado neste curso; esta seção vem da
documentação deles, e nenhum relatório é mostrado.

## O que um relatório traz

| parte do relatório | o que responde |
|---|---|
| árvore de processos | o que iniciou o quê: o documento que abriu um script que abriu um download |
| atividade de rede | os domínios e endereços contatados, com as próprias requisições |
| arquivos escritos e alterados | o que foi largado no disco, e onde tentou se manter depois de um reboot |
| indicadores | hashes, domínios e endereços para bloquear ou procurar em outro lugar |
| comportamento mapeado no MITRE ATT&CK | as técnicas observadas, no vocabulário que as regras de detecção usam |

Os indicadores são o que quem defende leva embora: os domínios vão para o resolvedor da aula 14, os
hashes para as assinaturas da aula 7 e a caça da aula 8, as técnicas para as regras de detecção.

## Os dois serviços

O **any.run** é interativo: o analista vê a tela da máquina virtual no navegador e consegue clicar no que
a amostra pede, como um documento que diz "habilite a edição". O plano gratuito dele torna pública cada
análise.

O **Joe Sandbox** roda amostras sozinho e escreve relatórios longos e detalhados. O plano gratuito
"Cloud Basic" publica os relatórios; os planos pagos os mantêm privados e acrescentam mais sistemas.

## Os limites deles

Um sandbox vê o que uma amostra faz em alguns minutos, numa máquina, naquele dia. Amostras escritas para
fugir de análise procuram sinais de máquina virtual, esperam mais do que o sandbox observa ou não fazem
nada a não ser que achem o idioma, o domínio ou o usuário certos, e aí o relatório sai limpo porque nada
rodou. **Um relatório de sandbox limpo quer dizer que a amostra não fez nada ali**, o que é mais fraco
que "a amostra não faz nada". A regra de privacidade da primeira seção vale aqui com mais força que em
qualquer lugar: um documento enviado a um sandbox público é publicado junto com um vídeo de alguém
abrindo-o.
