---@class Planet
---@field id number
---@field name string[]
---@field type string[]
---@field biosphere string[]
---@field classification string[]
---@field habitability string[]
---@field description string[]
---@field iconPath string
---@field hasAtmosphere boolean
---@field isSanctuary boolean
---@field isInSafeZone boolean
---@field systemId number
---@field positionInSystem number
---@field satellites number[]
---@field center number[]
---@field gravity number
---@field radius number
---@field atmosphereThickness number
---@field atmosphereRadius number
---@field surfaceArea number
---@field surfaceAverageAltitude number
---@field surfaceMaxAltitude number
---@field surfaceMinAltitude number
---@field GM number
---@field ores = string[][]
---@field territories number
Planet = {}

---@type Planet[][]
atlas = {
    --actual number 0 but IDE doesn't like it
    [1] = {
        [1] = --[[---@type Planet]] {
            id = 1,
            name = { "Madis", "Madis", "Madis"},
            type = { "Planet", "Planète", "Planet"},
            biosphere = { "Barren", "Stérile", "Ödnis"},
            classification = { "Hyperthermoplanet", "Hyperthermoplanète", "Hyperthermoplanet"},
            habitability = { "Low", "Faible", "Gering"},
            description = {
                [[Madis is a barren wasteland of a rock, it sits closest to the sun and temperatures reach extreme highs during the day. The Arkship geological survey reports long rocky valleys intermittently separated by small ravines.]],
                [[Madis est un désert rocheux stérile, elle est située au plus près du soleil et les températures atteignent des sommets extrêmes pendant la journée. L'étude géologique de l'Arche fait état de longues vallées rocheuses séparées par intermittence par de petits ravins.]],
                [[Madis ist eine karge Felswüste, welche der Sonne am nächsten liegt und deren Temperaturen tagsüber extreme Werte erreichen. Die geologische Untersuchung des Archenschiffes berichtet von langen felsigen Tälern, die von kleinen Schluchten unterbrochen werden.]]
            },
            iconPath = "gui/screen_unit/img/planets/madis.png",
            hasAtmosphere = true,
            isSanctuary = false,
            isInSafeZone = true,
            systemId = 0,
            positionInSystem = 1,
            satellites = { 10, 11, 12},
            center = { 17465536.00, 22665536.00, -34464.00 },
            gravity = 3.5325,
            radius = 44300.00,
            atmosphereThickness = 6200.00,
            atmosphereRadius = 50700.00,
            surfaceArea = 24661377024,
            surfaceAverageAltitude = 750,
            surfaceMaxAltitude = 850,
            surfaceMinAltitude = 670,
            GM = 6932495925.00,
            ores = {
                {"Hematite","Hématite","Hämatit"},
                {"Bauxite","Bauxite","Bauxit"},
                {"Quartz","Quartz","Quarz"},
                {"Coal","Charbon","Kohle"},
                {"Natron","Natron","Soda"},
                {"Garnierite","Garniérite","Garnierit"}
            },
            territories = 30722
        }
    }
}