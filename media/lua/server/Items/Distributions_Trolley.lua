
local TROLLEY_TYPES = {
    "PROJTrolley.CartContainer",
}

for _, item_type in ipairs(TROLLEY_TYPES) do
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, 2)

    table.insert(ProceduralDistributions["list"]["CrateCarpentry"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateCarpentry"].items, 2)

    table.insert(ProceduralDistributions["list"]["CrateRandomJunk"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateRandomJunk"].items, 1)

    table.insert(ProceduralDistributions["list"]["CrateTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateTools"].items, 0.5)

    table.insert(ProceduralDistributions["list"]["DrugShackTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["DrugShackTools"].items, 1)

    table.insert(ProceduralDistributions["list"]["FireStorageTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["FireStorageTools"].items, 3)

    table.insert(ProceduralDistributions["list"]["ForestFireTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ForestFireTools"].items, 2)

    table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, item_type)
    table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, 2)

    table.insert(ProceduralDistributions["list"]["GarageTools"].items, item_type);
    table.insert(ProceduralDistributions["list"]["GarageTools"].items, 1)

    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, item_type)
    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, 3)

    table.insert(ProceduralDistributions["list"]["LoggingFactoryTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["LoggingFactoryTools"].items, 3)

    table.insert(ProceduralDistributions["list"]["ToolStoreCarpentry"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreCarpentry"].items, 2)

    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, 3)

    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, 1)

    table.insert(ProceduralDistributions["list"]["CrateMechanics"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateMechanics"].items, 1)

    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, 1)

    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, item_type)
    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, 1)

    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, 1)

    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, 2)
end
