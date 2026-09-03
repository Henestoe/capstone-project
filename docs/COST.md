# Infrastructure Cost

Estimated monthly cost for us-east-1, running 730 hours, before tax
and credits. Prices checked September 2026.

| Resource | Monthly estimate |
|---|---:|
| 1 t3.medium control plane | $30.51 |
| 2 t3.small workers | $30.51 |
| 90 GB gp3 storage | $7.20 |
| 3 public IPv4 addresses | $10.95 |
| S3 state and DynamoDB locking allowance | $1.00 |
| **AWS total** | **$80.17** |

Postgres uses the existing root disk, so its PVC adds no separate
volume charge. Domain renewal and additional data transfer are excluded.
Domain cost is the GoDaddy annual renewal price divided by 12.

An equivalent single t3.medium server would cost approximately
$36.56/month. The extra nodes support application redundancy and
worker-failure recovery, but Postgres remains a single point of failure.

## Halving the cost

For this learning environment, running all three nodes around 10 hours
daily would reduce the estimate to roughly $38/month. Disks remain
billable while stopped. This sacrifices continuous availability, and
changed public IPs require DNS and inventory updates.
