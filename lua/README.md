# 🌙 FNAF Lua Web Application

This folder contains the **backend** code - the Lua code that runs on the server!

---

## 📁 Files Explained

| File | What it does |
|------|--------------|
| `app.lua` | The main Lua code with all your API functions. This is where you write your server logic! |
| `nginx.conf` | Tells the web server which URLs go to which Lua functions |
| `deploy.ps1` | PowerShell script to upload your code to the server (not working due to execution policy) |
| `README.md` | This file! |

---

## 🔤 Understanding the Code

### app.lua Structure

```lua
-- 1. Module declaration (at the top)
local _M = {}         -- Creates a container for all our functions

-- 2. Variables (store data)
local doors = {...}   -- Stores door states
local power_level = 100

-- 3. Functions (do things)
function _M.toggle_door()
    -- Code that runs when someone calls /api/door
end

-- 4. Export (at the bottom)
return _M            -- Makes functions available to nginx
```

### nginx.conf Structure

```nginx
location /api/door {           -- When someone visits /api/door
    content_by_lua_block {     -- Run this Lua code:
        local app = require "app"   -- Load app.lua
        app.toggle_door()           -- Call the toggle_door function
    }
}
```

---

## 🚀 API Endpoints

| Endpoint | Function | What it does |
|----------|----------|--------------|
| `/api/door?side=left` | `toggle_door()` | Opens or closes the left door |
| `/api/door?side=right` | `toggle_door()` | Opens or closes the right door |
| `/api/doors` | `get_doors()` | Gets status of both doors |
| `/api/power` | `power()` | Gets current power level |
| `/api/animatronics` | `animatronics()` | Gets where each animatronic is |
| `/api/reset` | `reset()` | Resets game to 100% power |
| `/api` | `api()` | General system status |
| `/time` | `time()` | Current server time |
| `/echo` | `echo()` | Echoes back your request (for debugging) |

---

## 📤 How to Deploy Changes

After editing the Lua code, you need to upload it to the server:

```powershell
# From the project root (website-project folder)

# 1. Upload the files
scp -i ~/.ssh/id_rsa lua/app.lua ec2-user@52.62.57.49:/tmp/
scp -i ~/.ssh/id_rsa lua/nginx.conf ec2-user@52.62.57.49:/tmp/

# 2. Move files and restart server
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo mv /tmp/app.lua /opt/openresty/nginx/lua/app.lua && sudo mv /tmp/nginx.conf /opt/openresty/nginx/conf/nginx.conf && sudo systemctl restart openresty"
```

---

## 🔧 Adding a New API Endpoint

Want to add your own API? Here's how:

### Step 1: Add the function to app.lua

```lua
-- Add this before "return _M" at the bottom of app.lua

function _M.my_new_function()
    -- Set the response type to JSON
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- Create your response data
    local response = {
        message = "Hello from my new endpoint!",
        success = true
    }
    
    -- Send it back
    ngx.say(cjson.encode(response))
end
```

### Step 2: Add the route to nginx.conf

```nginx
# Add this inside the server { } block in nginx.conf

location /api/my-endpoint {
    content_by_lua_block {
        local app = require "app"
        app.my_new_function()
    }
}
```

### Step 3: Deploy and test

```powershell
# Deploy
scp -i ~/.ssh/id_rsa lua/app.lua ec2-user@52.62.57.49:/tmp/
scp -i ~/.ssh/id_rsa lua/nginx.conf ec2-user@52.62.57.49:/tmp/
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo mv /tmp/app.lua /opt/openresty/nginx/lua/app.lua && sudo mv /tmp/nginx.conf /opt/openresty/nginx/conf/nginx.conf && sudo systemctl restart openresty"

# Test
Invoke-RestMethod "https://legoblox.me/api/my-endpoint"
```

---

## 🐛 Debugging Tips

### Check if server is running
```powershell
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo systemctl status openresty"
```

### View error logs
```powershell
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo tail -20 /opt/openresty/nginx/logs/error.log"
```

### Test your config before deploying
```powershell
ssh -i ~/.ssh/id_rsa ec2-user@52.62.57.49 "sudo /opt/openresty/nginx/sbin/nginx -t"
```

### Test an endpoint
```powershell
Invoke-RestMethod "https://legoblox.me/api/power"
```

---

## 📚 Lua Quick Reference

```lua
-- Variables
local x = 10              -- Number
local name = "Freddy"     -- String
local active = true       -- Boolean
local empty = nil         -- Nothing/null

-- Tables (like objects)
local door = {
    is_closed = true,
    power_drain = 5
}
door.is_closed            -- Access with dot
door["is_closed"]         -- Or with brackets

-- Arrays (numbered tables)
local names = {"Freddy", "Bonnie", "Chica"}
names[1]                  -- First item (Lua starts at 1!)
#names                    -- Length (3)

-- Conditions
if power < 30 then
    print("Low power!")
elseif power < 10 then
    print("Critical!")
else
    print("Power OK")
end

-- Loops
for i = 1, 10 do          -- Loop 1 to 10
    print(i)
end

for key, value in pairs(table) do   -- Loop through table
    print(key, value)
end

-- Functions
function greet(name)
    return "Hello, " .. name    -- .. joins strings
end

-- String joining
local message = "Hello" .. " " .. "World"  -- "Hello World"
```

---

## 🔗 Server Paths

| What | Path on Server |
|------|----------------|
| Lua code | `/opt/openresty/nginx/lua/app.lua` |
| Nginx config | `/opt/openresty/nginx/conf/nginx.conf` |
| HTML files | `/opt/openresty/nginx/html/` |
| Error log | `/opt/openresty/nginx/logs/error.log` |
| Access log | `/opt/openresty/nginx/logs/access.log` |

---

## 💡 Tips for Beginners

1. **Always test locally first** - Read through your code before deploying
2. **Check the logs** - If something breaks, the error log tells you why
3. **Use the /echo endpoint** - It shows you exactly what data is being sent
4. **JSON must be valid** - One missing comma breaks everything
5. **Restart after changes** - The server needs to reload after you update files


```bash
sudo tail -f /opt/openresty/nginx/logs/error.log
sudo tail -f /opt/openresty/nginx/logs/access.log
```
