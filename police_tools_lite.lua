--[[
  Доброго времени суток, это сообщение от разработчика Police Tools Lite!
  Уведомляю вас о том, что данный код находится под лицензией GPL v.3
  Это обозначает, что любой продукт, который будет в итоге произведен из
  оригинального кода должен распространяться под той же лицензий, а
  соответственно исходный код вашего продукта всегда должен быть доступен.

  Я ВКонтакте: https://vk.com/pavel.akulichev
  Я в Telegram: https://t.me/pakulichev
  Я на BlastHack: https://blast.hk/members/159390/
  Поддержать меня: https://qiwi.com/n/PAKULICHEV

  Изменение и повторная публикация данного скрипта разрешена с указанием
  изначального авторства, а также ссылки на первоначальную публикацию.
]]

--[[
  Police Tools Lite
  Copyright (C) 2020 Pavel Akulichev

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see https://www.gnu.org/licenses/.
]]

script_name("Police Tools Lite")
script_author("Pavel Garson")
script_properties("work-in-pause")

local ffi = require("ffi")
local encoding = require("encoding")
local imgui = require("mimgui")
local xconf = require("xconf")

encoding.default = "CP1251"
local u8 = encoding.UTF8

local ImVec2, ImVec4, ToU32, ToVec4 = imgui.ImVec2, imgui.ImVec4,
imgui.ColorConvertFloat4ToU32, imgui.ColorConvertU32ToFloat4

local is_window_open = false
local imgui_fonts = {}
local sx, sy = getScreenResolution()

local buf_name = imgui.new.char[61]()
local buf_command = imgui.new.char[61]()
local buf_buffer = imgui.new.char[5000]()
local buf_phone = imgui.new.char[10]()
local buf_work = imgui.new.char[129]()
local buf_rang = imgui.new.char[129]()

local binds_list = {}
local current_bind = 0
local focus_field = false
local settings_list = false
local settings_col = 0

local sett_template = {
  phone = "nil",
  work = "nil",
  rang = "nil"
}
local settings = {}
local vars = {
  ["ID"] = function()
    return tostring(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
  end,
  ["NAME"] = function()
    local name = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    local name, surname = name:match("^(%S+)_(%S+)$")
    name, surname = tostring(name), tostring(surname)
    return name
  end,
  ["SURNAME"] = function()
    local name = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    local name, surname = name:match("^(%S+)_(%S+)$")
    name, surname = tostring(name), tostring(surname)
    return surname
  end,
  ["PHONE"] = function()
    return tostring(settings.phone)
  end,
  ["WORK"] = function()
    return tostring(settings.work)
  end,
  ["RANG"] = function()
    return tostring(settings.rang)
  end
}

local function set_vars(str)
  for k, v in pairs(vars) do
    str = str:gsub("%$"..k.."%$", v)
  end; return str
end

local function bind_starter(bind, args)
  args = u8(args)
  local text = set_vars(bind.buffer)
  lua_thread.create(function()
    for line in text:gmatch("[^\r\n]+") do
      local sleep = tonumber(line:match("%$SLEEP:(%d-)%$") or 1000)
      local no_send = line:match("%$NOSEND%$")
      line = line:gsub("%$ARGS%$", args)
      line = line:gsub("%$NOSEND%$", args)
      line = line:gsub("%$SLEEP:%d-%$", "")
      if no_send then sampAddChatMessage(u8:decode(line), -1)
      else sampSendChat(u8:decode(line)) end
      wait(sleep)
    end
  end)
end

local function hook_bind(command, args)
  for i, v in ipairs(binds_list) do
    if v.command == command then
      bind_starter(v, args)
    end
  end
end

function imgui.FromRGB(r, g, b, a)
  return ImVec4(r / 255, g / 255, b / 255, a / 255)
end

createDirectory(getWorkingDirectory().."\\config")

local conf = xconf.new(getWorkingDirectory().."\\config\\PToolsLite.cfg")
conf:set_template(sett_template); settings = conf:get()

local binds = xconf.new(getWorkingDirectory().."\\config\\PToolsLite.list")
binds_list = binds:get()

ffi.copy(buf_phone, tostring(settings.phone))
ffi.copy(buf_work, tostring(settings.work))
ffi.copy(buf_rang, tostring(settings.rang))

function main()
  repeat wait(0) until isSampAvailable()
  sampRegisterChatCommand("plite", function()
    is_window_open = not is_window_open
  end)
  for i, v in ipairs(binds_list) do
    if #v.command > 0 and v.command ~= 'plite' then
      sampUnregisterChatCommand(v.command)
      sampRegisterChatCommand(v.command, function(args)
        hook_bind(v.command, args)
      end)
      print("Command "..v.command.." was registered!")
    end
  end
  wait(-1)
end

imgui.OnInitialize(function()
  local ImIO = imgui.GetIO()
  ImIO.IniFilename = nil
  local ImGR = ImIO.Fonts:GetGlyphRangesCyrillic()
  ImIO.Fonts:Clear()
  ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 10, nil, ImGR)
  imgui_fonts[1] = ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 16, nil, ImGR)
  imgui_fonts[2] = ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 9, nil, ImGR)
  imgui_fonts[3] = ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 12, nil, ImGR)
  imgui_fonts[4] = ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 14, nil, ImGR)
  imgui_fonts[5] = ImIO.Fonts:AddFontFromFileTTF(getWorkingDirectory().."\\resource\\Police Tools Lite\\font.ttf", 8, nil, ImGR)
  imgui.InvalidateFontsTexture()
  local ImST = imgui.GetStyle()
  ImST.WindowPadding = ImVec2(0, 0)
  ImST.WindowBorderSize = 0.00
  ImST.WindowRounding = 0.00
  ImST.FrameRounding = 10.00
  ImST.ScrollbarSize = 1
  ImST.Colors[imgui.Col.WindowBg] = imgui.FromRGB(60, 60, 60, 255)
  ImST.Colors[imgui.Col.FrameBg] = imgui.FromRGB(100, 100, 100, 255)
  ImST.Colors[imgui.Col.FrameBgActive] = imgui.FromRGB(100, 100, 100, 255)
  ImST.Colors[imgui.Col.FrameBgHovered] = imgui.FromRGB(100, 100, 100, 255)
