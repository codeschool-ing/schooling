---
title: "O Play Console, e o que ele custa antes de tudo"
version: 1
---

**Publicar no Google Play exige uma conta de desenvolvedor do Google Play, e criar uma custa
dinheiro.** O Google cobra uma taxa de registro única. O valor dela, e as verificações de identidade
que vêm com uma conta nova, estão nas páginas de ajuda do Play Console em `support.google.com`, e
**essas páginas não puderam ser acessadas do computador em que este curso foi gravado**, então este
curso não cita um valor. Leia o valor atual lá antes de começar; um estudante que nunca publica no
Google Play nunca o paga, e o flavour `direct` da seção 03 é um jeito de entregar o planner a algumas
pessoas sem conta nenhuma.

Tudo o que vem abaixo **não foi executado**, pelo mesmo motivo: nenhuma conta foi criada. A regra do
nível de API alvo é citada da documentação do Google em `developer.android.com`, lida em 30 de outubro
de 2026. O roteiro dos passos do console depois dela é uma descrição, não uma transcrição: as páginas
de ajuda que documentam cada passo são as que não puderam ser acessadas, então confira cada passo lá
quando for fazê-lo.

## A regra do nível de API alvo, com a data

A página do Google *Target API level requirements for Google Play apps* diz que **a partir de 31 de
agosto de 2026, apps novos e atualizações de apps precisam ter como alvo o Android 16 (nível de API
36) ou superior para serem enviados ao Google Play**, com níveis menores para apps de Wear OS,
Android Automotive OS, Android TV e Android XR. Ela diz também que apps existentes precisam ter como
alvo o Android 15, API 35, ou superior para continuarem disponíveis a usuários novos em aparelhos
com um Android mais novo que o alvo do app. O planner tem como alvo o 36, e é por isso que a aula 1
o escolheu. A regra muda todo ano, e a página é onde a próxima data aparece.

## Do bundle aos estudantes

O caminho de um envio, em linhas gerais, vale a pena conhecer antes de começar:

1. **Crie o app** no Play Console: o nome, o idioma padrão e se ele é gratuito.
2. **Ative a Assinatura de apps do Google Play**, seção 07, e registre a chave de upload.
3. **Envie o bundle** da seção 06 para uma faixa de teste: o teste interno chega a uma lista curta de
   testadores que você nomeia, e os testes fechado e aberto chegam a mais gente.
4. **Preencha a página da loja e as declarações**: a descrição e as capturas de tela, uma política de
   privacidade, o questionário de classificação de conteúdo e o formulário de segurança dos dados,
   que diz quais dados o app coleta e por quê. A aula 13 de `mobile-fundamentals` trata do que esse
   formulário obriga você a declarar.
5. **Promova uma versão para produção**, o que a envia para a revisão do Google antes de chegar à
   loja.

O `versionCode` da seção 02 precisa crescer a cada envio: o console recusa um bundle cujo código já
viu, e essa é a única regra daqui que um estudante encontra no segundo envio.

## O que `mobile-delivery` leva adiante

Os passos depois do primeiro envio, como lançamentos graduais, notas de versão em vários idiomas, o
equivalente na App Store e a automação de tudo isso, são o assunto de `mobile-delivery`, um curso
posterior desta trilha que todo estudante faz, e esta aula para na primeira versão publicada.
