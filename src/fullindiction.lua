--[[
      MIT License
      Copyright (c) 2026 Vladimir Abramov <abramov7613@yandex.ru>

      Permission is hereby granted, free of charge, to any person
      obtaining a copy of this software and associated documentation
      files (the "Software"), to deal in the Software without
      restriction, including without limitation the rights to use,
      copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the
      Software is furnished to do so, subject to the following
      conditions:

      The above copyright notice and this permission notice shall be
      included in all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
      OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
      HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
      WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
      FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
      OTHER DEALINGS IN THE SOFTWARE.
]]

local INDICTION_LENGTH = 532
local INDICTION_OFFSET = 1940

--#######################################################################--
--##################         FUNCTIONS        ###########################--
--#######################################################################--

local function check_y(y)
  if type(y)~='number' or (y<1 or y>INDICTION_LENGTH) then return false end
  return true
end

local function check_m(m)
  if type(m)~='number' or (m<1 or m>12) then return false end
  return true
end

local function leap(y)
  if not check_y(y) then error"leap error" end
  return (y+INDICTION_OFFSET)%4 == 0
end

local function m_size(m, leap)
  if not check_m(m) or type(leap)~='boolean' then
    error"m_size error"
  end
  if m==2 then
    if leap then return 29 end
    return 28
  end
  if m==1 or m==3 or m==5 or m==7 or m==8 or m==10 or m==12 then
    return 31
  end
  return 30
end

local function check_ymd(y,m,d)
  if not check_y(y) or not check_m(m) then return false end
  if type(d)~='number' or d<1 or d>m_size(m, leap(y)) then return false end
  return true
end

local function easter(year)
  if not check_y(year) then error"easter function error" end
  year = year + INDICTION_OFFSET
  local  m = 3
  local  a = year % 19
  local  b = year % 4
  local  c = year % 7
  local  d = (19*a+15) % 30
  local  e = (2*b+4*c+6*d+6) % 7
  local  p = 22 + d + e
  if p>31 then
    p = d + e - 9;
    m  = 4;
  end
  return m, p
end

--#######################################################################--
--##################        Date Class        ###########################--
--#######################################################################--

local Date = {}

function Date:new(Y, M, D) -- constructor (year, month, day)
  if not check_ymd(Y,M,D) then error"Date:new error" end
  local t = { year=Y, month=M, day=D }
  setmetatable(t, self)
  self.__index = self
  return t
end

function Date:assign(t) -- assign operation where 't' is table as { [y,] m, d }
  if type(t)~='table' then error"Date:assign error" end
  if #t==2 then
    self.month = t[1]
    self.day = t[2]
  elseif #t==3 then
    self.year = t[1]
    self.month = t[2]
    self.day = t[3]
  else
    error"Date:assign error - invalid size of t"
  end
  if not check_ymd(self.year, self.month, self.day) then error"Date:assign error" end
  return self
end

function Date:__call(y,m,d)
  return self:assign({y,m,d})
end

function Date:__tostring()
  return self.year .. '.' .. self.month .. '.' .. self.day
end

function Date:__eq(rhs)
  return self.year==rhs.year and self.month==rhs.month and self.day==rhs.day
end

function Date:__lt(rhs)
  if self.year < rhs.year then return true end
  if self.year > rhs.year then return false end
  if self.month < rhs.month then return true end
  if self.month > rhs.month then return false end
  return self.day < rhs.day
end

function Date:__le(rhs)
  return self == rhs or self < rhs
end

function Date:ymd() -- return year, month, day
  return self.year, self.month, self.day
end

function Date:md() -- return month, day
  return self.month, self.day
end

function Date:l() -- return true if current year is leap
  return leap(self.year)
end

function Date:ml() -- return current month length
  return m_size(self.month, self:l())
end

function Date:wd() -- return current weekday as 0=sun, 1=mon ...
  local fdiv = function(a,b)
    local x = 0
    if a<0 then x = b-1 end
    local r = math.modf((a - x) / b)
    return r
  end
  local Y = self.year + INDICTION_OFFSET
  local c0 = fdiv((self.month - 3) , 12)
  local j1 = fdiv(1461 * (Y + c0), 4)
  local j2 = fdiv(153 * self.month - 1836 * c0 - 457, 5)
  local cjdn = j1 + j2 + self.day + 1721117
  local result = (cjdn+1) % 7
  return result
end

function Date:i(c) -- increment self
  c = c or 1
  if c<1 then error"Date:i error" end
  local U = self:ml()
  self.day = self.day + c
  while self.day>U do
    self.day = self.day - U
    self.month = self.month + 1
    if self.month>12 then
      self.month = 1
      self.year = self.year + 1
      if self.year>INDICTION_LENGTH then self.year = 1 end
    end
    U = self:ml()
  end
  return self
end