end)

imgui.OnFrame(function() return not isGamePaused() and is_window_open end,
function(self)
  imgui.SetNextWindowPos(ImVec2(sx / 2, sy / 2), imgui.Cond.FirstUseEver, ImVec2(0.5, 0.5))
  imgui.SetNextWindowSize(ImVec2(800, 500), imgui.Cond.FirstUseEver)
  imgui.Begin("Police Tools Lite", nil, imgui.WindowFlags.NoDecoration)
  local DL = imgui.GetWindowDrawList()
  local PS = imgui.GetCursorScreenPos()
  DL:AddRectFilled(ImVec2(PS.x, PS.y), ImVec2(PS.x + 800, PS.y + 45), ToU32(imgui.FromRGB(105, 140, 200, 255)))
  imgui.SetCursorPos(ImVec2(10, 10))
  imgui.PushFont(imgui_fonts[1])
  imgui.Text("POLICE TOOLS")
  imgui.PopFont()
  imgui.SetCursorPos(ImVec2(10, 25))
  imgui.PushFont(imgui_fonts[2])
  imgui.Text("KITTENDEV PRODUCTION")
  imgui.PopFont()
  imgui.SetCursorPos(ImVec2(710, 17))
  imgui.PushFont(imgui_fonts[3])
  imgui.Text("НАСТРОЙКИ")
  imgui.PopFont()
  if imgui.IsItemHovered() and imgui.IsItemClicked(0) then
    settings_list = not settings_list
  end
  imgui.SetCursorPos(ImVec2(10, 53))
  imgui.PushFont(imgui_fonts[4])
  imgui.Text("СОЗДАТЬ НОВЫЙ БИНД")
  imgui.PopFont()
  if imgui.IsItemHovered() and imgui.IsItemClicked(0) then
    table.insert(binds_list, {
      name = "НОВЫЙ БИНД #" .. #binds_list + 1,
      command = "", buffer = ""
    })
    current_bind = #binds_list
    ffi.copy(buf_name, binds_list[#binds_list].name)
    ffi.copy(buf_command, binds_list[#binds_list].command)
    ffi.copy(buf_buffer, binds_list[#binds_list].buffer)
  end
  imgui.SetCursorPos(ImVec2(355, 53))
  imgui.PushFont(imgui_fonts[4])
  imgui.Text("LITE VERSION")
  imgui.PopFont()
  imgui.SetCursorPos(ImVec2(650, 53))
  imgui.PushFont(imgui_fonts[4])
  imgui.Text("УДАЛИТЬ ВСЕ БИНДЫ")
  imgui.PopFont()
  if imgui.IsItemHovered() and imgui.IsItemClicked(0) and not settings_list then
    for i, v in ipairs(binds_list) do
      if sampIsChatCommandDefined(v.command) then
        sampUnregisterChatCommand(v.command)
      end
    end
    binds_list = {}
    current_bind = 0
    ffi.copy(buf_name, "")
    ffi.copy(buf_command, "")
    ffi.copy(buf_buffer, "")
  end
  DL:AddLine(ImVec2(PS.x, PS.y + 75), ImVec2(PS.x + 800, PS.y + 75), ToU32(imgui.FromRGB(200, 200, 200, 255)))
  imgui.SetCursorPos(ImVec2(315, 90))
  imgui.Text("НАЗВАНИЕ")
  imgui.SetCursorPos(ImVec2(370, 87))
  imgui.PushItemWidth(420.0)
  imgui.InputTextWithHint("##name", "Введите название бинда...", buf_name, ffi.sizeof(buf_name))
  imgui.PopItemWidth()
  imgui.SetCursorPos(ImVec2(315, 115))
  imgui.Text("КОМАНДА")
  imgui.SetCursorPos(ImVec2(370, 112))
  imgui.PushItemWidth(420.0)
  imgui.InputTextWithHint("##command", "Введите команду для бинда...", buf_command, ffi.sizeof(buf_command))
  imgui.PopItemWidth()
  imgui.SetCursorPos(ImVec2(315, 140))
  imgui.Text("ТЕКСТ НАСТОЯЩЕГО БИНДА (ДОСТУПНЫ ПЕРЕМЕННЫЕ)")
  imgui.SetCursorPos(ImVec2(315, 160))
  imgui.InputTextMultiline("##buffer", buf_buffer, ffi.sizeof(buf_buffer), ImVec2(475, 225))
  if focus_field then
    imgui.SetKeyboardFocusHere(2)
    focus_field = false
  end
  imgui.SetCursorPos(ImVec2(315, 400))
  imgui.Text("ВСТАВИТЬ ПЕРЕМЕННЫЕ")
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.00)
  imgui.SetCursorPos(ImVec2(440, 395))
  if imgui.Button("МОЙ ID", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$ID$")
    focus_field = true
  end
  imgui.SameLine(0, 20)
  if imgui.Button("ИМЯ", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$NAME$")
    focus_field = true
  end
  imgui.SameLine(0, 20)
  if imgui.Button("ФАМИЛИЯ", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$SURNAME$")
    focus_field = true
  end
  imgui.SetCursorPos(ImVec2(440, 425))
  if imgui.Button("ТЕЛЕФОН", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$PHONE$")
    focus_field = true
  end
  imgui.SameLine(0, 20)
  if imgui.Button("РАБОТА", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$WORK$")
    focus_field = true
  end
  imgui.SameLine(0, 20)
  if imgui.Button("ЗВАНИЕ", ImVec2(100, 20)) then
    ffi.copy(buf_buffer, ffi.string(buf_buffer) .. "$RANG$")
    focus_field = true
  end
  imgui.SetCursorPos(ImVec2(315, 460))
  if current_bind ~= 0 and binds_list[current_bind] then
    imgui.Text("ДЕЙСТВИЯ С БИНДОМ")
    imgui.SetCursorPos(ImVec2(440, 455))
    if imgui.Button("СОХРАНИТЬ", ImVec2(100, 20)) then
      sampUnregisterChatCommand(binds_list[current_bind].command)
      binds_list[current_bind] = {
        name = ffi.string(buf_name),
        command = ffi.string(buf_command),
        buffer = ffi.string(buf_buffer)
      }
      local v = binds_list[current_bind]
      if #v.command > 0 and v.command ~= 'plite' then
        sampUnregisterChatCommand(v.command)
        sampRegisterChatCommand(v.command, function(args)
          hook_bind(v.command, args)
        end)
      end
      current_bind = 0
      ffi.copy(buf_name, "")
      ffi.copy(buf_command, "")
      ffi.copy(buf_buffer, "")
    end
    imgui.SameLine(0, 20)
    if imgui.Button("УДАЛИТЬ", ImVec2(100, 20)) then
      table.remove(binds_list, current_bind)
      current_bind = 0
      ffi.copy(buf_name, "")
      ffi.copy(buf_command, "")
      ffi.copy(buf_buffer, "")
    end
    imgui.SameLine(0, 20)
    if imgui.Button("КОПИЯ", ImVec2(100, 20)) then
      table.insert(binds_list, {
        name = binds_list[current_bind].name,
        command = binds_list[current_bind].command,
        buffer = binds_list[current_bind].buffer
      })
      current_bind = #binds_list
      ffi.copy(buf_name, binds_list[#binds_list].name)
      ffi.copy(buf_command, binds_list[#binds_list].command)
      ffi.copy(buf_buffer, binds_list[#binds_list].buffer)
    end
  end
  imgui.PopStyleVar()
  imgui.SetCursorPos(ImVec2(10, 90))
  imgui.BeginChild("binds", ImVec2(290, 400))
  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.FromRGB(100, 100, 100, 255))
  imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 10.00)
  local clipper = imgui.ImGuiListClipper(#binds_list)
  while clipper:Step() do
    for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
      local v = binds_list[i]
      imgui.BeginChild("bind"..i, ImVec2(280, 30))
      local bind_name = v.name
      imgui.SetCursorPos(ImVec2(280 / 2 - imgui.CalcTextSize(bind_name).x / 2, 10))
      imgui.Text(bind_name)
      if imgui.IsItemHovered() and imgui.IsItemClicked(0) then
        if current_bind ~= i then
          current_bind = i
          ffi.copy(buf_name, v.name)
          ffi.copy(buf_command, v.command)
          ffi.copy(buf_buffer, v.buffer)
        end
      end
      imgui.EndChild()
    end
  end
  imgui.PopStyleVar()
  imgui.PopStyleColor()
  imgui.EndChild()
  if settings_col > 0 then
    DL:AddRectFilled(ImVec2(PS.x + 600, PS.y + 45), ImVec2(PS.x + 800, PS.y + 180), ToU32(imgui.FromRGB(105, 140, 200, settings_col)), 15.0, imgui.DrawCornerFlags.Bot)
    imgui.SetCursorPos(ImVec2(600, 45))
    imgui.PushStyleColor(imgui.Col.ChildBg, ImVec4(0, 0, 0, 0))
    imgui.BeginChild("protector", ImVec2(200, 135))

    imgui.PushStyleColor(imgui.Col.Text, imgui.FromRGB(255, 255, 255, settings_col))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.FromRGB(60, 60, 60, settings_col))
    imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.FromRGB(60, 60, 60, settings_col))
    imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.FromRGB(60, 60, 60, settings_col))
    imgui.PushStyleColor(imgui.Col.Button, imgui.FromRGB(60, 110, 60, settings_col))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.FromRGB(60, 110, 60, settings_col))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.FromRGB(60, 160, 60, settings_col))
    imgui.SetCursorPos(ImVec2(10, 5))
    imgui.BeginGroup()
    imgui.Text("Ваш номер телефона:")
    imgui.PushItemWidth(180.00)
    imgui.InputText("##phone", buf_phone, ffi.sizeof(buf_phone))
    imgui.PopItemWidth()
    imgui.Text("Название вашей работы:")
    imgui.PushItemWidth(180.00)
    imgui.InputText("##work", buf_work, ffi.sizeof(buf_work))
    imgui.PopItemWidth()
    imgui.Text("Название вашей должности:")
    imgui.PushItemWidth(180.00)
    imgui.InputText("##rang", buf_rang, ffi.sizeof(buf_rang))
    imgui.PopItemWidth()
    imgui.Spacing()
    if imgui.Button("Сохранить настройки", ImVec2(180, 0)) then
      settings.phone = ffi.string(buf_phone)
      settings.work = ffi.string(buf_work)
      settings.rang = ffi.string(buf_rang)
    end
    imgui.EndGroup()
    imgui.PopStyleColor(7)

    imgui.EndChild()
    imgui.PopStyleColor()
  end
  if settings_list and settings_col < 255 then settings_col = settings_col + 1
  elseif not settings_list and settings_col > 0 then settings_col = settings_col - 1 end
  imgui.End()
end)

function onScriptTerminate(script)
  if thisScript() == script then
    conf:set(settings); conf:close()
    binds:set(binds_list); binds:close()
    for i, v in ipairs(binds_list) do
      sampUnregisterChatCommand(v.command)
      print("Command "..v.command.." was unregistered!")
    end
  end
end