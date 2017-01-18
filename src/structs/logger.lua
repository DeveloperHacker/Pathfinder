
local Logger = {}

Logger.printInfo = true
Logger.printErrorMessages = false
Logger.printInputServerMessages = true
Logger.printInputRobotMessages = false
Logger.printOutputMessages = false

function Logger.info(text)
    if (Logger.printInfo) then
        print(string.format("[INFO] - %s", text))
    end
end

function Logger.errorMessage(text)
    if (Logger.printErrorMessages) then
        print(string.format("[ERROR-MESSAGE] - %s", text))
    end
end

function Logger.inputServerMessage(text)
    if (Logger.printInputServerMessages) then
        print(string.format("[INPUT-MESSAGE] - %s", text))
    end
end

function Logger.inputRobotMessage(text)
    if (Logger.printInputRobotMessages) then
        print(string.format("[INPUT-MESSAGE] - %s", text))
    end
end

function Logger.outputMessage(text)
    if (Logger.printOutputMessages) then
        print(string.format("[OUTPUT-MESSAGE] - %s", text))
    end
end

return Logger
