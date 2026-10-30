---
title: Quem pode fazer o quê
version: 1
---

**Uma conta é um conjunto de permissões, e o padrão é todo mundo receber permissões demais.** Duas
pessoas tocam um app pequeno e as duas são administradoras; um prestador de serviço é adicionado
para enviar um build e continua com acesso por dois anos. Os papéis existem para que cada pessoa
faça o seu trabalho e nada além. *Lido na documentação de papéis do App Store Connect, outubro de
2026, e na Central de Ajuda do Play Console como publicada em 2025; não rodado.*

## App Store Connect

A Apple dá a cada usuário um ou mais **papéis**, e cada papel é um pacote fixo de permissões:

| papel | para que serve |
|---|---|
| **Account Holder** | a única pessoa que fez a inscrição: assina os acordos legais, renova a assinatura, pede acesso à API |
| Admin | um segundo no comando: gerencia usuários e vê todos os apps |
| App Manager | gerencia apps, builds, testadores e releases |
| Developer | envia builds e usa os recursos de desenvolvedor |
| Marketing | edita a ficha na loja e o material promocional |
| Finance | vê vendas, pagamentos e impostos |
| Sales | vê só os relatórios de vendas |
| Customer Support | responde às avaliações dos clientes |

**Existe exatamente um Account Holder, e só essa pessoa assina os acordos da Apple ou renova a
assinatura.** Quando a Apple publica uma versão nova do acordo de desenvolvedor, os envios param
até o Account Holder aceitá-la. Se essa pessoa saiu da empresa e ninguém consegue entrar como ela,
a equipe espera a transferência do papel. **Escolha o Account Holder de propósito**: alguém que
vai estar ali daqui a dois anos, com a Apple Account protegida por autenticação de dois fatores, e
que lê os e-mails que a Apple manda.

## Play Console

O modelo do Google é uma lista de usuários, cada um com **permissões** escolhidas uma a uma, no
nível da conta ou por app: ver o app, liberar para as faixas de teste, liberar para produção,
gerenciar a ficha na loja, responder avaliações, ver dados financeiros. Existe um **dono da
conta**, que faz tudo e não pode ser removido por ninguém.

A granularidade mais fina é útil: quem coordena os testadores pode liberar para as faixas de teste
sem poder liberar para produção, uma permissão que os papéis fixos da Apple não separam tão bem.

## As regras que a mantêm segura

- **Uma pessoa, um login.** Uma conta compartilhada não consegue dizer quem apertou o botão de
  liberar, e os dois consoles só guardam o registro de atividade por usuário.
- **O menor papel que faz o trabalho.** Uma designer que troca capturas de tela recebe Marketing, e
  não Admin.
- **O acesso termina quando o trabalho termina.** O usuário de um prestador de serviço é removido
  no último dia dele, e alguém lê a lista de usuários a cada trimestre.
- **Autenticação de dois fatores em toda conta que pode liberar.** A Apple a exige nas contas de
  desenvolvedor; do lado do Google, ela protege a Conta Google que faz o login.
