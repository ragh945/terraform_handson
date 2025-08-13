# Terraform + AWS (Windows) — Step‑by‑Step README

This guide shows a clean, repeatable way to set up AWS credentials, test them, and run Terraform on Windows CMD. It also includes common fixes you’ve hit (bad credentials, key pair duplicates, RDS connectivity/parameter issues).

---

## 0) Prerequisites

* **AWS account** with permissions (AdministratorAccess for testing is easiest; least‑privilege later).
* **AWS CLI** installed (`aws --version`).
* **Terraform** installed (`terraform -version`).
* (Optional) **PuTTYgen** or **OpenSSH** for SSH keys if you’re creating EC2 instances.

> Tip: Keep your project in a path without spaces to avoid escaping issues (e.g., `C:\terraform\project`).

---

## 1) Create or verify an IAM user + access keys

1. AWS Console → **IAM** → **Users** → your user → **Security credentials**.
2. Under **Access keys**, click **Create access key** → choose **Command Line Interface (CLI)** → copy:

   * **Access key ID** (looks like `AKIA...`)
   * **Secret access key** (long random string)
3. Make sure the **Status** is **Active**.

> If the key was created earlier, confirm it still shows **Active** and belongs to the account you’re using.

---

## 2) Configure credentials (pick ONE method)

Use exactly **one** of these; mixing methods can cause Terraform to use the wrong keys.

### Method A — AWS CLI default profile (recommended)

In **CMD**:

```cmd
aws configure
```

Enter:

```
AWS Access Key ID: <YOUR_AKIA_KEY>
AWS Secret Access Key: <YOUR_SECRET_KEY>
Default region name: us-east-2
Default output format: json
```

AWS stores these at `%USERPROFILE%\.aws\credentials` and `%USERPROFILE%\.aws\config`.

**Provider config for Terraform (clean):**

```hcl
# provider.tf
provider "aws" {
  region = var.AWS_REGION
}

variable "AWS_REGION" {
  type    = string
  default = "us-east-2"
}
```

Terraform automatically reads the CLI credentials. **No keys in code.**

### Method B — Environment variables

Set persistent env vars (then open a new CMD):

```cmd
setx AWS_ACCESS_KEY_ID "YOUR_NEW_ACCESS_KEY"
setx AWS_SECRET_ACCESS_KEY "YOUR_NEW_SECRET_KEY"
setx AWS_DEFAULT_REGION "us-east-2"
```

**Provider config stays the same as Method A** (don’t hardcode keys):

```hcl
provider "aws" {
  region = var.AWS_REGION
}
```

### Method C — Variables + tfvars (only if you must)

Create `terraform.tfvars` (do **not** commit):

```hcl
AWS_ACCESS_KEY = "YOUR_AKIA_KEY"
AWS_SECRET_KEY = "YOUR_SECRET_KEY"
AWS_REGION     = "us-east-2"
```

`provider.tf`:

```hcl
variable "AWS_ACCESS_KEY" { type = string }
variable "AWS_SECRET_KEY" { type = string }
variable "AWS_REGION"     { type = string }

provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
}
```

Run with:

```cmd
terraform plan -var-file="terraform.tfvars"
```

> Note: Method C is more error‑prone and less secure. Prefer A or B.

---

## 3) Verify credentials BEFORE Terraform

Run this in CMD:

```cmd
aws sts get-caller-identity
```

**Expected output** (example):

```json
{
  "UserId": "AIDXXXXXXXXXXXXXXX",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

If you see `InvalidClientTokenId`, see **Troubleshooting A** below.

---

## 4) Project structure (example)

```
project/
  provider.tf
  variables.tf
  vpc.tf
  nat.tf
  security_group.tf
  createInstance.tf
  rds.tf
  outputs.tf
  terraform.tfvars         # if using Method C (never commit)
  .gitignore               # include terraform.tfvars, *.pem
```

---

## 5) Initialize, validate, and plan/apply

From your project folder in CMD:

```cmd
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

If using Method C:

```cmd
terraform plan  -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## 6) SSH key notes (EC2)

**Using PuTTYgen**

1. Open PuTTYgen → RSA 4096 → **Generate** → move mouse.
2. **Save private key** (PuTTY `.ppk`) if using PuTTY.
3. **Conversions → Export OpenSSH key** → save as `level_up_key` (no extension) for OpenSSH/Terraform.
4. Copy **Public key for pasting into OpenSSH** to `level_up_key.pub`.

**Terraform**

```hcl
resource "aws_key_pair" "level_up" {
  key_name   = "level_up_key"
  public_key = file("D:/terraform_keys/level_up_key.pub")
}
```

> If you get `InvalidKeyPair.Duplicate`, the key pair name already exists: delete it in EC2 Console, change `key_name`, or import: `terraform import aws_key_pair.level_up level_up_key`.

**Windows paths**: Use `D:/path/file` or escape backslashes `D:\\path\\file`.

---

## 7) RDS (MariaDB) quick reference

**Matching engine + parameter group** (common pitfall):

```hcl
resource "aws_db_parameter_group" "mariadb106" {
  name   = "levelup-mariadb-parameters"
  family = "mariadb10.6"
}

