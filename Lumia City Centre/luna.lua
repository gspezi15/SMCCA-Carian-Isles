local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Lumia City Centre",
        [1] = "Lumia City Sewers",
		[2] = "City Centre",
        [3] = "Riverside Pathway",
        [4] = "Arena",
        [5] = "",
        [6] = "",
        [7] = "",
        [8] = "",
        [9] = "",
        [10] = "",
        [11] = "",
        [12] = "",
        [13] = "",
        [14] = "",
        [15] = "",
        [16] = "",
        [17] = "",
        [18] = "",
        [19] = "",
        [20] = ""
        }
        
        local ShopSystem = require("ShopSystem")

        local myShop = ShopSystem.create{}

        -- shopsystem stuff --
local myShop = ShopSystem.create{music = "Shop.ogg"}
local miscShop = ShopSystem.create{music = "34 Buy Somethin' Will Ya!.ogg"}
local bootShop = ShopSystem.create{music = ""}
local animalShop = ShopSystem.create{}

-- variable currency stuff --
local simpleVar = 0
local simpleVar2 = 0

local function handleVarCurrency(shopItem)
    if simpleVar >= shopItem.price then
        simpleVar = simpleVar - shopItem.price
    end
end

local function handleVarCurrency2(shopItem)
    if simpleVar2 >= shopItem.price then
        simpleVar2 = simpleVar2 - shopItem.price
    end
end

----------------------

local mushroom = myShop:RegisterItem{NPCid =   9, inEgg = true, image = shopItems, price = 10,  amount = 5, name = "Mushroom", sourceX = 0, sourceY = 0, sourceWidth = 32, sourceHeight = 32, currency = simpleVar, handleVarCurrency = handleVarCurrency}
local fire =     myShop:RegisterItem{NPCid =  14, image = shopItems, price = 20,  amount = 5, name = "Fire Flower", description = "A burning flower!?", sourceX = 0, sourceY = 32, sourceWidth = 32, sourceHeight = 32, currency = coinCounter}
local leaf =     myShop:RegisterItem{NPCid =  34, image = shopItems, price = 30,  amount = 5, name = "Leaf", sourceX = 0, sourceY = 64, sourceWidth = 32, sourceHeight = 32, currency = coinCounter, description = "<wave 2>something seems strange about this leaf...</wave>"}
local tanooki =  myShop:RegisterItem{NPCid = 169, image = shopItems, price = 80,  amount = 5, name = "Tanooki Suit", sourceX = 0, sourceY = 96, sourceWidth = 32, sourceHeight = 32, currency = simpleVar2, description = "tanookieeeeeeeeeeee", handleVarCurrency = handleVarCurrency2}
local hammer =   myShop:RegisterItem{NPCid = 170, inEgg = true, image = shopItems, price = 80,  amount = 5, name = "Hammer Suit", sourceX = 0, sourceY = 128, sourceWidth = 32, sourceHeight = 32, currency = coinCounter, description = "No one stands a chance if you wear this suit."}
local ice =      myShop:RegisterItem{NPCid = 264, useReserve = true, image = shopItems, closeAfterPurchase = true, price = 30,  amount = 5, name = "Ice Flower", sourceX = 0, sourceY = 160, sourceWidth = 32, sourceHeight = 32, currency = coinCounter, description = "It's so cold!!"}

mushroom.description = "<tremble 2>Mmm.. a tasty mushroom!</tremble>"

        function onEvent (eventName)
        if eventName == "Open Shop" then 
         myShop:open()
        end
        end
        