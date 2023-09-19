-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qb-core']:GetCoreObject()
local RepairCosts = {}

-----------------------
----   Functions   ----
-----------------------

local function IsVehicleOwned(plate)
    local retval = false
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then retval = true end
    return retval
end

-----------------------
----   Threads     ----
-----------------------

-----------------------
---- Server Events ----
-----------------------

AddEventHandler("playerDropped", function()
	local source = source
    RepairCosts[source] = nil
end)

RegisterNetEvent('qb-customs:server:attemptPurchase', function(type, upgradeLevel)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local moneyType = Config.MoneyType
    local balance = Player.Functions.GetMoney(moneyType)

    if type == "repair" then
        local repairCost = RepairCosts[source] or 600
        balance = Player.Functions.GetMoney(Config.RepairMoneyType)
        if balance >= repairCost then
            Player.Functions.RemoveMoney(Config.RepairMoneyType, repairCost, "bennys")
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
	exports['qb-management']:AddMoney("mechanic", repairCost)
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    elseif type == "performance" or type == "turbo" then
        if balance >= vehicleCustomisationPrices[type].prices[upgradeLevel] then
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
            Player.Functions.RemoveMoney(moneyType, vehicleCustomisationPrices[type].prices[upgradeLevel], "bennys")
	exports['qb-management']:AddMoney("mechanic", vehicleCustomisationPrices[type].prices[upgradeLevel])
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    else
        if balance >= vehicleCustomisationPrices[type].price then
            TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
            Player.Functions.RemoveMoney(moneyType, vehicleCustomisationPrices[type].price, "bennys")
	exports['qb-management']:AddMoney("mechanic", vehicleCustomisationPrices[type].price)
        else
            TriggerClientEvent('qb-customs:client:purchaseFailed', source)
        end
    end
end)

RegisterNetEvent('qb-customs:server:updateRepairCost', function(cost)
    local source = source
    RepairCosts[source] = cost
end)

RegisterNetEvent("qb-customs:server:updateVehicle", function(myCar)    
    if IsVehicleOwned(myCar.plate) then
        MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {json.encode(myCar), myCar.plate})
    end
end)

-- Use somthing like this to dynamically enable/disable a location. Can be used to change anything at a location.
-- TriggerEvent('qb-customs:server:UpdateLocation', 'Hayes', 'settings', 'enabled', test)

RegisterNetEvent('qb-customs:server:UpdateLocation', function(location, type, key, value)
    Config.Locations[location][type][key] = value
    TriggerClientEvent('qb-customs:client:UpdateLocation', -1, location, type, key, value)
end)

QBCore.Functions.CreateCallback('qb-customs:server:GetLocations', function(_, cb)
	cb(Config.Locations)
end)


RegisterNetEvent('d3:customs:server:getReceiptData', function(receiptData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local info = {}

    info.vehicleCosmetics = table.concat(receiptData.vehicleCosmetics, " | ")
    info.neonColor = table.unpack(receiptData.neonColor)
    info.wheelSmokeColor = table.unpack(receiptData.wheelSmokeColor)
    info.pearlescentColour = table.unpack(receiptData.pearlescentColour)
    info.windowTint = table.unpack(receiptData.windowTint)
    info.xenonColor = table.unpack(receiptData.xenonColor)
    info.wheelName = table.unpack(receiptData.wheelName)
    info.wheelColor = table.unpack(receiptData.wheelColor)
    info.dashboardColor = table.unpack(receiptData.dashboardColor)
    info.primaryColor = table.unpack(receiptData.primaryColor)
    info.secondaryColor = table.unpack(receiptData.secondaryColor)
    info.interiorColor = table.unpack(receiptData.interiorColor)

    if info.wheelSmokeColor == nil then info.wheelSmokeColor = "None" end

    if (info.neonColor == '' or info.neonColor == nil) then
        info.neonColor = "None"
    elseif (info.vehicleCosmetics == '' or info.vehicleCosmetics == nil) then
        info.vehicleCosmetics = "None" 
    elseif (info.pearlescentColour == '' or info.pearlescentColour == nil) then
        info.pearlescentColour = "None" 
    elseif (info.windowTint == '' or info.windowTint == nil) then
        info.windowTint = "None" 
    elseif (info.xenonColor == '' or info.xenonColor == nil) then
        info.xenonColor = "None" 
    elseif (info.wheelName == '' or info.wheelName == nil) then
        info.wheelName = "None"
    elseif (info.dashboardColor == '' or info.dashboardColor == nil) then
        info.dashboardColor = "None"
    elseif (info.interiorColor == '' or info.interiorColor == nil) then
        info.interiorColor = "None"
    end

    Wait(250)

    Player.Functions.RemoveMoney("bank", 200) -- account (money or bank), amount 
    TriggerClientEvent('QBCore:Notify', src, "You paid 200$ for the receipt.", "success", 5000)
    Player.Functions.AddItem("customs_receipt", 1, false, info)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['customs_receipt'], "add")
end)

