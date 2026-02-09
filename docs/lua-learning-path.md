# 🎮 Lua Learning Path for Beginners

Welcome! This guide will help you learn Lua using both **Roblox** and **your FNAF website**.

---

## ⚠️ Important: Two Different Environments

The Lua code we created (`app.lua`) runs on your **web server**, NOT in Roblox!

| Environment | Where it runs | Lua code location |
|-------------|---------------|-------------------|
| **Your Website** | AWS EC2 server | `lua/app.lua` |
| **Roblox** | Roblox Studio / Roblox servers | Scripts inside Roblox Studio |

They use the same language (Lua) but different APIs!

---

## 🔧 How to Run Lua in Each Place

### Your Website (OpenResty)
```
Edit lua/app.lua → Deploy to EC2 → Visit https://legoblox.me/api
```

### Roblox Studio
```
Open Roblox Studio → Create Script → Write code → Press Play
```

---

## 🔗 Connecting VS Code to Roblox (Rojo)

Yes! You can sync VS Code with Roblox Studio using **Rojo**.

### What is Rojo?
Rojo lets you:
- Write Roblox code in VS Code (with LSP support!)
- Automatically sync changes to Roblox Studio
- Use Git version control for Roblox projects

### Install Rojo

1. **Install Rojo VS Code Extension**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search "Rojo"
   - Install "Rojo" by Rojo

2. **Install Rojo CLI**
   ```powershell
   # Using Aftman (recommended)
   aftman add rojo-rbx/rojo
   
   # Or download from GitHub releases
   # https://github.com/rojo-rbx/rojo/releases
   ```

3. **Install Rojo Plugin in Roblox Studio**
   - Open Roblox Studio
   - Go to Plugins → Manage Plugins
   - Search "Rojo" and install it

### Using Rojo

1. Create a new Rojo project:
   ```powershell
   mkdir my-roblox-game
   cd my-roblox-game
   rojo init
   ```

2. Start the Rojo server:
   ```powershell
   rojo serve
   ```

3. In Roblox Studio, click the Rojo plugin → Connect

4. Now when you edit `.lua` files in VS Code, they sync to Studio!

---

## 🎮 Your Two Lua Learning Paths

