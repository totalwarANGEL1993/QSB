-- -------------------------------------------------------------------------- --

--
-- Stellt Cheats und Befehle für einfacheres Testen bereit.
--
-- @set sort=true
-- @within Beschreibung
-- @local
--

Swift.Debug = {
    CheckAtRun           = false;
    TraceQuests          = false;
    DevelopingCheats     = false;
    DevelopingShell      = false;
    Active               = false;
    HistoryIndex         = 0;
    History = {};
};

function Swift.Debug:Initalize()
    QSB.ScriptEvents.DebugChatConfirmed = Swift.Event:CreateScriptEvent("Event_DebugChatConfirmed");
    QSB.ScriptEvents.DebugConfigChanged = Swift.Event:CreateScriptEvent("Event_DebugConfigChanged");

    if Swift.Environment == QSB.Environment.LOCAL then
        self:InitalizeDebugWidgets();
		self:InitalizeQsbDebugHotkeys();

        API.AddScriptEventListener(
            QSB.ScriptEvents.ChatClosed,
            function(...)
                Swift.Debug:ProcessDebugInput(unpack(arg));
            end
        );
    end
end

function Swift.Debug:OnSaveGameLoaded()
    if Swift.Environment == QSB.Environment.LOCAL then
        self:InitalizeDebugWidgets();
        self:InitalizeQsbDebugHotkeys();
    end
end

function Swift.Debug:ActivateDebugMode(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell)
    if Swift.Environment == QSB.Environment.LOCAL then
        return;
    end

    self.CheckAtRun       = _CheckAtRun == true;
    self.TraceQuests      = _TraceQuests == true;
    self.DevelopingCheats = _DevelopingCheats == true;
    self.DevelopingShell  = _DevelopingShell == true;

    Swift.Event:DispatchScriptEvent(
        QSB.ScriptEvents.DebugModeStatusChanged,
        self.CheckAtRun,
        self.TraceQuests,
        self.DevelopingCheats,
        self.DevelopingShell
    );

    Logic.ExecuteInLuaLocalState(string.format(
        [[
            Swift.Debug.CheckAtRun       = %s;
            Swift.Debug.TraceQuests      = %s;
            Swift.Debug.DevelopingCheats = %s;
            Swift.Debug.DevelopingShell  = %s;

            Swift.Event:DispatchScriptEvent(
                QSB.ScriptEvents.DebugModeStatusChanged,
                Swift.Debug.CheckAtRun,
                Swift.Debug.TraceQuests,
                Swift.Debug.DevelopingCheats,
                Swift.Debug.DevelopingShell
            );
            Swift.Debug:InitalizeDebugWidgets();
        ]],
        tostring(self.CheckAtRun),
        tostring(self.TraceQuests),
        tostring(self.DevelopingCheats),
        tostring(self.DevelopingShell)
    ));
end

function Swift.Debug:InitalizeDebugWidgets()
    if Network.IsNATReady ~= nil and Framework.IsNetworkGame() then
        return;
    end
    if self.DevelopingCheats then
        KeyBindings_EnableDebugMode(1);
        KeyBindings_EnableDebugMode(2);
        KeyBindings_EnableDebugMode(3);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignTopLeft/GameClock", 1);
        self.GameClock = true;
    else
        KeyBindings_EnableDebugMode(0);
        XGUIEng.ShowWidget("/InGame/Root/Normal/AlignTopLeft/GameClock", 0);
        self.GameClock = false;
    end
end

function Swift.Debug:InitalizeQsbDebugHotkeys()
    if Framework.IsNetworkGame() then
        return;
    end
    -- Restart map
    Input.KeyBindDown(
        Keys.ModifierControl + Keys.ModifierShift + Keys.ModifierAlt + Keys.R,
        "Swift.Debug:ProcessDebugShortcut('RestartMap')",
        30,
        false
    );
    -- Open chat
    Input.KeyBindDown(
        Keys.ModifierShift + Keys.OemPipe,
        "Swift.Debug:ProcessDebugShortcut('Terminal')",
        30,
        false
    );