function Date:d(c) -- decrement self
  c = c or 1
  if c<1 then error"Date:d error" end
  local U = self:ml()
  self.day = self.day - c
  while self.day<1 do
    self.month = self.month - 1
    if self.month<1 then
      self.month = 12
      self.year = self.year - 1
      if self.year<1 then self.year = INDICTION_LENGTH end
    end
    U = self:ml()
    self.day = self.day + U
  end
  return self
end

function Date:itowd(weekday) -- change date to first weekday after current
  repeat
    if(weekday == self:wd()) then break; end
    self:i()
  until false
  return self
end

function Date:dtowd(weekday) -- change date to first weekday before current
  repeat
    if(weekday == self:wd()) then break; end
    self:d()
  until false
  return self
end

--#######################################################################--
--#########################   days table    #############################--
--#######################################################################--

local days = {}

local add_idx = 1

local function CREATE_DAYS_ENTRY (t)
  if type(t)~='table' or
     t.keys==nil or
     t.desc==nil or
     t.calc==nil or
     type(t.calc)~='function' or
     type(t.keys)~='table'
  then error"CREATE_DAYS_ENTRY function error" end
  for i,v in ipairs(t.keys) do
   local q = {}
   q.desc = t.desc
   q.calc = t.calc
   q.index = add_idx
   add_idx = add_idx + 1
   days[v] = q
  end
end

local function GET_DATEOBJ(year, key)
  if type(key)~='string' or days[key]==nil then error"GET_DATEOBJ function error" end
  return Date:new(year, days[key]["calc"](year))
end

