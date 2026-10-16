---
title: Quanto custam os três
version: 1
---

Cada serviço é cobrado pelo que lê, então cada um cresce com uma parte diferente do sistema:

```
ana@laptop:~/aws$ python3 price.py AmazonGuardDuty "CloudTrail event analyzed"
AmazonGuardDuty, sa-east-1, published 2026-10-08
  SAE1-PaidEventsAnalyzed                  0.000007 USD per Events     $0.000007 per CloudTrail event analyzed in South America (Sao Paulo) region
ana@laptop:~/aws$ python3 price.py AmazonGuardDuty PaidEventsAnalyzed-Bytes
AmazonGuardDuty, sa-east-1, published 2026-10-08
  SAE1-PaidEventsAnalyzed-Bytes            0.260000 USD per GB         $0.26 per GB over 10000 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            0.440000 USD per GB         $0.44 per GB for the next 7500 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            0.880000 USD per GB         $0.88 per GB for the next 2000 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            1.750000 USD per GB         $1.75 per GB for the first 500 GB / month of data analyzed South America (Sao Paulo) region
ana@laptop:~/aws$ python3 price.py AmazonInspectorV2 SAE1-container-image
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-container-image-initial-scan        0.110000 USD per Resource-assessment $0.11 per Resource-assessment for container-image-initial-scan in South America (Sao Paulo)
  SAE1-container-image-initial-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-initial-scan-free-trial in South America (Sao Paulo)
  SAE1-container-image-re-scan             0.010000 USD per Resource-assessment $0.01 per Resource-assessment for container-image-re-scan in South America (Sao Paulo)
  SAE1-container-image-re-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-re-scan-free-trial in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py AmazonInspectorV2 SAE1-EC2-Scanning
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-EC2-Scanning                        0.002100 USD per Instance-hrs $0.0021 per Instance-hrs for EC2-Scanning in South America (Sao Paulo)
  SAE1-EC2-Scanning-agentless              0.002890 USD per Instance-hrs $0.00289 per Instance-hrs for EC2-Scanning-agentless in South America (Sao Paulo)
  SAE1-EC2-Scanning-agentless-free-trial     0.000000 USD per Instance-hrs $0.0 per Instance-hrs for EC2-Scanning-agentless in South America (Sao Paulo)
  SAE1-EC2-Scanning-free-trial             0.000000 USD per Instance-hrs $0.0 per Instance-hrs for EC2-Scanning-free-trial in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py AWSSecurityHub "security checks per account"
AWSSecurityHub, sa-east-1, published 2026-09-30
  SAE1-PaidComplianceCheck                 0.000500 USD per Security Checks Over 500,000 security checks per account per region per month cost USD0.0005 per check
  SAE1-PaidComplianceCheck                 0.000800 USD per Security Checks 100,001 to 400,000 security checks per account per region per month cost USD0.0008 per check
  SAE1-PaidComplianceCheck                 0.001000 USD per Security Checks The first 100,000 security checks per account per region per month cost USD0.001 per check
```

O **GuardDuty** cobra pelos eventos do CloudTrail que analisa, 7 USD por milhão em São Paulo, e pelos
flow logs e logs de DNS por gigabyte, 1,75 USD por GB nos primeiros 500 GB do mês e menos depois. As
proteções opcionais, monitoramento de runtime, varredura de malware, RDS e S3, têm linhas próprias. Há um
teste grátis de 30 dias em cada uma, que são as linhas grátis da lista.

O **Inspector** cobra por coisa escaneada: 0,11 USD pela primeira varredura de uma imagem no ECR e 0,01
USD por cada nova varredura, e 0,0021 USD por hora por instância EC2 escaneada com o agente, 0,00289 sem.

O **Security Hub** cobra por verificação de controle, 0,001 USD por cada uma das primeiras 100.000 do mês e
menos depois, e por achado recebido além de 10.000 por mês. A lista também traz linhas por recurso de um
plano mais novo, que esta lição não calcula.

## A loja, num mês

| linha | quantidade | USD por mês |
|---|---|---|
| GuardDuty, eventos do CloudTrail | 2 milhões × 0,000007 | 14,00 |
| GuardDuty, flow logs e DNS | 40 GB × 1,75 | 70,00 |
| Inspector, imagens no ECR | 60 imagens novas × 0,11, 900 novas varreduras × 0,01 | 15,60 |
| Inspector, EC2 | 4 instâncias × 730 h × 0,0021 | 6,13 |
| Security Hub, verificações | 20.000 × 0,001 | 20,00 |
| **total** | | **125,73** |

**Os flow logs são a maior linha**, e crescem com o tráfego. A maioria das equipes liga os três em toda
conta e região que usa, porque o preço de um achado perdido é maior que o ano; o hábito que mantém a conta
sensata é olhar esta tabela uma vez, com os números da própria equipe, antes que alguém pergunte por que
ela dobrou.
