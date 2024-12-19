
---
-- Ermittelt alle Entities in der Kategorie auf dem Territorium und gibt
-- sie als Liste zurück.
--
-- <b>QSB:</b> API.SearchEntitiesOfCategoryInTerritory(_Territory, _Category, _PlayerID)
-- <p><b>Alias:</b> GetEntitiesOfCategoryInTerritory</p>
--
-- @param[type=number] _PlayerID    PlayerID [0-8] oder -1 für alle
-- @param[type=number] _Category  Kategorie, der die Entities angehören
-- @param[type=number] _Territory Zielterritorium
-- @within QSB_1_Entity
--
-- @usage
-- local Found = API.GetEntitiesOfCategoryInTerritory(1, EntityCategories.Hero, 5)
--
function API.GetEntitiesOfCategoryInTerritory(_PlayerID, _Category, _Territory)
    return API.SearchEntitiesOfCategoryInTerritory (_Territory, _Category, _PlayerID)
end
GetEntitiesOfCategoryInTerritory = API.GetEntitiesOfCategoryInTerritory;

---
-- Setzt die Ausrichtung des Entity.
--
-- <b>Alias</b>: SetOrientation
--
-- @param               _Entity  Entity (Scriptname oder ID)
-- @param[type=number] _Orientation Neue Ausrichtung
-- @within QSB_1_Entity
--
function API.SetEntityOrientation(_Entity, _Orientation)
    if GUI then
        return;
    end
    local EntityID = GetID(_Entity);
    if EntityID > 0 then
        if type(_Orientation) ~= "number" then
            error("API.SetEntityOrientation: _Orientation is wrong!");
            return
        end
        Logic.SetOrientation(EntityID, API.Round(_Orientation));
    else
        error("API.SetEntityOrientation: _Entity (" ..tostring(_Entity).. ") does not exist!");
    end
end
SetOrientation = API.SetEntityOrientation;