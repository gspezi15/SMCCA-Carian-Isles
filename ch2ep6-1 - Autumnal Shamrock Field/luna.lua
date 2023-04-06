local rain = SFX.open(Misc.resolveSoundFile("Falling Rain.spc"))
local rainSFX

function onLoadSection1()
    SFX.play(rain, 0.5, 0)
end
-- SFX.play(sound, volume, loops [0 means forever])

-- the section where to stop the rain SFX
function onLoadSection2()
    if rainSFX ~= nil then -- just in case if the player manages to reach this section while SFX is not playing
        rainSFX:stop()
    end
end