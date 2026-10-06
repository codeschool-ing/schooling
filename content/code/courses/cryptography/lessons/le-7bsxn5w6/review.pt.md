---
title: Uma revisão em dezessete perguntas
version: 1
---

**Este curso foi um conjunto de decisões, cada uma com um motivo. Revisar a criptografia de um
sistema é fazer as mesmas perguntas na mesma ordem, e a resposta que deve preocupar é "não sei" mais
vezes do que "não".** Uma pergunta por aula, com a resposta a procurar:

| aula | pergunta | como soa uma resposta sólida |
| --- | --- | --- |
| 1 | Como os dados são cifrados? | AES-GCM ou ChaCha20-Poly1305, nonces únicos, falhas ao abrir tratadas como ataques |
| 2 | De que tamanho são as chaves assimétricas? | RSA de 3072 bits ou mais para chaves novas, ou P-256 ou Ed25519 |
| 3 | Que chave faz o quê? | cifrar para a chave pública do destinatário, assinar com a própria chave privada |
| 4 | Que hash, para quê? | SHA-256 ou melhor; MD5 e SHA-1 em nenhum lugar de que a segurança dependa |
| 5 | Como as senhas são guardadas? | Argon2id ou bcrypt, um sal por senha, a pimenta guardada à parte |
| 6 | Como a integridade é conferida? | HMAC ou assinaturas, comparados em tempo constante |
| 7 | Há sigilo futuro? | Diffie-Hellman efêmero, e um plano para troca de chaves pós-quântica |
| 8 | Quem emite os certificados? | uma AC conhecida, raízes privadas guardadas offline, emissões registradas |
| 9 | Os clientes os validam? | cadeia, nome, datas e revogação, com a verificação nunca desligada |
| 10 | Qual TLS? | 1.3, ou 1.2 com suítes de sigilo futuro; nada mais antigo oferecido |
| 11 | Algo é "cifrado" com Base64 ou XOR? | não: codificação e ofuscação levam o nome do que são |
| 12 | Que protocolos levam credenciais? | SFTP ou FTPS, LDAPS ou StartTLS, nunca as formas puras |
| 13 | O que protege nomes, chamadas e e-mail? | DNSSEC assinado e validado, SRTP, S/MIME onde o e-mail precisa ficar selado |
| 14 | O que é cifrado em repouso, e onde está a chave? | cada camada escolhida contra um roubo nomeado, chaves num KMS, recuperação testada |
| 15 | Qual segurança de Wi-Fi? | WPA3 ou 802.1X; WPA2-Personal só com frase aleatória; nunca WEP nem TKIP |
| 16 | Os clientes conferem o servidor RADIUS? | um perfil distribuído com a AC e o servidor, ou EAP-TLS |
| 17 | Chaves no código, esquemas caseiros, nonces repetidos? | scanners na CI, receitas de biblioteca, nonces escolhidos pela biblioteca e auditados |

## Usar a tabela

Faça as perguntas a alguém que opera o sistema, não à documentação dele, e peça a evidência por trás
de cada resposta: o arquivo de configuração, o último relatório do scanner, a data em que a chave foi
trocada pela última vez. Uma resposta escrita que ninguém consegue mostrar é uma esperança.

A maior parte do que uma revisão encontra está na coluna da direita das aulas 14 a 17. Os algoritmos
das primeiras linhas em geral são escolhidos por uma biblioteca ou por um fornecedor e em geral estão
bem. **As chaves, as configurações e os procedimentos em volta delas são escolhidos por pessoas, uma
de cada vez**, e é aí que este curso passou as quatro últimas aulas e onde a sua atenção vai render
mais.
