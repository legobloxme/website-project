# Deploy Lua code and config to EC2 server
# Usage: .\deploy.ps1

$SERVER = "52.62.57.49"
$KEY = "$HOME\.ssh\id_rsa"
$USER = "ec2-user"

Write-Host "Deploying to $SERVER..." -ForegroundColor Cyan

# Upload Lua app
Write-Host "Uploading app.lua..." -ForegroundColor Yellow
scp -i $KEY .\app.lua "${USER}@${SERVER}:/tmp/app.lua"

# Upload nginx config
Write-Host "Uploading nginx.conf..." -ForegroundColor Yellow
scp -i $KEY .\nginx.conf "${USER}@${SERVER}:/tmp/nginx.conf"

# Upload index.html
Write-Host "Uploading index.html..." -ForegroundColor Yellow
scp -i $KEY ..\index.html "${USER}@${SERVER}:/tmp/index.html"

# Install files and restart
Write-Host "Installing files on server..." -ForegroundColor Yellow
ssh -i $KEY "${USER}@${SERVER}" @"
sudo cp /tmp/app.lua /opt/openresty/nginx/lua/app.lua
sudo cp /tmp/nginx.conf /opt/openresty/nginx/conf/nginx.conf
sudo cp /tmp/index.html /opt/openresty/nginx/html/index.html
sudo /opt/openresty/nginx/sbin/nginx -t && sudo systemctl restart openresty
"@

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "Website: http://legoblox.me" -ForegroundColor Cyan
