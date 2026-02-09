terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# US East 1 provider required for ACM certificates used with CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "site" {
  bucket = "legoblox.me-website"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "legoblox-me-oac"
  description                       = "OAC for legoblox.me-website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  wait_for_deployment = false
  aliases             = ["legoblox.me", "www.legoblox.me"]

  # EC2 OpenResty/Lua server as the origin (instead of S3)
  # CloudFront requires a domain name, not an IP - use EC2 public DNS
  origin {
    domain_name = aws_instance.openresty.public_dns
    origin_id   = "ec2-openresty-lua"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"  # EC2 only has HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ec2-openresty-lua"
    viewer_protocol_policy = "redirect-to-https"

    # Forward query strings for API calls like /api/door?side=left
    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "all"
      }
    }

    # Short cache for dynamic Lua content
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 60
  }

  # Cache static assets longer
  ordered_cache_behavior {
    path_pattern           = "*.css"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ec2-openresty-lua"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 3600
    default_ttl = 86400
    max_ttl     = 604800
  }

  ordered_cache_behavior {
    path_pattern           = "*.js"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ec2-openresty-lua"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 3600
    default_ttl = 86400
    max_ttl     = 604800
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_iam_policy_document" "site" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json
}

resource "aws_route53_zone" "primary" {
  name = "legoblox.me"
}

# ACM Certificate for custom domain (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = "legoblox.me"
  subject_alternative_names = ["*.legoblox.me"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route 53 A record pointing to CloudFront (HTTPS)
resource "aws_route53_record" "site_a" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "legoblox.me"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# IPv6 record for CloudFront
resource "aws_route53_record" "site_aaaa" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "legoblox.me"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# WWW subdomain pointing to CloudFront (HTTPS)
resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.legoblox.me"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# WWW IPv6 record for CloudFront
resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.legoblox.me"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# =====================
# iCloud Mail DNS Records
# =====================

# MX Records for iCloud Mail
resource "aws_route53_record" "icloud_mx" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "legoblox.me"
  type    = "MX"
  ttl     = 3600
  records = [
    "10 mx01.mail.icloud.com",
    "10 mx02.mail.icloud.com"
  ]
}

# SPF Record for iCloud Mail
resource "aws_route53_record" "icloud_spf" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "legoblox.me"
  type    = "TXT"
  ttl     = 3600
  records = ["v=spf1 include:icloud.com ~all"]
}

# DKIM Record for iCloud Mail
resource "aws_route53_record" "icloud_dkim" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "sig1._domainkey.legoblox.me"
  type    = "CNAME"
  ttl     = 3600
  records = ["sig1.dkim.legoblox.me.at.icloudmailadmin.com"]
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "route53_name_servers" {
  value = aws_route53_zone.primary.name_servers
}

output "certificate_arn" {
  value = aws_acm_certificate.site.arn
}

# =====================
# OpenResty (Nginx + Lua) EC2 Server
# =====================

# VPC - Use default VPC for simplicity
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for OpenResty
resource "aws_security_group" "openresty" {
  name        = "openresty-lua-server"
  description = "Security group for OpenResty Lua web server"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openresty-lua-server"
  }
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Key Pair - You'll need to create this or use an existing one
resource "aws_key_pair" "openresty" {
  key_name   = "openresty-lua-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 Instance with OpenResty
resource "aws_instance" "openresty" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"  # Free tier eligible in this account
  key_name                    = aws_key_pair.openresty.key_name
  vpc_security_group_ids      = [aws_security_group.openresty.id]
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              dnf update -y
              
              # Install dependencies
              dnf install -y gcc make pcre-devel openssl-devel zlib-devel wget tar
              
              # Download and install OpenResty
              cd /tmp
              wget https://openresty.org/download/openresty-1.25.3.1.tar.gz
              tar -xzf openresty-1.25.3.1.tar.gz
              cd openresty-1.25.3.1
              
              ./configure --prefix=/opt/openresty \
                          --with-pcre-jit \
                          --with-http_ssl_module \
                          --with-http_v2_module
              
              make -j$(nproc)
              make install
              
              # Add OpenResty to PATH
              echo 'export PATH=/opt/openresty/bin:/opt/openresty/nginx/sbin:$PATH' >> /etc/profile.d/openresty.sh
              source /etc/profile.d/openresty.sh
              
              # Create directories
              mkdir -p /opt/openresty/nginx/lua
              mkdir -p /opt/openresty/nginx/html
              
              # Create placeholder index.html (will be replaced by deploy script)
              echo '<html><body><h1>OpenResty Ready - Deploy your Lua app!</h1></body></html>' > /opt/openresty/nginx/html/index.html
              
              # Create minimal nginx config (will be replaced by deploy script)
              cat > /opt/openresty/nginx/conf/nginx.conf << 'NGINXEOF'
              worker_processes auto;
              error_log logs/error.log;
              events { worker_connections 1024; }
              http {
                  include mime.types;
                  default_type application/octet-stream;
                  sendfile on;
                  keepalive_timeout 65;
                  lua_package_path "/opt/openresty/nginx/lua/?.lua;;";
                  server {
                      listen 80;
                      server_name _;
                      root /opt/openresty/nginx/html;
                      index index.html;
                      location / { try_files $uri $uri/ /index.html; }
                  }
              }
              NGINXEOF
              
              # Create placeholder Lua app (will be replaced by deploy script)
              cat > /opt/openresty/nginx/lua/app.lua << 'LUAEOF'
              local _M = {}
              function _M.api()
                  ngx.header.content_type = "application/json"
                  ngx.say('{"status":"ready","message":"Deploy your Lua app using deploy.ps1"}')
              end
              return _M
              LUAEOF
              
              # Create systemd service
              cat > /etc/systemd/system/openresty.service << 'SERVICEEOF'
              [Unit]
              Description=OpenResty - Lua Web Platform
              After=network.target
              
              [Service]
              Type=forking
              PIDFile=/opt/openresty/nginx/logs/nginx.pid
              ExecStartPre=/opt/openresty/nginx/sbin/nginx -t
              ExecStart=/opt/openresty/nginx/sbin/nginx
              ExecReload=/bin/kill -s HUP $MAINPID
              ExecStop=/bin/kill -s QUIT $MAINPID
              PrivateTmp=true
              
              [Install]
              WantedBy=multi-user.target
              SERVICEEOF
              
              # Start OpenResty
              systemctl daemon-reload
              systemctl enable openresty
              systemctl start openresty
              
              echo "OpenResty installation complete! Deploy your Lua app using deploy.ps1"
              EOF

  tags = {
    Name = "openresty-lua-server"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

# Elastic IP for stable public address
resource "aws_eip" "openresty" {
  instance = aws_instance.openresty.id
  domain   = "vpc"

  tags = {
    Name = "openresty-lua-server"
  }
}

# DNS Record for Lua subdomain
resource "aws_route53_record" "lua_a" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "lua.legoblox.me"
  type    = "A"
  ttl     = 300
  records = [aws_eip.openresty.public_ip]
}

output "openresty_public_ip" {
  value       = aws_eip.openresty.public_ip
  description = "Public IP of the OpenResty Lua server"
}

output "openresty_ssh_command" {
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_eip.openresty.public_ip}"
  description = "SSH command to connect to the server"
}

output "lua_website_url" {
  value       = "http://lua.legoblox.me"
  description = "URL of the Lua-powered website"
}