CREATE_DAYS_ENTRY {
  desc = "Светлое Христово Воскресение. ПАСХА",
  keys = { 'EASTER', "PASHA", "PASCHA", "RESURRECTION" },
  calc = function(year) return easter(year) end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник Светлой седмицы",
  keys = { 'BRIGHT_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник Светлой седмицы",
  keys = { 'BRIGHT_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда Светлой седмицы",
  keys = { 'BRIGHT_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг Светлой седмицы",
  keys = { 'BRIGHT_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница Светлой седмицы",
  keys = { 'BRIGHT_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота Светлой седмицы",
  keys = { 'BRIGHT_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 2-я по Пасхе, апостола Фомы́. Антипасха",
  keys = { 'SUN2_AFTER_EASTER', 'ANTIPASHA', 'FOMA_SUN', 'ANTIPASCHA' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 2-й седмицы по Пасхе",
  keys = { 'WEEK2_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 2-й седмицы по Пасхе. Ра́доница. Поминовение усопших",
  keys = { 'WEEK2_AFTER_EASTER_TUE', 'RADONICA' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 2-й седмицы по Пасхе",
  keys = { 'WEEK2_AFTER_EASTER_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 2-й седмицы по Пасхе",
  keys = { 'WEEK2_AFTER_EASTER_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 2-й седмицы по Пасхе",
  keys = { 'WEEK2_AFTER_EASTER_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 2-й седмицы по Пасхе",
  keys = { 'WEEK2_AFTER_EASTER_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 3-я по Пасхе, святых жен-мироносиц",
  keys = { 'SUN3_AFTER_EASTER' },
  calc = function(year) return GET_DATEOBJ(year, 'ANTIPASHA'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 3-й седмицы по Пасхе",
  keys = { 'WEEK3_AFTER_EASTER_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 4-я по Пасхе, о расслабленном",
  keys = { 'SUN4_AFTER_EASTER' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_EASTER'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 4-й седмицы по Пасхе",
  keys = { 'WEEK4_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 4-й седмицы по Пасхе",
  keys = { 'WEEK4_AFTER_EASTER_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 4-й седмицы по Пасхе. Преполове́ние Пятидесятницы",
  keys = { 'WEEK4_AFTER_EASTER_WED', 'MID_PENTECOST' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 4-й седмицы по Пасхе",
  keys = { 'WEEK4_AFTER_EASTER_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 4-й седмицы по Пасхе",
  keys = { 'WEEK4_AFTER_EASTER_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 4-й седмицы по Пасхе",
  keys = { 'WEEK4_AFTER_EASTER_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 5-я по Пасхе, о самаряны́не",
  keys = { 'SUN5_AFTER_EASTER' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN4_AFTER_EASTER'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 5-й седмицы по Пасхе",
  keys = { 'WEEK5_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 5-й седмицы по Пасхе",
  keys = { 'WEEK5_AFTER_EASTER_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 5-й седмицы по Пасхе. Отдание праздника Преполовения Пятидесятницы",
  keys = { 'WEEK5_AFTER_EASTER_WED', 'ENDOF_MID_PENTECOST' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 5-й седмицы по Пасхе",
  keys = { 'WEEK5_AFTER_EASTER_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 5-й седмицы по Пасхе",
  keys = { 'WEEK5_AFTER_EASTER_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 5-й седмицы по Пасхе",
  keys = { 'WEEK5_AFTER_EASTER_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 6-я по Пасхе, о слепом",
  keys = { 'SUN6_AFTER_EASTER' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN5_AFTER_EASTER'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 6-й седмицы по Пасхе",
  keys = { 'WEEK6_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 6-й седмицы по Пасхе",
  keys = { 'WEEK6_AFTER_EASTER_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 6-й седмицы по Пасхе. Отдание праздника Пасхи",
  keys = { 'WEEK6_AFTER_EASTER_WED', 'ENDOF_PASHA', 'ENDOF_PASCHA', 'ENDOF_EASTER' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 6-й седмицы по Пасхе. Вознесе́ние Госпо́дне",
  keys = { 'WEEK6_AFTER_EASTER_THU', 'ASCENSION' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 6-й седмицы по Пасхе",
  keys = { 'WEEK6_AFTER_EASTER_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 6-й седмицы по Пасхе",
  keys = { 'WEEK6_AFTER_EASTER_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 7-я по Пасхе. Святых отцов Первого Вселенского Собора",
  keys = { 'SUN7_AFTER_EASTER' , 'FATHERS_ECU_COUNCIL_1', 'COUNCIL_1' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN6_AFTER_EASTER'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 7-й седмицы по Пасхе",
  keys = { 'WEEK7_AFTER_EASTER_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 7-й седмицы по Пасхе",
  keys = { 'WEEK7_AFTER_EASTER_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 7-й седмицы по Пасхе",
  keys = { 'WEEK7_AFTER_EASTER_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 7-й седмицы по Пасхе",
  keys = { 'WEEK7_AFTER_EASTER_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 7-й седмицы по Пасхе. Отдание праздника Вознесения Господня",
  keys = { 'WEEK7_AFTER_EASTER_FRI', 'ENDOF_ASCENSION' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Попразднство Вознесения Господня",
  keys = { 'AFTERFEAST_ASCENSION' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local d = GET_DATEOBJ(year, 'ASCENSION'):i(1)
    local endof_ascension = GET_DATEOBJ(year, 'ENDOF_ASCENSION')
    while d < endof_ascension do
      add(d:md())
      d:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 7-й седмицы по Пасхе. Троицкая родительская суббота",
  keys = { 'WEEK7_AFTER_EASTER_SAT', 'TRINITY_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 8-я по Пасхе. День Святой Тро́ицы. Пятидеся́тница",
  keys = { 'PENTECOST_SUN', 'PENTECOST', 'TRINITY_SUN' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN7_AFTER_EASTER'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник Пятидесятницы. День Святаго Духа",
  keys = { 'PENTECOST_MON', 'HOLY_SPIRIT_DAY' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник Пятидесятницы",
  keys = { 'PENTECOST_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда Пятидесятницы",
  keys = { 'PENTECOST_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг Пятидесятницы",
  keys = { 'PENTECOST_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница Пятидесятницы",
  keys = { 'PENTECOST_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота Пятидесятницы. Отдание праздника Пятидесятницы",
  keys = { 'PENTECOST_SAT', 'ENDOF_PENTECOST' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Попразднство Пятидесятницы",
  keys = { 'AFTERFEAST_PENTECOST' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local d = GET_DATEOBJ(year, 'PENTECOST'):i(1)
    local endof_pentecost = GET_DATEOBJ(year, 'ENDOF_PENTECOST')
    while d < endof_pentecost do
      add(d:md())
      d:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 1-я по Пятидесятнице, Всех святых",
  keys = { 'SUN1_AFTER_PENTECOST', 'ALL_SAINTS' },
  calc = function(year) return GET_DATEOBJ(year, 'PENTECOST_SUN'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 2-я по Пятидесятнице. Всех святых, в земле Русской просиявших",
  keys = { 'SUN2_AFTER_PENTECOST', 'ALL_RUS_SAINTS' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN1_AFTER_PENTECOST'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 3-я по Пятидесятнице",
  keys = { 'SUN3_AFTER_PENTECOST' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN2_AFTER_PENTECOST'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 4-я по Пятидесятнице",
  keys = { 'SUN4_AFTER_PENTECOST' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN3_AFTER_PENTECOST'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя о мытаре́ и фарисе́е",
  keys = { 'PUBLICAN_PHARISEE_SUN' },
  calc = function(year) return GET_DATEOBJ(year, 'PASHA'):d(70):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя о блудном сыне",
  keys = { 'PRODIGAL_SON_SUN' },
  calc = function(year) return GET_DATEOBJ(year, 'PUBLICAN_PHARISEE_SUN'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя мясопу́стная, о Страшном Суде",
  keys = { 'DREAD_JUDGEMENT_SUN', 'JUDG_SUN' },
  calc = function(year) return GET_DATEOBJ(year, 'PRODIGAL_SON_SUN'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник сырный",
  keys = { 'CHEESE_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник сырный",
  keys = { 'CHEESE_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда сырная",
  keys = { 'CHEESE_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг сырный",
  keys = { 'CHEESE_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница сырная",
  keys = { 'CHEESE_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота сырная",
  keys = { 'CHEESE_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя сыропустная. Воспоминание Адамова изгнания. Прощеное воскресенье",
  keys = { 'CHEESE_SUN', 'FORGIVENESS_SUN', 'FORGIVENESS' },
  calc = function(year) return GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 1-й седмицы. Начало Великого поста",
  keys = { 'LENT_WEEK1_MON', 'LENT_BEGIN', 'LENT_MON1' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Сре́тение Господа Бога и Спаса нашего Иисуса Христа",
  keys = { 'GOD_MEETING' },
  calc = function(year)
    local result = Date:new(year,2,2)
    local lent_begin = GET_DATEOBJ(year, 'LENT_WEEK1_MON')
    while result >= lent_begin do result:d() end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота мясопу́стная. Вселенская родительская суббота",
  keys = { 'MEMORIAL_SAT' },
  calc = function(year)
    local result = GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN'):d()
    local god_meeting = GET_DATEOBJ(year, 'GOD_MEETING')
    if result == god_meeting then result:d(7) end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 1-й седмицы великого поста",
  keys = { 'LENT_WEEK1_TUE', 'LENT_TUE1' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 1-й седмицы великого поста",
  keys = { 'LENT_WEEK1_WED', 'LENT_WED1' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 1-й седмицы великого поста",
  keys = { 'LENT_WEEK1_THU', 'LENT_THU1' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 1-й седмицы великого поста",
  keys = { 'LENT_WEEK1_FRI', 'LENT_FRI1' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 1-й седмицы великого поста",
  keys = { 'LENT_WEEK1_SAT', 'LENT_SAT1', 'THEODOR_SAT', 'FEODOR_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 1-я Великого поста. Торжество Православия",
  keys = { 'LENT_SUN1', 'ORTHODOXY_TRIUMPH' },
  calc = function(year) return GET_DATEOBJ(year, 'CHEESE_SUN'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 2-й седмицы великого поста",
  keys = { 'LENT_WEEK2_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 2-я Великого поста",
  keys = { 'LENT_SUN2', 'GREGORY_PALAMA' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN1'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 3-й седмицы великого поста",
  keys = { 'LENT_WEEK3_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 3-я Великого поста, Крестопоклонная",
  keys = { 'LENT_SUN3', 'CROSS_WORSHIP' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN2'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 4-й седмицы вел. поста, Крестопоклонной",
  keys = { 'LENT_WEEK4_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 4-я Великого поста. Прп. Иоанна Лествичника",
  keys = { 'LENT_SUN4', 'IOAN_LADDER', 'IOANN_LADDER' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN3'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 5-й седмицы великого поста",
  keys = { 'LENT_WEEK5_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 5-й седмицы великого поста",
  keys = { 'LENT_WEEK5_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 5-й седмицы великого поста",
  keys = { 'LENT_WEEK5_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 5-й седмицы великого поста",
  keys = { 'LENT_WEEK5_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Великий канон, Стояние Марии Египетской",
  keys = { 'GREAT_CANON' },
  calc = function(year)
    local result = GET_DATEOBJ(year, 'LENT_WEEK5_THU')
    if result.month==3 and (result.day==25 or result.day==26) then result:d(2) end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 5-й седмицы великого поста",
  keys = { 'LENT_WEEK5_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 5-й седмицы великого поста. Суббота Ака́фиста. Похвала́ Пресвятой Богородицы",
  keys = { 'LENT_WEEK5_SAT', 'AKAFIST_SAT', 'AKATHIST_SAT', 'THEOTOKOS_LAUDATION' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя 5-я Великого поста. Прп. Марии Египетской",
  keys = { 'LENT_SUN5', 'MARY_OF_EGYPT' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN4'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Понедельник 6-й седмицы великого поста, ва́ий",
  keys = { 'LENT_WEEK6_MON', 'PALM_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Вторник 6-й седмицы великого поста, ва́ий",
  keys = { 'LENT_WEEK6_TUE', 'PALM_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Среда 6-й седмицы великого поста, ва́ий",
  keys = { 'LENT_WEEK6_WED', 'PALM_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Четверг 6-й седмицы великого поста, ва́ий",
  keys = { 'LENT_WEEK6_THU', 'PALM_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Пятница 6-й седмицы великого поста, ва́ий",
  keys = { 'LENT_WEEK6_FRI', 'PALM_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота 6-й седмицы великого поста, ва́ий. Лазарева суббота",
  keys = { 'LENT_WEEK6_SAT', 'LAZAR_SAT', 'LAZARUS_SAT', 'PALM_SAT' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя ва́ий (цветоно́сная, Вербное воскресенье). Вход Господень в Иерусалим",
  keys = { 'LENT_SUN6', 'PALM_SUN', 'JERUSALEM_ENTRANCE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN5'):i(7):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великий Понедельник",
  keys = { 'LENT_WEEK7_MON', 'GREAT_MON' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(1):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великий Вторник",
  keys = { 'LENT_WEEK7_TUE', 'GREAT_TUE' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(2):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великая Среда",
  keys = { 'LENT_WEEK7_WED', 'GREAT_WED' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(3):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великий Четверг. Воспоминание Тайной Ве́чери",
  keys = { 'LENT_WEEK7_THU', 'GREAT_THU' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(4):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великая Пятница",
  keys = { 'LENT_WEEK7_FRI', 'GREAT_FRI' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(5):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Страстна́я седмица. Великая Суббота",
  keys = { 'LENT_WEEK7_SAT', 'GREAT_SAT', 'LENT_END' },
  calc = function(year) return GET_DATEOBJ(year, 'LENT_SUN6'):i(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота пред Воздвижением",
  keys = { 'SAT_BEFORE_EXALTATION' },
  calc = function(year) return Date:new(year,9,13):dtowd(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя пред Воздвижением",
  keys = { 'SUN_BEFORE_EXALTATION' },
  calc = function(year) return Date:new(year,9,13):dtowd(0):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота по Воздвижении",
  keys = { 'SAT_AFTER_EXALTATION' },
  calc = function(year) return Date:new(year,9,15):itowd(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя по Воздвижении",
  keys = { 'SUN_AFTER_EXALTATION' },
  calc = function(year) return Date:new(year,9,15):itowd(0):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Память святых отцов VII Вселенского Собора",
  keys = { 'FATHERS_ECU_COUNCIL_7', 'COUNCIL_7' },
  calc = function(year)
    local result = Date:new(year,10,11)
    local i = result:wd()
    if i==1 or i==2 or i==3 then result:d(i)
    elseif i==4 or i==5 or i==6 then result:i(7-i) end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Димитриевская родительская суббота",
  keys = { 'DIMITRI_SAT' },
  calc = function(year)
    local result = Date:new(year,10,25)
    repeat
      if(result:wd() == 6 and result.day ~= 22) then break; end
      result:d()
    until false
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота пред Рождеством Христовым",
  keys = { 'SAT_BEFORE_CHRISTMAS' },
  calc = function(year) return Date:new(year,12,24):dtowd(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя пред Рождеством Христовым, святых отец",
  keys = { 'SUN_BEFORE_CHRISTMAS' },
  calc = function(year) return Date:new(year,12,24):dtowd(0):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя святых пра́отец",
  keys = { 'HOLY_FOREFATHERS_SUN' },
  calc = function(year) return GET_DATEOBJ(year, 'SUN_BEFORE_CHRISTMAS'):d(1):dtowd(0):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота по Рождестве Христовом",
  keys = { 'SAT_AFTER_CHRISTMAS' },
  calc = function(year)
    local result = Date:new(year,12,25)
    local i = result:wd()
    if i==1 then result:assign{12,30}     -- типикон стр.380
    elseif i==2 then result:assign{12,29}
    elseif i==3 then result:assign{12,28}
    elseif i==4 then result:assign{12,27}
    elseif i==5 then result:assign{12,26}
    else result:assign{12,31} end
    if ( result:wd() == 6 ) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Чтения субботы по Рождестве Христовом",
  keys = { 'SAT_AFTER_CHRISTMAS_READINGS' },
  calc = function(year)
    local result = Date:new(year,12,25)
    local i = result:wd()
    if i==1 then result:assign{12,30}
    elseif i==2 then result:assign{12,29}
    elseif i==3 then result:assign{12,28}
    elseif i==4 then result:assign{12,27}
    elseif i==5 then result:assign{12,26}
    else result:assign{12,31} end
    if ( result:wd() ~= 6 ) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя по Рождестве Христовом",
  keys = { 'SUN_AFTER_CHRISTMAS' },
  calc = function(year)
    local result = Date:new(year,12,25)
    local i = result:wd()
    if i==1 then result:assign{12,31}      -- типикон стр.380
    elseif i==2 then result:assign{12,30}
    elseif i==3 then result:assign{12,29}
    elseif i==4 then result:assign{12,28}
    elseif i==5 then result:assign{12,27}
    else result:assign{12,26} end
    if ( result:wd() == 0 ) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Чтения недели по Рождестве Христовом",
  keys = { 'SUN_AFTER_CHRISTMAS_READINGS' },
  calc = function(year)
    local result = Date:new(year,12,25)
    local i = result:wd()
    if i==1 then result:assign{12,31}
    elseif i==2 then result:assign{12,30}
    elseif i==3 then result:assign{12,29}
    elseif i==4 then result:assign{12,28}
    elseif i==5 then result:assign{12,27}
    else result:assign{12,26} end
    if ( result:wd() ~= 0 ) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Правв. Иосифа Обручника, Давида царя и Иакова, брата Господня",
  keys = { 'SAINTS_JOSEPH_DAVID_JAMES' },
  calc = function(year)
    local m, d = days.SUN_AFTER_CHRISTMAS.calc(year)
    if m==0 then m, d = days.SUN_AFTER_CHRISTMAS_READINGS.calc(year) end
    return m, d
  end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота перед Богоявлением",
  keys = { 'SAT_BEFORE_BAPTISM', 'SAT_BEFORE_THEOPHANY' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local i = Date:new(year,12,25):wd() -- типикон стр.380
    if i > -1 and i < 2 then add(12, 31-i) end
    i = year-1
    if i==0 then i = INDICTION_LENGTH end
    i = Date:new(i,12,25):wd()
    if i>1 and i<7 then add(1, 7-i) end
    if #result == 0 then add(0, 0) end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя перед Богоявлением",
  keys = { 'SUN_BEFORE_BAPTISM', 'SUN_BEFORE_THEOPHANY' },
  calc = function(year)
    local result = Date:new(year, 1, 1)
    local i = year-1
    if i==0 then i = INDICTION_LENGTH end
    i = Date:new(i,12,25):wd()
    if i==3 then result:assign{1,5}
    elseif i==4 then result:assign{1,4}
    elseif i==5 then result:assign{1,3}
    elseif i==6 then result:assign{1,2} end
    if (result:wd() == 0) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Чтения недели пред Богоявлением",
  keys = { 'SUN_BEFORE_BAPTISM_READINGS', 'SUN_BEFORE_THEOPHANY_READINGS' },
  calc = function(year)
    local result = Date:new(year, 1, 1)
    local i = year-1
    if i==0 then i = INDICTION_LENGTH end
    i = Date:new(i,12,25):wd()
    if i==3 then result:assign{1,5}
    elseif i==4 then result:assign{1,4}
    elseif i==5 then result:assign{1,3}
    elseif i==6 then result:assign{1,2} end
    if (result:wd() ~= 0) then return result:md() end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Суббота по Богоявлении",
  keys = { 'SAT_AFTER_BAPTISM', 'SAT_AFTER_THEOPHANY' },
  calc = function(year) return Date:new(year,1,7):itowd(6):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Неделя по Богоявлении",
  keys = { 'SUN_AFTER_BAPTISM', 'SUN_AFTER_THEOPHANY' },
  calc = function(year) return Date:new(year,1,7):itowd(0):md() end
}

CREATE_DAYS_ENTRY {
  desc = "Собор новомучеников и исповедников Церкви Русской",
  keys = { 'NEW_MARTYRS_OF_RUSSIA', 'RUS_MARTYRS' },
  calc = function(year)
    local result = Date:new(year,1,25)
    local i = result:wd()
    if i==1 or i==2 or i==3 then result:d(i)
    elseif i==4 or i==5 or i==6 then result:i(7-i) end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Собор 3-x свят. Василия Великого, Григория Богослова и Иоанна Златоустого",
  keys = { 'CONVENTION_OF_3_HIERARCHS', 'HIERARCHS_3' },
  calc = function(year)
    local result = Date:new(year,1,30)
    local d1 = GET_DATEOBJ(year, 'CHEESE_WED')
    local d2 = GET_DATEOBJ(year, 'CHEESE_FRI')
    local d3 = GET_DATEOBJ(year, 'MEMORIAL_SAT')
    if result==d1 or result==d2 or result==d3 then result:d() end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Предпразднство Сре́тения Господня",
  keys = { 'FOREFEAST_GOD_MEETING' },
  calc = function(year)
    local result = Date:new(year, 2, 1)
    if result == GET_DATEOBJ(year, 'GOD_MEETING') then return 0,0 end
    if result == GET_DATEOBJ(year, 'MEMORIAL_SAT') then result:d() end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Отдание праздника Сретения Господня",
  keys = { 'ENDOF_GOD_MEETING' },
  calc = function(year)
    local dd = GET_DATEOBJ(year, 'GOD_MEETING')
    local forgiveness = GET_DATEOBJ(year, 'CHEESE_SUN')
    if dd == forgiveness  then return 0,0 end
    local result = Date:new(year, 2, 9)
    local t1 = GET_DATEOBJ(year, 'PRODIGAL_SON_SUN')
    local t2 = GET_DATEOBJ(year, 'PRODIGAL_SON_SUN'):i(2)
    if(dd>=t1 and dd<=t2) then result = GET_DATEOBJ(year, 'PRODIGAL_SON_SUN'):i(5); end
    t1:i(3)
    t2 = Date:new(t1:ymd()):i(3)
    if(dd>=t1 and dd<=t2) then result = GET_DATEOBJ(year, 'CHEESE_TUE') end
    t1 = GET_DATEOBJ(year, 'DREAD_JUDGEMENT_SUN')
    t2 = GET_DATEOBJ(year, 'CHEESE_MON')
    if(dd>=t1 and dd<=t2) then result = GET_DATEOBJ(year, 'CHEESE_THU') end
    t1 = GET_DATEOBJ(year, 'CHEESE_TUE')
    t2 = GET_DATEOBJ(year, 'CHEESE_WED')
    if(dd>=t1 and dd<=t2) then result = GET_DATEOBJ(year, 'CHEESE_SAT') end
    t1 = GET_DATEOBJ(year, 'CHEESE_THU')
    t2 = GET_DATEOBJ(year, 'CHEESE_SAT')
    if(dd>=t1 and dd<=t2) then result = forgiveness end
    if(result == GET_DATEOBJ(year, 'MEMORIAL_SAT')) then result:d() end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Попразднство Сретения Господня",
  keys = { 'AFTERFEAST_GOD_MEETING' },
  calc = function(year)
    local end_m, end_d = days.ENDOF_GOD_MEETING.calc(year)
    if end_m==0 then return 0,0 end
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local d = GET_DATEOBJ(year, 'GOD_MEETING'):i(1)
    local endof_god_meeting = Date:new(year, end_m, end_d)
    while d < endof_god_meeting do
      add(d:md())
      d:i()
    end
    if #result==0 then add(0,0) end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Первое и второе Обре́тение главы Иоанна Предтечи",
  keys = { 'JOHN_BAPTIST_HEAD_DISCOVERY_1_2', 'IOAN_HEAD_FINDING_12', 'IOANN_HEAD_FINDING_12' },
  calc = function(year)
    local result = Date:new(year,2,24)
    local d1 = GET_DATEOBJ(year, 'CHEESE_WED')
    local d2 = GET_DATEOBJ(year, 'CHEESE_FRI')
    local d3 = GET_DATEOBJ(year, 'MEMORIAL_SAT')
    local d4 = GET_DATEOBJ(year, 'LENT_BEGIN')
    local d5 = GET_DATEOBJ(year, 'LENT_SAT1')
    if result==d1 or result==d2 or result==d3 or result==d4 then result:d() end
    if result>d4 and result<d5 then result = d5 end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Третье обре́тение главы Предтечи и Крестителя Господня Иоанна",
  keys = { 'JOHN_BAPTIST_HEAD_DISCOVERY_3', 'IOAN_HEAD_FINDING_3', 'IOANN_HEAD_FINDING_3' },
  calc = function(year)
    local result = Date:new(year,5,25)
    local trinity_sat = GET_DATEOBJ(year, 'TRINITY_SAT')
    local holy_spirit_day = GET_DATEOBJ(year, 'HOLY_SPIRIT_DAY')
    local all_saints = GET_DATEOBJ(year, 'ALL_SAINTS')
    local pentecost = GET_DATEOBJ(year, 'PENTECOST')
    if( result==all_saints or result==trinity_sat ) then result.day = 23
    elseif( result==holy_spirit_day ) then result.day = 26
    elseif( result==pentecost ) then result.day = 22 end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Святых сорока́ мучеников, в Севастийском е́зере мучившихся",
  keys = { 'HOLY_FORTY_MARTYRS_OF_SEBASTE', 'MARTYRS_40_SEBASTE', 'MARTYRS_40' },
  calc = function(year)
    local result = Date:new(year,3,9)
    local akafist_sat = GET_DATEOBJ(year, 'AKAFIST_SAT')
    local lent_week4_wed = GET_DATEOBJ(year, 'LENT_WEEK4_WED')
    local lent_week5_thu = GET_DATEOBJ(year, 'LENT_WEEK5_THU')
    local forgiveness = GET_DATEOBJ(year, 'FORGIVENESS')
    local lent_sat1 = GET_DATEOBJ(year, 'LENT_SAT1')
    if result == lent_week4_wed then result:d()
    elseif result == lent_week5_thu then result:d(2)
    elseif result == akafist_sat then result:i()
    elseif result > forgiveness and result < lent_sat1 then result = lent_sat1 end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Предпразднство Благовещения Пресвятой Богородицы",
  keys = { 'FOREFEAST_GOD_MOTHER_ANNUNCIATION', 'FOREFEAST_ANNUNCIATION' },
  calc = function(year)
    local result = Date:new(year,3,25)
    if result < GET_DATEOBJ(year, 'GREAT_MON') then
      result.day = 24
      if result == GET_DATEOBJ(year, 'LAZAR_SAT') then result.day = 22
      elseif result == GET_DATEOBJ(year, 'LENT_WEEK5_THU') or
             result == GET_DATEOBJ(year, 'LENT_WEEK5_TUE') then result.day = 23 end
      return result:md()
    end
    return 0,0
  end
}

CREATE_DAYS_ENTRY {
  desc = "Отдание праздника Благовещения Пресвятой Богородицы",
  keys = { 'ENDOF_GOD_MOTHER_ANNUNCIATION', 'ENDOF_ANNUNCIATION' },
  calc = function(year)
    local result = Date:new(year,3,26)
    if result < GET_DATEOBJ(year, 'LAZAR_SAT') then return result:md()
    else return 0,0 end
  end
}

CREATE_DAYS_ENTRY {
  desc = "Вмч. Гео́ргия Победоно́сца",
  keys = { 'HOLY_GREAT_MARTYR_GEORGE', 'MARTYR_GEORG' },
  calc = function(year)
    local result = Date:new(year,4,23)
    local great_thu = GET_DATEOBJ(year, 'GREAT_THU')
    local bright_mon = GET_DATEOBJ(year, 'BRIGHT_MON')
    if result > great_thu and result < bright_mon then result = bright_mon end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Память святых отцов шести Вселенских Соборов",
  keys = { 'FATHERS_ECU_COUNCIL_1_6', 'COUNCIL_1_6' },
  calc = function(year)
    local result = Date:new(year,7,16)
    local i = result:wd()
    if i==1 or i==2 or i==3 then result:dtowd(0)
    elseif i==4 or i==5 or i==6 then result:itowd(0) end
    return result:md()
  end
}

CREATE_DAYS_ENTRY {
  desc = "Двунадесятые переходящие праздники",
  keys = { 'MOVEABLE_FEAST', 'MOVE_FEAST' },
  calc = function(year)
    local palm_sun = GET_DATEOBJ(year, 'PALM_SUN')
    local ascension = GET_DATEOBJ(year, 'ASCENSION')
    local pentecost = GET_DATEOBJ(year, 'PENTECOST')
    local result =
    {
      palm_sun.month, palm_sun.day,
      ascension.month, ascension.day,
      pentecost.month, pentecost.day
    }
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Двунадесятые непереходящие праздники",
  keys = { 'IMMOVEABLE_FEAST', 'IMMOVE_FEAST' },
  calc = function(year)
    local god_meeting = GET_DATEOBJ(year, 'GOD_MEETING')
    local result =
    {
      1, 6,
      god_meeting.month, god_meeting.day,
      3, 25,
      8, 6,
      8, 15,
      9, 8,
      9, 14,
      11, 21,
      12,25
    }
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "Великие праздники",
  keys = { 'GREAT_FEAST' },
  calc = function(year)
    local result =
    {
      1, 1,
      6, 24,
      6, 29,
      8, 29,
      10, 1
    }
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней великого поста",
  keys = { 'GREAT_LENT' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'LENT_BEGIN')
    local pasha = GET_DATEOBJ(year, 'PASHA')
    while date < pasha do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней Петрова поста",
  keys = { 'APOSTOL_LENT' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'ALL_SAINTS'):i()
    local sentinel = Date:new(year,6,29)
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней Рождественского поста",
  keys = { 'CHRISTMAS_LENT' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = Date:new(year,11,15)
    local sentinel = Date:new(year,12,25)
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней Успенского поста",
  keys = { 'ASSUMPTION_LENT' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = Date:new(year,8,1)
    local sentinel = Date:new(year,8,15)
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней сплошной седмицы. Светлая",
  keys = { 'SOLID_WEEK_BRIGHT' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'PASHA')
    local sentinel = GET_DATEOBJ(year, 'ANTIPASHA')
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней сплошной седмицы. Рождественская",
  keys = { 'SOLID_WEEK_CHRISTMAS' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    add(1,1)
    add(1,2)
    add(1,3)
    add(1,4)
    add(12,25)
    add(12,26)
    add(12,27)
    add(12,28)
    add(12,29)
    add(12,30)
    add(12,31)
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней сплошной седмицы. Троицкая",
  keys = { 'SOLID_WEEK_PENTECOST' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'PENTECOST')
    local sentinel = GET_DATEOBJ(year, 'ALL_SAINTS')
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней сплошной седмицы. Сырная (Масленица)",
  keys = { 'SOLID_WEEK_CHEESE' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'CHEESE_MON')
    local sentinel = GET_DATEOBJ(year, 'LENT_BEGIN')
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

CREATE_DAYS_ENTRY {
  desc = "один из дней сплошной седмицы. Мытаря и фарисея",
  keys = { 'SOLID_WEEK_PUBLICAN_PHARISEE' },
  calc = function(year)
    local result = {}
    local add = function(...)
      for i, v in ipairs{...} do
        result[#result+1] = v
      end
    end
    local date = GET_DATEOBJ(year, 'PUBLICAN_PHARISEE_SUN')
    local sentinel = GET_DATEOBJ(year, 'PUBLICAN_PHARISEE_SUN'):i(7)
    while date < sentinel do
      add(date:md())
      date:i()
    end
    return table.unpack(result)
  end
}

--#######################################################################--
--#################   RETURN MODULE TABLE    ############################--
--#######################################################################--

return {
  INDICTION_LENGTH = INDICTION_LENGTH,
  days             = days,
}
