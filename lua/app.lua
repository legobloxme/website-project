--[[
================================================================================
    FNAF SECURITY OFFICE - LUA WEB APPLICATION
    Powered by OpenResty (Nginx + LuaJIT)
================================================================================

    WHAT IS THIS FILE?
    ------------------
    This is a Lua file that runs on the SERVER (the computer in the cloud).
    When someone visits your website, this code runs and sends back data.
    
    Think of it like this:
    - User clicks a button on the website (frontend/browser)
    - The browser sends a request to your server
    - This Lua code processes the request
    - It sends back a response (like JSON data)
    - The website displays the result
    
    WHAT IS LUA?
    ------------
    Lua is a simple, fast programming language. It's used in:
    - Video games (Roblox, World of Warcraft addons)
    - Web servers (like this one!)
    - Game engines (Love2D, Corona)
    
    WHAT IS JSON?
    -------------
    JSON (JavaScript Object Notation) is a way to format data.
    It looks like this: {"name": "Freddy", "scary": true}
    It's how the server talks to the browser in a structured way.
    
================================================================================
--]]


--[[
    _M is a Lua TABLE (like a container/folder)
    We put all our functions inside it so we can use them from other files.
    The underscore M means "module" - it's a naming convention in Lua.
--]]
local _M = {}


