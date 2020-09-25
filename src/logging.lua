-- Lualogging
local tyep, table, string, _tostring, tonumber = type, table, string, tostring, tonumber
local select = select
local error = error
local format = string.format

local this = {}

-- Attribute
-- public
local DEBUG = 'DEBUG'
local INFO = 'INFO'
local WARN = 'WARN'
local ERROR = 'ERROR'
local FATAL = 'FATAL'

-- private
local LEVEL= {'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'}
local MAX_LEVELS = #LEVEL
local LEVEL_FUNCS = {}

--Methods
--public
local new
local prepareLogMsg
local tostring
--private
local LOG_MSG
local disable_level
local assert

function disable_level() end

function assert(exp, ...) 
    if exp then return exp, ... end
    error(format(...), 2)
end

function new(append)
    if type(append) ~= 'function' then return nil, 'Appender must be a function' end

    local logger = {}
    logger.append = append

    logger.setLevel = function(self, level)
        local order = LEVEL[level]
        assert(order, "undefined level '%s'", _tostring(level))
        self.level = level
        self.level_order = order
        for i=1, MAX_LEVELS do
            local name = LEVEL[i]:lower()
            if i >= order then
                self[name] = LEVEL_FUNCS[i]
            else
                self[name] = disable_level
            end
        end
    end

    logger.log = function(self, level, ...)
        local order = LEVEL[level]
        assert(order, "undefined level '%s'", _tostring(level))
        if order < self.level_order then
            return
        end
        return LOG_MSG(self, level, ...)
    end
    logger:setLevel(DEBUG)
    return logger
end

function prepareLogMsg(pattern, dt, level, message)
    local logMsg = pattern or "%date %level %message\n"
    message = string.gsub(message, "%%", "%%%%")
    logMsg = string.gsub(logMsg, "%%date", dt)
    logMsg = string.gsub(logMsg, "%%level", level)
    logMsg = string.gsub(logMsg, "%%message", message)
    return logMsg
end

function tostring(value)
    local str = ''
    local t = type(value)
    if t ~= 'table' then
        if t == 'string' then
            str = string.format("%q", value)
        else
            str = _tostring(value)
        end
    else
        local auxTable = {}
        for i, v in pairs(value) do
            if (tonumber(i) ~= i) then
                table.insert(auxTable, i)
            else
                table.insert(auxTable, tostring(i))
            end
        end
        table.sort(auxTable)
        str = str ..'{'
        local separator = ''
        local entry = ''
        for i, fileName in ipairs(auxTable) do
            if tonumber(fieldName) and tonumber(fieldName) > 0 then
                entry = tostring(value[tonumber(fieldName)])
            else
                entry = fieldName .. '=' .. tostring(value[fieldName])
            end
            str = str .. separator .. entry
            separator = ', '
        end
        str = str .. '}'
    end
    return str
end

function LOG_MSG(self, level, fmt, ...)
    local f_type = type(fmt)
    if f_type == 'string' then
        if select('#', ...) > 0 then
            return self:append(level, format(fmt, ...))
        else
            return self:append(level, fmt)
        end
    elseif f_type == 'function' then
        return self:append(level, fmt(...))
    end
    return self:append(level, tostring(fmt))
end

-- init
for i = 1 ,MAX_LEVELS do
    LEVEL[LEVEL[i]] = i
end

for i = 1, MAX_LEVELS do
    local level = LEVEL[i]
    LEVEL_FUNCS[i] = function(self, ...)
        return LOG_MSG(self, level, ...)
    end
end

-- export
this.DEBUG = DEBUG
this.INFO = INFO
this.WARN = WARN
this.ERROR = ERROR
this.FATAL = FATAL
this.new = new
this.prepareLogMsg = prepareLogMsg
this.tostring = tostring

return this
