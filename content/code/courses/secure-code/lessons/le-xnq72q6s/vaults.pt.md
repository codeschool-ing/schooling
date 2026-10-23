---
title: Onde a produção guarda os segredos
version: 1
---

Uma variável de ambiente é como um segredo **chega** a um processo. Não é onde um segredo **fica
guardado**. Em produção, a origem da variável deveria ser um **cofre de segredos**: um serviço cujo
único trabalho é guardar segredos, entregá-los aos processos que podem tê-los e registrar cada vez
que faz isso.

| o que um cofre de segredos dá | por que importa |
|---|---|
| **acesso por processo** | o worker de lembretes lê a chave do SMS e não a senha do dono do banco |
| **um registro de auditoria** | cada leitura fica registrada com quem e quando, o que um `.env` num servidor não faz |
| **rotação sem deploy** | uma chave muda num lugar só, e o processo a pega na próxima inicialização ou leitura |
| **credenciais de vida curta** | alguns cofres emitem uma senha de banco válida por uma hora, então uma cópia que vaza expira sozinha |

Os mais comuns são o HashiCorp Vault, que a equipe roda por conta própria, e os serviços gerenciados
de cada nuvem: AWS Secrets Manager, Google Secret Manager e Azure Key Vault. Plataformas de
contêineres como o Kubernetes têm um objeto `Secret` que entrega valores a um processo, e que é tão
seguro quanto o controle de acesso do próprio cluster. Nenhum deles foi executado para este curso;
cada um se configura de um jeito, e todos terminam onde o código desta aula começa, numa variável
que o processo lê ao iniciar e sem a qual se recusa a iniciar.

::: track devsecops
Os cursos `secure-pipeline` e `cloud-security` da sua trilha rodam um cofre de segredos e o ligam a um
pipeline e a uma conta de nuvem. A parte desta aula é a da aplicação: nunca guardar segredo no
código, e se recusar a iniciar sem um.
:::

::: track security
O curso `cloud-security` da sua trilha olha como provedores de nuvem guardam e concedem segredos. A
parte desta aula é a da aplicação: nunca guardar segredo no código, e se recusar a iniciar sem um.
:::

::: track *
Seja o que for que guarde os segredos, a parte da aplicação é a mesma: nunca guardar segredo no
código, e se recusar a iniciar sem um.
:::

### Uma lista curta para manter

- **Todo segredo tem dono e data de rotação.** Uma chave que ninguém lembra de ter criado é uma chave
  que ninguém vai trocar.
- **Um segredo por finalidade.** O worker de lembretes e o portal não dividem a senha do banco, então
  revogar uma não para o outro, e um vazamento de um não abre o outro.
- **Segredos nunca aparecem em logs nem em páginas de erro.** A aula 15 trata do que uma página de
  erro e uma linha de log podem mostrar.
