# IAM and Networking Lab

Two-part AWS lab: IAM setup (console) and a data-platform VPC (Terraform), built under AWS account `025523568662`.

## Part 1 — IAM Setup

See [Lab_1_1_IAM_Setup.txt](Lab_1_1_IAM_Setup.txt).

Roles created: `DataEngineerRole`, `GlueServiceRole`, `LambdaExecutionRole`, `RedshiftIAMRole`, `AnalystReadOnlyRole`, plus a custom policy `DataLakeBucketAccessPolicy`.

## Part 2 — VPC & Networking

Full details: [Lab_1_2_VPC_Documentation.txt](Lab_1_2_VPC_Documentation.txt).

Built in **`eu-west-1`** (the training role's IAM permissions did not allow EC2/VPC creation in `us-east-1`).

### Resources

| Resource | ID | Notes |
|---|---|---|
| VPC `data-platform-vpc` | `vpc-086ebedad8dd36707` | `10.0.0.0/16` |
| Subnet `public-subnet-1a` | `subnet-02f71b25c3dda1b75` | `10.0.1.0/24`, `eu-west-1a` |
| Subnet `private-subnet-1a` | `subnet-03b3e5496fdf1898b` | `10.0.2.0/24`, `eu-west-1a` |
| Subnet `private-subnet-1b` | `subnet-0c3192d842498dd57` | `10.0.3.0/24`, `eu-west-1b` |
| Internet Gateway `data-platform-igw` | `igw-09d6c983130246ec5` | attached to the VPC |
| NAT Gateway `data-platform-nat` | `nat-072381d4eec9288f0` (destroyed) | was in `public-subnet-1a` — torn down after the lab, see [Cost management](#cost-management) |
| Elastic IP | `34.247.131.119` (released) | was attached to the NAT Gateway — released after the lab |
| Route table `data-platform-public-rt` | `rtb-0dd6880915b567e0a` | `0.0.0.0/0 → IGW`, associated to `public-subnet-1a` |
| Route table `data-platform-private-rt` | `rtb-0fc66252a30e9ae43` | `0.0.0.0/0 → NAT Gateway`, associated to both private subnets |
| SG `public-nat-sg` | `sg-022354db3715e6a0b` | inbound HTTPS (443) from `0.0.0.0/0` |
| SG `private-compute-sg` | `sg-064a5aca55d19a1f3` | inbound: all traffic from itself, all traffic from `public-nat-sg` |
| SG `private-db-sg` | `sg-07e9a82fb4bea9123` | inbound: 3306 and 5432 from `private-compute-sg` |
| S3 Gateway endpoint | `vpce-02e421011f97d8256` | associated to the private route table |
| DynamoDB Gateway endpoint | `vpce-0031f873119a4d7ab` | associated to the private route table |
| Secrets Manager Interface endpoint | `vpce-01d519c0594cb9526` | in both private subnets, secured by `private-compute-sg` |

### Build history

The resources above were created manually through the AWS console, then imported into Terraform (`terraform/`) to bring them under IaC management. During that reconciliation, three functional gaps were found in the manual build and fixed via `terraform apply`:

- the private route table had no `0.0.0.0/0 → NAT Gateway` route (private subnets had no internet egress)
- `private-compute-sg` was missing its self-referencing "allow all from itself" rule
- the DynamoDB gateway endpoint wasn't associated with any route table

All three are now fixed and `terraform plan` reports no drift.

### Terraform

```
terraform/
├── versions.tf       # Terraform + AWS provider requirement
├── variables.tf       # region, project name, CIDRs, AZs
├── vpc.tf              # VPC, subnets, internet gateway
├── nat.tf               # Elastic IP + NAT Gateway (gated by var.enable_nat_gateway)
├── routes.tf            # route tables + associations + conditional NAT route
├── security_groups.tf   # public-nat-sg, private-compute-sg, private-db-sg
├── endpoints.tf          # S3 / DynamoDB / Secrets Manager endpoints
└── outputs.tf             # resource IDs
```

### Setup

Credentials are kept in a project-local `.env` (git-ignored) rather than `~/.aws/credentials`, loaded via `scripts/load-env.sh`. A Python venv (`phase2/`, also git-ignored) provides `boto3`/`awscli` for ad-hoc verification alongside Terraform.

```bash
# fill in .env with AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN / AWS_DEFAULT_REGION
source scripts/load-env.sh

cd terraform
terraform init
terraform plan
terraform apply
```

### Cost management

The NAT Gateway and its Elastic IP incur hourly charges, so they were destroyed after the lab objectives were verified (Terraform confirmed no drift on the rest of the stack before and after). Their creation is gated by the `enable_nat_gateway` variable (`terraform/variables.tf`), which defaults to `false`.

To recreate the NAT Gateway, EIP, and the private route table's `0.0.0.0/0` route to it in one step:

```bash
cd terraform
terraform apply -var enable_nat_gateway=true
```

This allocates a new Elastic IP (the old `34.247.131.119` was released back to AWS's pool and isn't guaranteed to be reassigned). To tear it down again: `terraform apply -var enable_nat_gateway=false` (or omit the flag, since `false` is the default).

### CI/CD

[.github/workflows/terraform-ci.yml](.github/workflows/terraform-ci.yml) runs on every push/PR touching `terraform/**`:

- `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` — no AWS credentials required.
- A Trivy IaC scan for security misconfigurations (report-only for now — see the comment in the workflow).

This is deliberately static-only: the AWS credentials in this account are short-lived STS session tokens (expire in hours), so `terraform plan`/`apply` are run locally rather than from CI, where stored secrets would go stale.
