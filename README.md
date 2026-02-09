# 🎮 FNAF Security Office - Lua Web Application

A Five Nights at Freddy's themed website built with **Lua** running on **AWS**!

This project demonstrates how to build a dynamic website using:
- **Lua** (programming language) for the backend server code
- **OpenResty** (Nginx + LuaJIT) as the web server
- **AWS EC2** for hosting the server
- **AWS CloudFront** for HTTPS and CDN
- **Terraform** for infrastructure as code

---

## 🌐 Live Website

**https://legoblox.me**

---

## 📁 Project Structure Explained

```
website-project/
│
├── index.html          # The main webpage (HTML/CSS/JavaScript)
│                       # This is what users see in their browser
│
├── lua/                # Lua server code (backend)
│   ├── app.lua         # Main Lua application with all the API endpoints
│   ├── nginx.conf      # Web server configuration
│   ├── deploy.ps1      # Script to upload code to the server
│   └── README.md       # Documentation for the Lua code
│
└── terraform/          # Infrastructure as Code (AWS setup)
    ├── main.tf         # All AWS resources defined here
    ├── terraform.tfstate   # Current state of your infrastructure
    └── *.log           # Log files from terraform commands
```

---

## 🔤 What is What? (Beginner's Guide)

### Frontend vs Backend

| Term | What it means | In this project |
|------|---------------|-----------------|
| **Frontend** | Code that runs in the user's browser | `index.html` (HTML, CSS, JavaScript) |
| **Backend** | Code that runs on the server | `lua/app.lua` (Lua code) |
| **API** | A way for frontend to talk to backend | URLs like `/api/door?side=left` |

### The Technologies

| Technology | What it is | Why we use it |
|------------|-----------|---------------|
| **Lua** | A simple programming language | Powers our server-side code |
| **OpenResty** | Nginx web server + LuaJIT | Runs our Lua code on a web server |
| **AWS EC2** | A virtual computer in the cloud | Hosts our OpenResty server |
| **AWS CloudFront** | A CDN (Content Delivery Network) | Provides HTTPS and makes site faster |
| **Terraform** | Infrastructure as Code tool | Sets up all the AWS stuff automatically |

---

## 🎯 How It All Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        USER'S BROWSER                                │
│                                                                     │
│   1. User visits https://legoblox.me                                │
│   2. Browser loads index.html (the FNAF page)                       │
│   3. User clicks a door button                                      │
│   4. JavaScript calls /api/door?side=left                           │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      AWS CLOUDFRONT                                  │
│                                                                     │
│   - Provides HTTPS (secure connection)                              │
│   - Has your SSL certificate                                        │
│   - Forwards requests to EC2                                        │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      AWS EC2 INSTANCE                                │
│                      (Your Server)                                   │
│                                                                     │
│   OpenResty receives the request                                    │
│         │                                                           │
│         ▼                                                           │
│   nginx.conf routes it to the right Lua function                    │
│         │                                                           │
│         ▼                                                           │
│   app.lua processes the request                                     │
│   - Toggles the door state                                          │
│   - Updates power level                                              │
│   - Returns JSON response                                           │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        USER'S BROWSER                                │
│                                                                     │
│   5. JavaScript receives JSON: {"is_closed": true, "power": 98}     │
│   6. Updates the button to show "SECURED"                           │
│   7. Updates the power bar display                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 How to Make Changes

### 1. Edit the Code

- **Change the website look?** → Edit `index.html`
- **Change the server logic?** → Edit `lua/app.lua`
- **Add new API endpoints?** → Edit `lua/app.lua` AND `lua/nginx.conf`

### 2. Deploy to Server

After making changes, upload them to the EC2 server:

```powershell
# From the project root directory
scp -i ~/.ssh/id_rsa lua/app.lua ec2-user@52.62.57.49:/tmp/
scp -i ~/.ssh/id_rsa lua/nginx.conf ec2-user@52.62.57.49:/tmp/
scp -i ~/.ssh/id_rsa index.html ec2-user@52.62.57.49:/tmp/

# Move files and restart server
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo mv /tmp/app.lua /opt/openresty/nginx/lua/app.lua && sudo mv /tmp/nginx.conf /opt/openresty/nginx/conf/nginx.conf && sudo mv /tmp/index.html /opt/openresty/nginx/html/index.html && sudo systemctl restart openresty"
```

