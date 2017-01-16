
local Logger = {}

function Logger.info(text)
    print(string.format("INFO  >>> %s", text))
end

function Logger.message(text)
    print(string.format("MESSAGE > %s", text))
end

return Logger