end

function Swift.Debug:ProcessDebugShortcut(_Type, _Params)
    if self.DevelopingShell then
        if _Type == "RestartMap" then
            Framework.RestartMap();
        elseif _Type == "Terminal" then
            API.ShowTextInput(GUI.GetPlayerID(), true);
            self.Active = true
            self.HistoryIndex = 0
            -- Last input
            Input.KeyBindDown(
                Keys.Up,
                "Swift.Debug:GetOneHistoryEntryUp()",
                30,
                false
            );
            -- Next Input
            Input.KeyBindDown(
                Keys.Down,
                "Swift.Debug:GetOneHistoryEntryDown()",
                30,
                false
            );
        end
    end
end

function Swift.Debug:GetOneHistoryEntryUp()
    local newIndex = self.HistoryIndex + 1
    if self.History[newIndex] then
        self.HistoryIndex = newIndex
        XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", self.History[newIndex]);
    end
end

function Swift.Debug:GetOneHistoryEntryDown()
    local newIndex = self.HistoryIndex - 1
    if newIndex >= 0 then
        self.HistoryIndex = newIndex
        if newIndex == 0 then
            XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", "");
        else
            XGUIEng.SetText("/InGame/Root/Normal/ChatInput/ChatInput", self.History[newIndex]);
        end
    end
end

function Swift.Debug:ProcessDebugInput(_Input, _PlayerID, _DebugAllowed)
    self.Active = false
    table.insert(self.History, 1, _Input)
    if _DebugAllowed then
        if _Input:lower():find("^restartmap") then
            self:ProcessDebugShortcut("RestartMap");
        elseif _Input:lower():find("^clear") then
            GUI.ClearNotes();
        elseif _Input:lower():find("^version") then
            local Slices = _Input:slice(" ");
            if Slices[2] then
                for i= 1, #Swift.ModuleRegister do
                    if Swift.ModuleRegister[i].Properties.Name ==  Slices[2] then
                        GUI.AddStaticNote("Version: " ..Swift.ModuleRegister[i].Properties.Version);
                    end
                end
                return;
            end
            GUI.AddStaticNote("Version: " ..QSB.Version);
        elseif _Input:find("^> ") then
            GUI.SendScriptCommand(_Input:sub(3), true);
        elseif _Input:find("^>> ") then
            GUI.SendScriptCommand(string.format(
                "Logic.ExecuteInLuaLocalState(\"%s\")",
                _Input:sub(4)
            ), true);
        elseif _Input:find("^< ") then
            GUI.SendScriptCommand(string.format(
                [[Script.Load("%s")]],
                _Input:sub(3)
            ));
        elseif _Input:find("^<< ") then
            Script.Load(_Input:sub(4));
        end
    end
end

-- -------------------------------------------------------------------------- --
-- API