--[[
================================================================================
    DOOR STATE STORAGE
================================================================================
    
    This is where we keep track of whether each door is open or closed.
    In FNAF, closing doors protects you from animatronics but uses power!
    
    IMPORTANT: This is stored in MEMORY on the server.
    - When the server restarts, this resets to default values
    - Each user shares the same door state (it's not per-player)
    
    For a real game, you'd use a database instead!
--]]

-- Create a table to store door information
-- Tables in Lua are like dictionaries/objects in other languages
local doors = {
    -- Left door: starts CLOSED (secured)
    left = {
        is_closed = true,                -- true = door is closed/blocking
        power_drain = 5,                 -- how much % power it uses per tick
        blocked_animatronics = 0         -- count of animatronics blocked
    },
    
    -- Right door: starts CLOSED (secured)
    right = {
        is_closed = true,
        power_drain = 5,
        blocked_animatronics = 0
    }
}

-- Starting power level (0-100%)
-- In the real FNAF, you start at 100% and it slowly drains
local power_level = 100


--[[
================================================================================
    FUNCTION: Toggle a Door (Open or Close it)
================================================================================
    
    This function is called when someone clicks a door button.
    It TOGGLES the door - if it's open, close it. If closed, open it.
    
    HOW IT WORKS:
    1. Check which door was requested (left or right)
    2. Flip the is_closed value (true becomes false, false becomes true)
    3. Send back the new door state as JSON
    
    PARAMETERS:
    - None directly, but we read from the URL like: /api/door?side=left
    
    RETURNS:
    - JSON with the door's new state
--]]
function _M.toggle_door()
    -- Tell the browser we're sending JSON data back
    -- This "header" helps the browser know how to read our response
    ngx.header.content_type = "application/json"
    
    -- We need cjson to convert Lua tables to JSON text
    -- "require" loads another Lua file/library (cjson comes with OpenResty)
    local cjson = require "cjson"
    
    -- Get the URL parameters (the ?side=left part of the URL)
    -- ngx.req.get_uri_args() gives us a table of all URL parameters
    local args = ngx.req.get_uri_args()
    
    -- Get the "side" parameter from the URL
    -- If someone visits /api/door?side=left, this gives us "left"
    local side = args.side
    
    -- VALIDATION: Make sure they gave us a valid door side
    -- We need to check because someone might send bad data!
    if side ~= "left" and side ~= "right" then
        -- If they didn't say "left" or "right", send an error
        -- HTTP status 400 means "Bad Request" (user made a mistake)
        ngx.status = 400
        ngx.say(cjson.encode({
            error = true,
            message = "Invalid door! Use ?side=left or ?side=right"
        }))
        return  -- Stop the function here, don't continue
    end
    
    -- Get the door object from our doors table
    -- This is like: doors["left"] or doors["right"]
    local door = doors[side]
    
    -- TOGGLE the door state!
    -- "not" flips a boolean: not true = false, not false = true
    door.is_closed = not door.is_closed
    
    -- If door is now CLOSED, and we have power, drain some power
    if door.is_closed and power_level > 0 then
        -- Deduct power (closing doors uses electricity!)
        power_level = power_level - 2
        
        -- Make sure power doesn't go below 0
        if power_level < 0 then
            power_level = 0
        end
    end
    
    -- RANDOM: Sometimes an animatronic tries to get in when door closes!
    -- math.random() gives a number between 0 and 1
    local animatronic_blocked = false
    if door.is_closed and math.random() > 0.7 then
        -- 30% chance an animatronic was blocked
        door.blocked_animatronics = door.blocked_animatronics + 1
        animatronic_blocked = true
    end
    
    -- Build the response data
    -- This is a Lua table that we'll convert to JSON
    local response = {
        success = true,                    -- The operation worked
        door = side,                       -- Which door (left or right)
        is_closed = door.is_closed,        -- New state (true = closed)
        status = door.is_closed and "SECURED" or "OPEN",  -- Human-readable
        power_remaining = power_level,     -- Current power level
        animatronic_blocked = animatronic_blocked,  -- Did we block one?
        total_blocked = door.blocked_animatronics,  -- Total blocked count
        message = door.is_closed 
            and "Door secured! Power is draining..." 
            or "Door opened! Saving power but exposed!"
    }
    
    -- Send the response!
    -- cjson.encode() converts our Lua table to a JSON string
    -- ngx.say() sends that string to the browser
    ngx.say(cjson.encode(response))
end


--[[
================================================================================
    FUNCTION: Get status of BOTH doors
================================================================================
    
    This function returns the current state of both doors.
    The website calls this periodically to keep the display updated.
    
    RETURNS:
    - JSON with both doors' states and power level
--]]
function _M.get_doors()
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- Build response with both doors
    local response = {
        doors = {
            -- Spread operator doesn't exist in Lua, so we build it manually
            left = {
                is_closed = doors.left.is_closed,
                status = doors.left.is_closed and "SECURED" or "OPEN",
                blocked = doors.left.blocked_animatronics
            },
            right = {
                is_closed = doors.right.is_closed,
                status = doors.right.is_closed and "SECURED" or "OPEN",
                blocked = doors.right.blocked_animatronics
            }
        },
        power = power_level,
        power_warning = power_level < 30  -- Warn if power is low!
    }
    
    ngx.say(cjson.encode(response))
end


--[[
================================================================================
    FUNCTION: Main API endpoint
================================================================================
    
    This is a general API endpoint that returns info about the security system.
    It's like a "status check" - gives an overview of everything.
    
    RETURNS:
    - JSON with system status, animatronic positions, power, etc.
--]]
function _M.api()
    -- Set the Content-Type header to tell browsers this is JSON
    ngx.header.content_type = "application/json"
    
    -- Load the cjson library to convert our data to JSON format
    local cjson = require "cjson"
    
    -- Build a table with all our response data
    -- Think of a table like a box that holds labeled items
    local response = {
        status = "success",                                    -- Did the request work?
        message = "Welcome to Freddy Fazbear's Pizza Security System",
        timestamp = ngx.now(),                                 -- Current time (Unix timestamp)
        server = "OpenResty",                                  -- What server software we use
        lua_version = _VERSION,                                -- Which Lua version (LuaJIT 2.1)
        
        -- List of animatronics (a table inside a table!)
        animatronics = {
            { name = "Freddy Fazbear", location = "Show Stage", status = "active" },
            { name = "Bonnie", location = "Backstage", status = "active" },
            { name = "Chica", location = "Dining Area", status = "active" },
            { name = "Foxy", location = "Pirate Cove", status = "dormant" }
        },
        
        power_remaining = power_level,                         -- Current power (uses our variable!)
        current_night = 5,                                     -- Night 5 is the hardest!
        
        -- Door states
        left_door = doors.left.is_closed and "SECURED" or "OPEN",
        right_door = doors.right.is_closed and "SECURED" or "OPEN"
    }
    
    -- Convert to JSON and send to the browser
    ngx.say(cjson.encode(response))
end


--[[
================================================================================
    FUNCTION: Get current server time
================================================================================
    
    Simple endpoint that just returns the current date and time.
    This shows how easy it is to make new endpoints!
    
    RETURNS:
    - Plain text with the current date/time
--]]
function _M.time()
    -- Plain text, not JSON
    ngx.header.content_type = "text/plain"
    
    -- os.date() returns the current date/time as a string
    -- ".." is Lua's way to join strings together (concatenation)
    ngx.say("Current server time: " .. os.date())
end


--[[
================================================================================
    FUNCTION: Echo back request details
================================================================================
    
    This is a debugging/testing endpoint. It echoes back whatever you send it.
    Useful for seeing what data your browser is sending!
    
    TRY IT:
    - Visit /echo?name=Mike&job=nightguard
    - The response will show you those parameters!
    
    RETURNS:
    - JSON with all the request details
--]]
function _M.echo()
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- Read the request body (for POST requests)
    -- Some requests send data in the "body" instead of the URL
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    
    -- Build response with all request info
    local response = {
        method = ngx.req.get_method(),      -- GET, POST, PUT, DELETE, etc.
        uri = ngx.var.request_uri,          -- The URL path they visited
        headers = ngx.req.get_headers(),    -- All HTTP headers
        args = ngx.req.get_uri_args(),      -- URL parameters (?key=value)
        body = body                          -- Request body (if any)
    }
    
    ngx.say(cjson.encode(response))
end


--[[
================================================================================
    FUNCTION: Get animatronic positions
================================================================================
    
    Returns where each animatronic currently is.
    Positions are RANDOMIZED to simulate them moving around!
    
    In the real FNAF, you'd check cameras to see where they are.
    Here, we just pick random locations each time you ask.
    
    RETURNS:
    - JSON with each animatronic's location and danger level
--]]
function _M.animatronics()
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- List of all possible locations in the pizzeria
    -- This is a Lua "array" (table with numbered indexes)
    local locations = {
        "Show Stage",       -- [1]
        "Backstage",        -- [2]
        "Dining Area",      -- [3]
        "Restrooms",        -- [4]
        "Kitchen",          -- [5]
        "East Hall",        -- [6]
        "West Hall",        -- [7]
        "Supply Closet",    -- [8]
        "Pirate Cove",      -- [9]
        "Office Door"       -- [10] <- DANGER! They're at your door!
    }
    
    -- Build animatronic data with random positions
    -- math.random(#locations) picks a random number from 1 to 10
    -- #locations means "length of locations" (which is 10)
    local animatronics = {
        {
            name = "Freddy Fazbear",
            location = locations[math.random(#locations)],
            aggression = math.random(1, 10)  -- How dangerous (1-10)
        },
        {
            name = "Bonnie",
            location = locations[math.random(#locations)],
            aggression = math.random(1, 10)
        },
        {
            name = "Chica",
            location = locations[math.random(#locations)],
            aggression = math.random(1, 10)
        },
        {
            name = "Foxy",
            location = locations[math.random(#locations)],
            aggression = math.random(1, 10)
        }
    }
    
    -- Send the data
    ngx.say(cjson.encode({
        animatronics = animatronics,
        night = 5,
        time = os.date("%I:%M %p"),         -- Formatted time like "12:00 AM"
        doors = {
            left = doors.left.is_closed,
            right = doors.right.is_closed
        }
    }))
end


--[[
================================================================================
    FUNCTION: Get power status
================================================================================

    Returns current power level and drain rate.
    In FNAF, running out of power = game over!
    
    - Doors drain power when CLOSED (5% each)
    - Cameras drain power
    - Lights drain power
    
    RETURNS:
    - JSON with power info and warnings
--]]
function _M.power()
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- Calculate drain rate based on what's active
    -- Each closed door adds to the drain
    local drain_rate = 1  -- Base drain
    
    -- If left door is closed, add its drain
    if doors.left.is_closed then
        drain_rate = drain_rate + doors.left.power_drain
    end
    
    -- If right door is closed, add its drain  
    if doors.right.is_closed then
        drain_rate = drain_rate + doors.right.power_drain
    end
    
    -- Simulate power drain over time
    -- In a real app, you'd track time more precisely
    if power_level > 0 then
        power_level = power_level - (drain_rate * 0.1)
        if power_level < 0 then
            power_level = 0
        end
    end
    
    -- Build response
    local response = {
        power_remaining = math.floor(power_level),     -- No decimals
        drain_rate = drain_rate,
        estimated_time_left = math.floor(power_level / drain_rate) .. " minutes",
        warning = power_level < 30,         -- Warn under 30%
        critical = power_level < 10,        -- Critical under 10%
        game_over = power_level <= 0,       -- Game over at 0%
        
        -- Show what's draining power
        power_usage = {
            base = 1,
            left_door = doors.left.is_closed and 5 or 0,
            right_door = doors.right.is_closed and 5 or 0
        }
    }
    
    ngx.say(cjson.encode(response))
end


--[[
================================================================================
    FUNCTION: Reset the game/power
================================================================================
    
    Resets power to 100% and door states.
    Like starting a new night!
--]]
function _M.reset()
    ngx.header.content_type = "application/json"
    local cjson = require "cjson"
    
    -- Reset everything
    power_level = 100
    doors.left.is_closed = true
    doors.left.blocked_animatronics = 0
    doors.right.is_closed = true
    doors.right.blocked_animatronics = 0
    
    ngx.say(cjson.encode({
        success = true,
        message = "Night reset! Power at 100%, doors secured.",
        power = power_level
    }))
end


--[[
================================================================================
    EXPORT THE MODULE
================================================================================
    
    This line MUST be at the end of the file!
    It makes all our functions available to other files.
    
    When nginx.conf does: local app = require "app"
    It gets this _M table with all our functions attached.
--]]
return _M


--[[
================================================================================
    QUICK REFERENCE - COMMON LUA CONCEPTS USED HERE:
================================================================================

    VARIABLES:
        local x = 10          -- Create a local variable
        x = x + 1             -- Change it
        
    STRINGS:
        "hello"               -- A string
        "hello" .. " world"   -- Join strings with ..
        
    TABLES (like objects/dictionaries):
        local t = {}          -- Empty table
        local t = {a = 1}     -- Table with key 'a' = 1
        t.a                   -- Access value (equals 1)
        t["a"]                -- Same thing, different syntax
        
    ARRAYS (tables with numbered indexes):
        local arr = {"a", "b", "c"}
        arr[1]                -- First item (Lua starts at 1, not 0!)
        #arr                  -- Length (3)
        
    FUNCTIONS:
        function name()       -- Define a function
            return value      -- Return something
        end
        
    CONDITIONS:
        if x > 10 then
            -- do something
        elseif x < 5 then
            -- do another thing
        else
            -- do default thing
        end
        
    TERNARY (inline if):
        local result = condition and "yes" or "no"
        
    NIL:
        nil                   -- Like "null" or "nothing"
        
================================================================================
--]]
