--[[
    Thanks to Znote as I used his php script to figure out what is being sent to and from the client.
]]

-- What is this? {"count":0,"isreturner":true,"offset":0,"showrewardnews":false,"type":"news"}
-- Only shows up sometimes. First login after client start possibly?

--[[ According to slavidodo
    errors:
    1 => thechnical error
    2 => ?
    3 => login error
    4 => ?
    5 => ?
    6 => two factor error
]]

-- Error function
local function sendError(msg, code)
    http:write(json:marshal({errorCode = code or 3, errorMessage = msg}))
end

function post()
    -- Ignore request if body is too short
    if http.body:len() < 10 then
        return
    end

    -- Placeholders
    local account
    local characters = {}
    local gamePort = config:get('gameProtocolPort')

    -- Get request data
    local result = json:unmarshal(http.body)
    if not result then
        log.Error("")
        return
    end

    if result.type ~= "login" then -- sometimes we get a request with type = "news" - What is this?
        return
    end

    -- Get account data
    local accountName = result["accountname"]
    local password = result["password"]

    if accountName:lower() == "cast" or accountName == "" then
        -- sessionkey should not contain accountName when joining a cast
        accountName = ""

        -- Check for live cast setting
        -- https://github.com/otland/forgottenserver/pull/2230/files
        -- https://github.com/mattyx14/otxserver/blob/otxserv3/path_10_11/config.lua#L53
        if not config:get("liveCastEnabled") and not config:get("enableLiveCasting") then
            return sendError("No cast system is available.", 1)
        end
        
        -- Look for database structure
        if db:singleQuery("SHOW COLUMNS FROM players_online LIKE 'cast_on'", true) ~= nil then -- TODO: Possibly replace with config value
            -- TFS https://github.com/otland/forgottenserver/pull/2230
            if password == "" then
                -- Get active casts without password
                casters = db:query("SELECT p.name, p.sex FROM players_online o LEFT JOIN players p ON o.player_id = p.id WHERE o.cast_on = 1 AND o.cast_password IS NULL")
            else
                -- Get casts with matching password
                casters = db:query("SELECT p.name, p.sex FROM players_online o LEFT JOIN players p ON o.player_id = p.id WHERE o.cast_on = 1 AND o.cast_password = ?", password)
            end
        elseif db:singleQuery("SHOW TABLES LIKE 'live_casts'", true) ~= nil then -- TODO: Possibly replace with config value
            -- OTX
            -- Get active casts
            casters = db:query("SELECT p.name, p.sex, c.password FROM live_casts c LEFT JOIN players p ON c.player_id = p.id WHERE password = ?", (password == "" and 0 or 1))
        else
            return sendError("Unknown cast system database structure.", 1)
        end

        if not casters then
            return sendError("There are no live casts right now.")
        end

        for _, caster in pairs(casters) do
            table.insert(characters, {worldid = 0, name = caster.name, ismale = ((tonumber(caster.sex) == 1) and true or false), tutorial = false})
        end

        -- Get cast protocol port
        -- https://github.com/otland/forgottenserver/pull/2230/files - liveCastProtocolPort
        -- https://github.com/otland/forgottenserver/pull/2007/files - liveCastProtocolPort
        -- https://github.com/mattyx14/otxserver/blob/otxserv3/path_10_11/config.lua#L54 - liveCastPort
        gamePort = config:get("liveCastProtocolPort") or config:get("liveCastPort") or 7173

        -- Mock account data
        account = {
            lastday = 0,
            premdays = 10
        }
    else
        -- Normal login
        account = db:singleQuery("SELECT id, password, lastday, premdays, secret FROM accounts WHERE name = ? AND password = ?", accountName, crypto:sha1(password))
        if not account then
            return sendError("Wrong account name or password.")
        end

        -- Two factor
        if account.secret ~= nil then
            if not validator:validQRToken(result.token, account.secret) then
                return sendError("Invalid two-factor token. Please try again.", 6)
            end
        end

        -- Get account characters
        local chars = db:query("SELECT name, sex FROM players WHERE account_id = ?", tonumber(account.id))

        if not chars then
            return sendError("Character list is empty.")
        end

        for _, c in pairs(chars) do
            table.insert(characters, {worldid = 0, name = c.name, ismale = ((tonumber(c.sex) == 1) and true or false), tutorial = false})
        end
    end

    local data = {
        session = {
            ["fpstracking"] = false,
            ["isreturner"] = true,
            ["returnernotification"] = false,
            ["showrewardnews"] = false,
            ["sessionkey"] = string.format("%s\n%s", accountName, password),
            ["lastlogintime"] = account.lastday,
            ["ispremium"] = (account.premdays > 0),
            ["premiumuntil"] = os.time() + (account.premdays * 86400),
            ["status"] = "active"
        },
        playdata = {
            worlds = {
                {
                    ["id"] = 0,
                    ["name"] = config:get("serverName"),
                    ["externaladdress"] = config:get("ip"),
                    ["externalport"] = gamePort,
                    ["previewstate"] = 0,
                    ["location"] = config:get("location"),
                    ["externaladdressunprotected"] = config:get("ip"),
                    ["externaladdressprotected"] = config:get("ip"),
                    ["anticheatprotection"] = false
                }
            },
            characters = characters
        }
    }

    http:write(json:marshal(data))
end