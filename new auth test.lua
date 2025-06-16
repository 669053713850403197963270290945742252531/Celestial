local auth = loadstring(readfile("Celestial/new auth.lua"))()

task.wait(2)

if auth.isWhitelisted() then
    print("Welcome " .. auth.get("Identifier"))
    if auth.isOwner() then
        print("You are the Owner")
    end
else
    warn("You are NOT whitelisted.")
end