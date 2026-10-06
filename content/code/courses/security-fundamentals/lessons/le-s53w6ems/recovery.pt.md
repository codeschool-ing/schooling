---
title: Recuperação, a porta ao lado da fechadura
version: 1
---

Todo sistema de MFA precisa responder a uma pergunta: **o que acontece quando alguém perde o celular?** A
resposta é o processo de recuperação de conta, e um atacante o lê com o mesmo cuidado que a página de
login, porque uma recuperação mais fácil que o login é a verdadeira porta de entrada.

### Códigos de recuperação

Quando o MFA é ligado, um bom sistema também emite um punhado de **códigos de recuperação**: códigos
longos e aleatórios, cada um usável uma vez, para imprimir ou guardar em lugar seguro e longe do celular.
Perder o celular então quer dizer usar um código e configurar o celular novo. Códigos de recuperação são
um fator por si, algo que você tem, e devem ser protegidos como um: não numa nota no mesmo celular, não
no e-mail que eles ajudariam a recuperar.

### O suporte

Quando não há códigos, a saída é uma pessoa: alguém liga para o suporte e pede que o MFA seja redefinido.
Essa ligação é o passo mais atacado do sistema inteiro, porque transforma um controle técnico de volta
numa conversa, e conversas podem ser manipuladas. Quem liga sabendo o nome do funcionário, o nome do
gestor e alguns detalhes das redes sociais consegue soar exatamente como um colega nervoso que perdeu o
celular antes de uma reunião.

As defesas são de procedimento:

- **verificar por um canal que quem liga não escolheu**: ligar de volta no número do cadastro de
  funcionários, ou confirmar com o gestor da pessoa, nunca no número que quem liga informa;
- **exigir mais para mais**: redefinir o MFA de um administrador exige mais que o de um usuário comum,
  de preferência a pessoa na frente de alguém que a conhece;
- **registrar e avisar**: toda redefinição fica no log com quem aprovou, e o dono da conta é avisado por
  um segundo canal, para que uma redefinição que ele não pediu seja notada no mesmo dia;
- **ser lento de propósito**: um pequeno atraso antes de a redefinição valer dá ao dono verdadeiro tempo
  de contestar.

As aulas 1 e 5 de `attacks-threats` desmontam como quem liga constrói um pretexto; esta aula só precisa
do lado do defensor.

### Recuperação fraca desfaz login forte

Perguntas de segurança, recuperação por SMS para um número que pode ser trocado, e e-mails de "clique
aqui para redefinir" para uma caixa com senha fraca são comuns, e cada um transforma um login forte num
fraco, porque o atacante simplesmente escolhe a porta mais fraca. **Uma conta é tão forte quanto o jeito
mais fácil de entrar nela**, e isso inclui o caminho de volta. Quando a loja configurou o MFA, a ana listou
todo jeito de recuperar uma conta e fechou os que eram mais fracos que o login.
