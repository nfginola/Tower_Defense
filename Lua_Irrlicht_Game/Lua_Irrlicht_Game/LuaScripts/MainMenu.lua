local MainMenu = {}

local topY = 240
MainMenu.fileSelectButton = CButton:new(735, topY + 90, 140, 20, 699, "SELECT FILE", "Resources/Fonts/smallerfont.xml")
MainMenu.playButton = CButton:new(720, topY, 170, 90, 700, "PLAY!", "Resources/Fonts/largefont.xml")
MainMenu.editButton = CButton:new(720, topY + 150, 170, 90, 701, "EDIT!", "Resources/Fonts/largefont.xml")
MainMenu.quitButton = CButton:new(720, topY + 300, 170, 90, 702, "QUIT!", "Resources/Fonts/largefont.xml")


local xGridSet = 2
local zGridSet = 2

local refX = 925
local refY = 417
MainMenu.startXgridPrompt = CScrollbar:new(
    refX, refY, 200, 15, 
    xGridSet, 20,
    1420)

MainMenu.xGridText = CText:new(refX + 210, refY, 40, 15, tostring(xGridSet), "Resources/Fonts/smallerfont.xml")
MainMenu.xGridText:setBGColor(255, 255, 255, 255)
MainMenu.startXtext = CText:new(refX, refY - 25, 300, 15, "X Grid Size", "Resources/Fonts/smallerfont.xml")

MainMenu.startZgridPrompt = CScrollbar:new(
    refX, refY + 25, 200, 15, 
    zGridSet, 20,
    1421)

MainMenu.zGridText = CText:new(refX + 210, refY + 25, 40, 15, tostring(zGridSet), "Resources/Fonts/smallerfont.xml")
MainMenu.zGridText:setBGColor(255, 255, 255, 255)

MainMenu.startZtext = CText:new(refX, refY + 45, 300, 15, "Z Grid Size", "Resources/Fonts/smallerfont.xml")




function MainMenu:hideGUI()
    self.playButton = nil
    self.editButton = nil
    self.quitButton = nil

    self.startXgridPrompt = nil
    self.startXtext = nil
    self.startZgridPrompt = nil
    self.startZtext = nil
    self.xGridText = nil
    self.zGridText = nil
    self.fileSelectButton = nil
end

function MainMenu:run(dt)
   -- We can do some cool text animation GUIs on the background :D 
end

function MainMenu:handleScrollbarEvent(guiID, value)
    if (guiID == 1420) then
        xGridSet = value
        self.xGridText:setText(tostring(xGridSet))
    elseif (guiID == 1421) then
        zGridSet = value
        self.zGridText:setText(tostring(zGridSet))
    end
end


function MainMenu:handleButtonClickEvent(guiID)

    if (guiID == 699) then
        openFileDialog()
        
    -- Play
    elseif (guiID == 700) then
        if (lastFilePathSelected == "") then log("Please select a file..") return end
        gameState = "Play"
        log("Game started")
        local statusGood = startGame()
        if (statusGood) then self:hideGUI() 
        else gameState = "Menu" end

    -- Edit
    elseif (guiID == 701) then
        gameState = "Edit"
        log("Editor started!")
        startEditor(xGridSet, zGridSet)

        self:hideGUI()

    -- Quit
    elseif (guiID == 702) then
        exitApp()

    end
end


return MainMenu