| | Roblox | Your Website |
|--|--------|--------------|
| **Lua Version** | Luau (Roblox's enhanced Lua) | LuaJIT (standard Lua 5.1) |
| **What you build** | Games, GUIs, player interactions | APIs, web servers, backends |
| **Special APIs** | `game`, `workspace`, `Players` | `ngx`, `cjson`, HTTP stuff |
| **Test with** | Roblox Studio Play button | Browser / PowerShell |

**They're 90% the same!** Core Lua (variables, tables, functions, loops) works identically in both.

---

## 🚀 Beginner Learning Path

### Week 1-2: Lua Basics (do in BOTH)

These concepts work the same everywhere:

```lua
-- ============ VARIABLES ============
-- Variables store data. Use "local" to create them.

local name = "Freddy"           -- Text (called a "string")
local power = 100               -- Number
local scary = true              -- Boolean (true or false)
local nothing = nil             -- Empty/nothing


-- ============ TABLES ============
-- Tables are containers that hold multiple values

-- Array-style (numbered)
local animatronics = {"Freddy", "Bonnie", "Chica", "Foxy"}
print(animatronics[1])          -- Prints "Freddy" (Lua starts at 1!)

-- Dictionary-style (named keys)
local door = {
    is_closed = true,
    power_drain = 5,
    side = "left"
}
print(door.is_closed)           -- Prints "true"


-- ============ CONDITIONS ============
-- if/then/else lets you make decisions

if power < 20 then
    print("Low power!")
elseif power < 10 then
    print("Critical!")
else
    print("Power OK")
end


-- ============ LOOPS ============
-- Loops repeat code multiple times

-- Count from 1 to 10
for i = 1, 10 do
    print(i)
end

-- Loop through a table
for index, name in ipairs(animatronics) do
    print(index, name)
end

-- Loop through dictionary
for key, value in pairs(door) do
    print(key, value)
end


-- ============ FUNCTIONS ============
-- Functions are reusable blocks of code

function greet(name)
    return "Hello, " .. name    -- .. joins strings together
end

local message = greet("Freddy")
print(message)                  -- Prints "Hello, Freddy"


-- ============ STRING OPERATIONS ============
local first = "Hello"
local second = "World"
local combined = first .. " " .. second    -- "Hello World"
local length = #combined                    -- 11 (length)
local upper = string.upper(combined)        -- "HELLO WORLD"
local lower = string.lower(combined)        -- "hello world"


-- ============ MATH ============
local a = 10
local b = 3
print(a + b)        -- 13 (addition)
print(a - b)        -- 7 (subtraction)
print(a * b)        -- 30 (multiplication)
print(a / b)        -- 3.333... (division)
print(a % b)        -- 1 (remainder/modulo)
print(a ^ b)        -- 1000 (power: 10³)
print(math.floor(3.7))  -- 3 (round down)
print(math.ceil(3.2))   -- 4 (round up)
print(math.random(1, 100))  -- Random number 1-100
```

### Week 3-4: Platform-Specific

#### Roblox-Specific Concepts
```lua
-- Getting the player
local Players = game:GetService("Players")

-- When a player joins
Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " joined!")
end)

-- Creating a part
local part = Instance.new("Part")
part.Position = Vector3.new(0, 10, 0)
part.Parent = workspace

-- Touched event
part.Touched:Connect(function(hit)
    print("Something touched the part!")
end)
```

#### Website-Specific Concepts
```lua
-- Setting response type
ngx.header.content_type = "application/json"

-- Getting URL parameters
local args = ngx.req.get_uri_args()
local name = args.name  -- From ?name=value

-- Sending JSON response
local cjson = require "cjson"
local response = {message = "Hello!"}
ngx.say(cjson.encode(response))
```

---

## 💡 Practice Exercises

### Exercise 1: Variables and Math
Create a power calculator:
```lua
local starting_power = 100
local doors_closed = 2
local drain_per_door = 5

-- Calculate remaining power after 10 ticks
-- Your code here!
```

### Exercise 2: Tables
Create and modify an animatronic tracker:
```lua
local animatronics = {
    {name = "Freddy", location = "Stage", danger = 5},
    {name = "Bonnie", location = "Backstage", danger = 7},
}

-- Add Chica to the list
-- Find the most dangerous animatronic
-- Your code here!
```

### Exercise 3: Functions
Create a function that checks if it's safe:
```lua
function isSafe(leftDoor, rightDoor, power)
    -- Return true if both doors are closed AND power > 20
    -- Your code here!
end

print(isSafe(true, true, 50))   -- Should print true
print(isSafe(true, false, 50))  -- Should print false
print(isSafe(true, true, 10))   -- Should print false
```

### Exercise 4: On Your Website
Add a new endpoint to `app.lua`:
```lua
-- Create /api/jumpscare that returns:
-- {scared: true, animatronic: "Freddy", message: "BOO!"}
```

### Exercise 5: In Roblox
Create a part that:
1. Changes color when touched
2. Plays a sound
3. Prints who touched it

---

## 📚 Learning Resources

### Lua Language
- [Learn Lua in 15 Minutes](https://learnxinyminutes.com/docs/lua/)
- [Programming in Lua (free book)](https://www.lua.org/pil/)
- [Lua Reference Manual](https://www.lua.org/manual/5.1/)

### Roblox Development
- [Roblox Creator Hub](https://create.roblox.com/docs)
- [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/)
- [DevForum Tutorials](https://devforum.roblox.com/c/resources/tutorials)

### OpenResty (Web)
- [OpenResty Getting Started](https://openresty.org/en/getting-started.html)
- [Lua Nginx Module](https://github.com/openresty/lua-nginx-module)

### Tools
- [Rojo](https://rojo.space/) - Sync VS Code with Roblox Studio
- [Selene](https://kampfkarren.github.io/selene/) - Lua linter
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua formatter

---

## 🎯 Quick Reference Card

```lua
-- VARIABLES
local x = 10              -- number
local s = "text"          -- string
local b = true            -- boolean
local n = nil             -- nothing

-- TABLES
local arr = {1, 2, 3}     -- array
local dict = {a=1, b=2}   -- dictionary
arr[1]                    -- first element
#arr                      -- length
dict.a or dict["a"]       -- access

-- CONDITIONALS
if x > 5 then
elseif x < 0 then
else
end

-- LOOPS
for i = 1, 10 do end
for i, v in ipairs(arr) do end
for k, v in pairs(dict) do end
while condition do end

-- FUNCTIONS
function name(params)
    return value
end

-- STRINGS
"hello" .. "world"        -- concatenate
#"hello"                  -- length (5)
string.format("%s %d", "age", 25)

-- OPERATORS
==    -- equal
~=    -- not equal
and   -- logical and
or    -- logical or
not   -- logical not
```

---

## 🏆 Your Progress Tracker

- [ ] Week 1: Variables, strings, numbers
- [ ] Week 2: Tables, loops, conditions
- [ ] Week 3: Functions, modules
- [ ] Week 4: Platform APIs (Roblox OR Web)
- [ ] Week 5: Build a small project
- [ ] Week 6: Build something bigger!

---

Good luck on your coding journey! Remember: the best way to learn is to **break things and fix them**! 🚀
