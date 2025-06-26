local auth = loadstring(readfile("Celestial/new auth.lua"))()

task.wait(2)

if auth.isWhitelisted() then
    print("Welcome " .. auth.get("Identifier"))
	print("hwid: " .. auth.get("HWID"))
	print("join date: " .. auth.get("JoinDate"))
	print("discord id: " .. auth.get("DiscordId"))
	print("notes: " .. auth.get("Notes"))
    if auth.isOwner() then
        print("You are the Owner")
    end
else
    warn("You are NOT whitelisted.")
end