### 3. Clear CloudFront Cache (if needed)

CloudFront caches your website. After deploying, you might need to invalidate the cache:

```powershell
aws cloudfront create-invalidation --distribution-id E1MPJ32WRIL27Q --paths "/*"
```

---

## 🔧 API Endpoints Reference

| URL | Method | Description |
|-----|--------|-------------|
| `/` | GET | Main FNAF Security Office page |
| `/api` | GET | General status of the security system |
| `/api/door?side=left` | GET | Toggle left door (open/close) |
| `/api/door?side=right` | GET | Toggle right door (open/close) |
| `/api/doors` | GET | Get status of both doors |
| `/api/power` | GET | Get current power level |
| `/api/animatronics` | GET | Get animatronic locations |
| `/api/reset` | GET | Reset game (power to 100%) |
| `/time` | GET | Current server time |
| `/echo` | GET/POST | Echo back request details |

### Example API Response

```json
{
  "success": true,
  "door": "left",
  "is_closed": true,
  "status": "SECURED",
  "power_remaining": 98,
  "animatronic_blocked": false,
  "message": "Door secured! Power is draining..."
}
```

---

## 🏗️ AWS Infrastructure

All AWS resources are managed by Terraform in the `terraform/` folder:

| Resource | Purpose |
|----------|---------|
| **EC2 Instance** | t3.micro running OpenResty + Lua |
| **Elastic IP** | 52.62.57.49 - fixed IP for the server |
| **CloudFront** | CDN with HTTPS (d1bfvras4th4sd.cloudfront.net) |
| **Route53** | DNS management for legoblox.me |
| **ACM Certificate** | SSL certificate for HTTPS |
| **Security Group** | Firewall rules (allow HTTP/SSH) |
| **S3 Bucket** | Storage (legacy, from previous static hosting) |

### Terraform Commands

```powershell
cd terraform

# See what changes would be made
terraform plan

# Apply changes to AWS
terraform apply

# Destroy all resources (careful!)
terraform destroy
```

---

## 🔑 SSH Access

To directly access the server:

```powershell
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49
```

Useful commands once connected:

```bash
# Check if OpenResty is running
sudo systemctl status openresty

# View error logs
sudo tail -f /opt/openresty/nginx/logs/error.log

# View access logs
sudo tail -f /opt/openresty/nginx/logs/access.log

# Restart the server
sudo systemctl restart openresty

# Test nginx configuration
sudo /opt/openresty/nginx/sbin/nginx -t
```

---

## 📚 Learning Resources

### Lua
- [Learn Lua in 15 Minutes](https://learnxinyminutes.com/docs/lua/)
- [Programming in Lua (free book)](https://www.lua.org/pil/)

### OpenResty
- [OpenResty Getting Started](https://openresty.org/en/getting-started.html)
- [OpenResty Lua Nginx Module](https://github.com/openresty/lua-nginx-module)

### Terraform
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Tutorial](https://developer.hashicorp.com/terraform/tutorials)

### AWS
- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

---

## 🎮 FNAF Features

The website includes:
- **Door Controls** - Left and right doors that can be opened/closed
- **Power System** - Power drains when doors are closed
- **Animatronic Tracker** - Shows where Freddy, Bonnie, Chica, and Foxy are
- **Night Timer** - Simulates time passing from 12 AM to 6 AM
- **Neon Aesthetic** - Glowing effects, scanlines, and FNAF theming

---

## 📝 Version History

### v1.0.0 (February 2026) - Milestone 1
- ✅ FNAF themed neon website created
- ✅ Lua backend with OpenResty on EC2
- ✅ Door controls connected to Lua API
- ✅ Power system with server-side state
- ✅ HTTPS via CloudFront
- ✅ Fully commented beginner-friendly code
- ✅ Terraform infrastructure as code

---

## 👤 Author

Built with GitHub Copilot assistance.

---

## 📄 License

This project is for educational purposes.