resource "aws_db_instance" "mariadb" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mariadb"
  engine_version          = "10.6.21"
  instance_class          = "db.t3.micro"
  identifier              = "mariadb-instance"
  db_name                 = "mariadb"
  username                = "root"
  password                = "mariadb141"
  db_subnet_group_name    = aws_db_subnet_group.mariadb_subnets.name
  parameter_group_name    = aws_db_parameter_group.mariadb106.name
  vpc_security_group_ids  = [aws_security_group.allow_mariadb.id]
  backup_retention_period = 30
  availability_zone       = aws_subnet.private_az1.availability_zone
  skip_final_snapshot     = true
}

output "rds_endpoint" {
  value = aws_db_instance.mariadb.endpoint
}
```

**Connect** (default port 3306):

```bash
mysql -h <rds-endpoint> -u root -p
# or explicitly
mysql -h <rds-endpoint> -P 3306 -u root -p
```

**Security Group must allow** inbound TCP **3306** from your EC2 SG or your IP. If connecting from your PC, RDS must be **Publicly accessible = true** (only for testing; restrict later).

---

## 8) Modern provider changes you already fixed

* `aws_eip`: remove `vpc = true`.
* `aws_vpc`: remove `enable_classiclink` / `enable_classiclink_dns_support`.
* `aws_db_instance`: use `db_name` (not `name`).
* Use instance types supported by engine version (e.g., `db.t3.micro` for MariaDB 10.6.x).

---

## 9) Troubleshooting

### A) `InvalidClientTokenId` (credentials rejected)

* You’re using wrong/old keys. Fix:

  1. Delete cached files:

     ```cmd
     del %USERPROFILE%\.aws\credentials
     del %USERPROFILE%\.aws\config
     ```
  2. Re‑run `aws configure` with your **active** key.
  3. Test: `aws sts get-caller-identity`.
* Ensure Terraform isn’t using hardcoded old keys in `provider.tf` or `terraform.tfvars`.
* Prefer Method A or B; avoid mixing methods.

### B) `InvalidKeyPair.Duplicate`

* Key pair with that `key_name` already exists.

  * Delete it in EC2 Console, or
  * Change `key_name`, or
  * Import: `terraform import aws_key_pair.level_up level_up_key`.

### C) `file("…")` can’t find your `.pub`

* Use absolute path `D:/terraform_keys/level_up_key.pub`.
* Avoid spaces in folders or escape them.
* From the project dir, test in Terraform console:

  ```
  terraform console
  file("D:/terraform_keys/level_up_key.pub")
  ```

### D) RDS engine/parameter/instance mismatch

* Parameter group **family** must match engine major version (e.g., `mariadb10.6`).
* Use supported instance class (e.g., `db.t3.micro` with MariaDB 10.6.x).

### E) Can’t connect to RDS

* Use hostname **without** `:3306` in `-h`. Use `-P 3306` for port if needed.
* Ensure RDS SG allows inbound **3306** from your source.
* If connecting from outside VPC, set **Publicly accessible = true** (testing only).

### F) Region and profiles

* To use a named profile:

  ```cmd
  setx AWS_PROFILE "myprofile"
  ```

  And in Terraform (optional):

  ```hcl
  provider "aws" {
    region  = var.AWS_REGION
    profile = "myprofile"
  }
  ```

---

## 10) Security tips

* **Never commit** credentials or private keys. Add to `.gitignore`:

  ```
  terraform.tfvars
  *.pem
  *.ppk
  .terraform/
  .terraform.lock.hcl
  ```
* Rotate keys regularly. Prefer AWS SSO/roles for long‑term setups.

---

## 11) Quick checklist

* [ ] IAM user + **Active** access key exists
* [ ] Credentials set via **Method A (CLI)** or **Method B (env vars)**
* [ ] `aws sts get-caller-identity` works
* [ ] `terraform init` / `validate` / `plan` succeed
* [ ] EC2 key pair created (no duplicate name)
* [ ] RDS engine ↔ parameter group family match
* [ ] SG rules allow expected connectivity

---

### Commands you’ll run most

```cmd
aws configure
aws sts get-caller-identity
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
bash
## **git** clone and declone commands
### Delete the existing folder and re-clone
```bash
rmdir /S /Q terraform_handson
git clone https://github.com/ragh945/terraform_handson.
cd reponame

# Remove the file
git rm "AWS RDS/variables.tf"

# Commit and push
git commit -m "Remove variables.tf"
git push origin main
```