---
-- Aktiviert oder deaktiviert Optionen des Debug Mode.
--
-- <b>Hinweis:</b> Du kannst alle Optionen unbegrenzt oft beliebig ein-
-- und ausschalten.
--
-- <ul>
-- <li><u>Prüfung zum Spielbeginn</u>: <br>
-- Quests werden auf konsistenz geprüft, bevor sie starten. </li>
-- <li><u>Questverfolgung</u>: <br>
-- Jede Statusänderung an einem Quest löst eine Nachricht auf dem Bildschirm
-- aus, die die Änderung wiedergibt. </li>
-- <li><u>Eintwickler Cheaks</u>: <br>
-- Aktivier die Entwickler Cheats. </li>
-- <li><u>Debug Chat-Eingabe</u>: <br>
-- Die Chat-Eingabe kann zur Eingabe von Befehlen genutzt werden. </li>
-- </ul>
--
-- <h3>Konsolenbefehle</h3>
-- <table border=1>
-- <tr>
-- <th><b>Befehl</b></th>
-- <th><b>Parameter</b></th>
-- <th><b>Beschreibung</b></th>
-- </tr>
-- <tr>
-- <td>clear</td>
-- <td></td>
-- <td>Entfernt alle Textnachrichten im Debug-Window.</td>
-- </tr>
-- <tr>
-- <td>restartmap</td>
-- <td></td>
-- <td>Startet die Map sofort neu.</td>
-- </tr>
-- <tr>
-- <td>version</td>
-- <td></td>
-- <td>Zeigt die Version der QSB an.</td>
-- </tr>
-- <tr>
-- <td>stop</td>
-- <td>QuestName</td>
-- <td>Unterbricht den angegebenen Quest.</td>
-- </tr>
-- <tr>
-- <td>start</td>
-- <td>QuestName</td>
-- <td>Startet den angegebenen Quest.</td>
-- </tr>
-- <tr>
-- <td>win</td>
-- <td>QuestName</td>
-- <td>Schließt den angegebenen Quest erfolgreich ab.</td>
-- </tr>
-- <tr>
-- <td>fail</td>
-- <td>QuestName</td>
-- <td>Lässt den angegebenen Quest fehlschlagen</td>
-- </tr>
-- <tr>
-- <td>restart</td>
-- <td>QuestName</td>
-- <td>Startet den angegebenen Quest neu.</td>
-- </tr>
-- <tr>
-- <td>stopped</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen abgebrochener Quests zurück.</td>
-- </tr>
-- <tr>
-- <td>active</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen aktiver Quests zurück.</td>
-- </tr>
-- <tr>
-- <td>won</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen gewonnener Quests zurück.</td>
-- </tr>
-- <tr>
-- <td>failed</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen fehlgeschlagener Quests zurück.</td>
-- </tr>
-- <tr>
-- <td>waiting</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen nicht ausgelöster Quests zurück.</td>
-- </tr>
-- <tr>
-- <td>find</td>
-- <td>Pattern</td>
-- <td>Gibt die Namen von Quests mit ähnlichen Namen zurück.</td>
-- </tr>
-- <tr>
-- <td><</td>
-- <td>Path</td>
-- <td>Läd ein Skript zur Laufzeit ins globale Skript.</td>
-- </tr>
-- <tr>
-- <td><<</td>
-- <td>Path</td>
-- <td>Läd ein Skript zur Laufzeit ins lokale Skript.</td>
-- </tr>
-- <tr>
-- <td>></td>
-- <td>Command</td>
-- <td>Führt die Eingabe als Lua-Befahl im globalen Skript aus.</td>
-- </tr>
-- <tr>
-- <td>>></td>
-- <td>Command</td>
-- <td>Führt die Eingabe als Lua-Befahl im lokalen Skript aus.</td>
-- </tr>
-- </table>
--
-- @param[type=boolean] _CheckAtRun       Custom Behavior prüfen an/aus
-- @param[type=boolean] _TraceQuests      Quest Trace an/aus
-- @param[type=boolean] _DevelopingCheats Cheats an/aus
-- @param[type=boolean] _DevelopingShell  Eingabeaufforderung an/aus
-- @within System
--
function API.ActivateDebugMode(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell)
    Swift.Debug:ActivateDebugMode(_CheckAtRun, _TraceQuests, _DevelopingCheats, _DevelopingShell);
end

-- Aktiviert DisplayScriptErrors, auch wenn der Benutzer das Spiel nicht
-- mit dem Kommandozeilenparameter gestartet hat.
-- @param[type=boolean] _active An/Aus.

function API.ToggleDisplayScriptErrors(_active)
	local Active = _active == true
	g_DisplayScriptErrors = Active

    if Swift.Environment == QSB.Environment.LOCAL then
		GUI.SendScriptCommand([[g_DisplayScriptErrors = ]]..tostring(Active)..[[]])
		return;
    end

	Logic.ExecuteInLuaLocalState([[g_DisplayScriptErrors = ]]..tostring(Active)..[[]])
end
-- #EOF
