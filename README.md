# OpenClaw AI Assistant with Tailscale on AWS EC2

This Terraform configuration deploys OpenClaw AI assistant on AWS EC2 with Tailscale for secure networking.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (v1.0+)
3. **Tailscale Account** - Sign up at https://tailscale.com
4. **AWS CLI** configured with credentials
5. **EC2 Key Pair** created in your AWS region

## Setup Instructions

### 1. Get Tailscale Auth Key

1. Log in to Tailscale admin console: https://login.tailscale.com/admin
2. Go to Settings → Keys
3. Click "Generate auth key"
4. Select options:
   - Reusable: Yes (if deploying multiple instances)
   - Ephemeral: No (unless you want temporary devices)
   - Tags: Optional (for ACL management)
5. Copy the generated key (starts with `tskey-auth-`)

### 2. Configure Terraform Variables

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your actual values:
   ```hcl
   aws_region          = "us-east-1"
   vpc_id              = "vpc-xxxxx"
   subnet_id           = "subnet-xxxxx"
   key_name            = "your-key-pair"
   tailscale_auth_key  = "tskey-auth-xxxxx"
   ```

3. To find your VPC and Subnet IDs:
   ```bash
   # List VPCs
   aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
   
   # List Subnets
   aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,VpcId,AvailabilityZone]' --output table
   ```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted to confirm deployment.

### 4. Verify Deployment

1. **Check EC2 Instance**:
   ```bash
   terraform output instance_public_ip
   ```

2. **Verify Tailscale Connection**:
   - Go to Tailscale admin console: https://login.tailscale.com/admin/machines
   - You should see your new EC2 instance listed
   - Note the Tailscale IP address (usually 100.x.x.x)

3. **SSH to Instance** (optional, via Tailscale):
   ```bash
   ssh ubuntu@100.x.x.x
   ```

4. **Check OpenClaw Status**:
   ```bash
   ssh ubuntu@<instance-ip>
   docker ps
   docker logs openclaw
   ```

### 5. Access OpenClaw

You can access OpenClaw through:

1. **Via Tailscale** (recommended, secure):
   ```
   http://100.x.x.x:8080
   ```

2. **Via Public IP** (if needed):
   ```
   http://<public-ip>:8080
   ```

## Configuration

### Instance Types

Choose based on your workload:
- `t3.small` - Light usage (2 vCPU, 2GB RAM)
- `t3.medium` - Moderate usage (2 vCPU, 4GB RAM) - **Default**
- `t3.large` - Heavy usage (2 vCPU, 8GB RAM)
- `t3.xlarge` - Production (4 vCPU, 16GB RAM)

### Security Considerations

1. **Restrict SSH Access**: Update `ssh_cidr_blocks` in `terraform.tfvars` to your IP only:
   ```hcl
   ssh_cidr_blocks = ["YOUR.IP.ADDRESS/32"]
   ```

2. **Use Tailscale ACLs**: Configure access controls in Tailscale admin console

3. **Enable Firewall**: Consider using AWS Security Groups to restrict access

4. **Rotate Keys**: Regularly rotate your Tailscale auth keys

### OpenClaw Configuration

Edit the `openclaw_config` variable in `terraform.tfvars` to customize OpenClaw settings:

```hcl
openclaw_config = <<EOF
{
  "api_port": 8080,
  "model": "gpt-4",
  "api_key": "your-api-key",
  "max_tokens": 2000,
  "temperature": 0.7
}
EOF
```

## Useful Commands

```bash
# View all outputs
terraform output

# SSH via public IP
ssh -i ~/.ssh/your-key.pem ubuntu@$(terraform output -raw instance_public_ip)

# View instance logs
ssh ubuntu@<ip> "sudo journalctl -u openclaw -f"

# Restart OpenClaw
ssh ubuntu@<ip> "cd /opt/openclaw && sudo docker-compose restart"

# Update Terraform
terraform plan
terraform apply

# Destroy infrastructure
terraform destroy
```

## Tailscale Features

### Access Control Lists (ACLs)

Configure who can access your OpenClaw instance in Tailscale admin console under Access Controls.

### Exit Node

The instance is configured as a Tailscale exit node. To use it:
1. Go to Tailscale admin console
2. Enable the exit node for your device
3. Select this EC2 instance as your exit node

### MagicDNS

Tailscale provides automatic DNS. Access your instance via:
```
http://openclaw-tailscale-instance:8080
```

## Troubleshooting

### Tailscale Not Connecting

```bash
# SSH to instance
ssh ubuntu@<instance-ip>

# Check Tailscale status
sudo tailscale status

# View Tailscale logs
sudo journalctl -u tailscaled -f
```

### OpenClaw Not Starting

```bash
# Check Docker status
sudo docker ps -a

# View OpenClaw logs
sudo docker logs openclaw

# Restart service
cd /opt/openclaw
sudo docker-compose restart
```

### Can't Access via Tailscale

1. Ensure Tailscale is running on your local machine
2. Check that the device appears in Tailscale admin console
3. Verify ACLs aren't blocking access
4. Try accessing via the Tailscale IP (100.x.x.x)

## Cost Optimization

- Use `t3.micro` or `t3.small` for development
- Enable `use_elastic_ip = false` if you don't need a static IP
- Consider using Spot Instances for non-production workloads
- Set up auto-shutdown during non-business hours

## Cleanup

To remove all resources:

```bash
terraform destroy
```

Also remember to:
1. Remove the device from Tailscale admin console
2. Revoke the auth key if no longer needed

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- OpenClaw Documentation (check project repository)
