Config = {}

-- Possible options: 'esx', 'lib', 'qb'. Adjust this to the framework you want to use. (Default: 'esx')
Config.Framework = 'esx'

-- Set the desired language (locale) here: for example 'en', 'nl', 'de', etc (view the locales/ folder). (Default: 'en')
Config.Locale = 'nl'

-- Options: 'txadmin' - Uses txAdmin's built-in permission system (default)
--          'custom'  - Uses Discord IDs defined in permissions/list.lua for permissions
Config.PermissionSystem = 'custom'

-- RP: Realistic shooting activity | SemiRP: Frequent shooting activity | Combat: Lots of shooting activity
-- Options: 'rp', 'semirp', 'combat'
Config.ServerType = 'rp'

-- Webhook URL for Silent Aim detections (a log channel)
Config.LogSilentAimWebhook = ''

-- Webhook URL for Aim Lock detections (a log channel)
Config.LogAimLockWebhook = ''

-- Webhook URL of when a person tries to stop the resource (a different channel)
Config.LogResourceWebhook = ''

-- When a player is banned (txAdmin only) with "cheat", "hack" or "aimshield" in the ban reason, their logs will be deleted
-- Leave empty if you don't want this functionality
Config.BanWebhook = ''

-- Do you want @everyone to be tagged in Discord when a detection occurs? (true/false)
Config.MentionEveryone = false

--[[

Open the menu with /aimshield or /as. Permissions are automatically set with txAdmin.

Do you have instant headshot kill (or any other instant kill) enabled on your server? Please set 'Citizen.Wait(1)' right before you set the player's HP to 0 / kill him.
This is essential, otherwise the detection will not work on instant kills!

Be sure to execute the queries (query.sql file) so that there can be no problems with the database and the ingame menu.
If there are any problems with the database (rare) after running the queries, change the MySQL reference to your SQL type under 'server_scripts' in the fxmanifest.lua.

If there are any problems, please reach us.

]]
