License = [[
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

LUA_MINOR_VERSION = string.match(_VERSION, "Lua 5%.(%d)")

if LUA_MINOR_VERSION==nil or tonumber(LUA_MINOR_VERSION)<4 then
  print("Lua 5.4 minimum version required")
  return
end

if arg[1]==nil or arg[2]==nil then
  print("Usage: "..arg[-1]..' '..arg[0]..' <out_cpp_header_file_name> <out_cpp_source_file_name>')
  return
end

local fi = require"fullindiction"
local out1 = assert(io.open(arg[1] ,"w"))
local out2 = assert(io.open(arg[2] ,"w"))
local DAY_PROPERTIES = {}

--##################################################################
--####################  Generate header file  ######################
--##################################################################
do
  local h1 = [[
#pragma once
#include <utility>
#include <initializer_list>
#include <vector>

namespace fullindiction {

constexpr auto INDICTION_LENGTH = 532 ;

using MonthDay = std::pair<int,int> ;

enum class DayProperty {]]
  out1:write('/*\n', License, '*/\n', h1, '\n')
  local iterator_by_firstkeys_of_days_table = function()
    local a = {}
    for n in pairs(fi.days) do a[#a + 1] = n end
    table.sort(a, function(x, y) return fi.days[x].index < fi.days[y].index end)
    local i = 0
    return function()
      i = i + 1
      if i==1 then return a[i], fi.days[a[i]] end
      if not a[i] then return nil,nil end
      while fi.days[a[i]].desc==fi.days[a[i-1]].desc do i = i + 1 end
      return a[i], fi.days[a[i]]
    end
  end
  local temp_table = {}
  for k,v in iterator_by_firstkeys_of_days_table() do
    out1:write('  ', k, ',///< ', v.desc, '\n')
    temp_table[v.desc] = k
    DAY_PROPERTIES[#DAY_PROPERTIES+1] = k
  end
  out1:write('  SIZE_\n};\n')
  local iterator_by_not_firstkeys_of_days_table = function()
    local t = {}
    for n in iterator_by_firstkeys_of_days_table() do t[n] = true end
    local a = {}
    for n in pairs(fi.days) do
      if not t[n] then a[#a + 1] = n end
    end
    table.sort(a, function(x, y) return fi.days[x].index < fi.days[y].index end)
    local i = 0
    return function()
      i = i + 1
      return a[i], fi.days[a[i]]
    end
  end
  out1:write('using enum DayProperty ;\n')
  out1:write('// таблица псевдонимов\n')
  for k,v in iterator_by_not_firstkeys_of_days_table() do
    out1:write('constexpr auto ', k, ' = ', temp_table[v.desc], ' ; ///< ', v.desc, '\n')
  end
  local h2 = [[
MonthDay easter_date(const int year_number_in_fullindiction) ;
MonthDay find_date(const int year_number_in_fullindiction, const DayProperty property) ;
int apostol_fast_length(const int year_number_in_fullindiction) ;
bool is_date_of(const int year_number_in_fullindiction, const MonthDay date, const DayProperty property) ;
std::vector<MonthDay> find_all_dates(const int year_number_in_fullindiction, const DayProperty property) ;
std::vector<MonthDay> find_all_dates(const int year_number_in_fullindiction,
                                     std::initializer_list<DayProperty> properties) ;
//std::vector<DayProperty> get_day_properties(const int year_number_in_fullindiction, const MonthDay date) ;
//int get_n50(const int year_number_in_fullindiction, const MonthDay date) ;

} // namespace fullindiction]]
  out1:write('\n', h2, '\n')
  assert(out1:close())
end

--##################################################################
--#################   Generate cpp file   ##########################
--##################################################################
do
  out2:write('/*\n', License, '*/\n')
  out2:write('#include "', arg[1], '"\n')
  local c1 = [[
#include <array>
#include <stdexcept>
#include <cstdint>
#include <string>
#include <algorithm>
#include <iterator>

namespace {

using namespace fullindiction ;

constexpr void check_year_number(const int year_number_in_fullindiction)
{
  if (year_number_in_fullindiction < 1 || year_number_in_fullindiction > INDICTION_LENGTH)
    throw std::runtime_error("fullindiction: value of 'year_number_in_fullindiction' must be in range [1,533)");
}

constexpr void check_property_number(DayProperty p)
{
  auto pnum = static_cast<int>(p);
  auto max = static_cast<int>(DayProperty::SIZE_) - 1;
  if (pnum < 0 || pnum > max)
    throw std::runtime_error("fullindiction: invalid DayProperty value");
}

constexpr bool is_leap(const int year_number_in_great_indiction)
{
  check_year_number(year_number_in_great_indiction) ;
  const int year = year_number_in_great_indiction + 1940 ;
  return (year%4 == 0) ;
}

constexpr int month_length(const int month, const bool leap)
{
  switch(month) {
    case 1:
    case 3:
    case 5:
    case 7:
    case 8:
    case 10:
    case 12:
        return 31;
        break;
    case 4:
    case 6:
    case 9:
    case 11:
        return 30;
        break;
    case 2:
        return leap ? 29 : 28;
        break;
    default:
        return 0;
  }
}

constexpr void check_date(const int year_number_in_fullindiction, const MonthDay date)
{
  check_year_number(year_number_in_fullindiction);
  if (date.first < 1 || date.first > 12)
    throw std::runtime_error("fullindiction: invalid month number");
  if (date.second < 1 || date.second > month_length(date.first, is_leap(year_number_in_fullindiction)))
    throw std::runtime_error("fullindiction: invalid day number");
}]]
  out2:write(c1, '\n\n')
  local to_octets = function (x, length)
    if math.type(x)~='integer' then error"to_octets function error" end
    length = length or 1
    local result = ""
    if x>=0 and x<256 then
      result = string.format("\\%o", x)
      length = length - 1
    elseif x>255 and x<65536 then
      result = string.format("\\%o\\%o", x>>8, x&255)
      length = length - 2
    else
      error"to_octets function error"
    end
    while length>0 do
      result = '\\0' .. result
      length = length - 1
    end
    return result
  end
  local adpy = {}
  local P_COUNT = #DAY_PROPERTIES
  for p = 1, P_COUNT do -- save all calculations to array of bytes
    for y = 1, fi.INDICTION_LENGTH do
      adpy[#adpy + 1] = '  "'
      adpy[#adpy + 1] = to_octets(p-1, 2)       -- 2 bytes for DayProperty value as int
      adpy[#adpy + 1] = to_octets(y, 2)         -- 2 bytes for year number in indiction range
      local dates = { fi.days[DAY_PROPERTIES[p]].calc(y) }
      if dates[1]==0 then dates = {} end
      adpy[#adpy + 1] = to_octets(#dates//2)    -- 1 byte for count of dates
      for i=1, #dates, 2 do
        adpy[#adpy + 1] = to_octets(dates[i])   -- 1 byte for month number of each date
        adpy[#adpy + 1] = to_octets(dates[i+1]) -- 1 byte for day number of each date
      end
      adpy[#adpy + 1] = '"\n'
    end
  end
  local buf = table.concat(adpy)
  out2:write('constexpr auto adpy = std::string_view(\n')
  out2:write(buf, '  , ', select(2, string.gsub(buf, '\\', '\\')), ');\n')
  buf = nil
  out2:write('constexpr auto P_COUNT = ', P_COUNT, ' ;\n\n')
  local c2 = [[
class ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR {
  std::array< std::array< std::vector<uint8_t>, INDICTION_LENGTH >, P_COUNT > arr_ ;
public:
  ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR()
  {
    auto ptr = reinterpret_cast<const uint8_t*>(adpy.data()) ;
    auto pend = ptr + adpy.size() ;
    while (ptr < pend) {
      uint8_t x = *ptr++;
      uint16_t property = x;
      property <<= 8 ;
      x = *ptr++;
      property |= x;
      x = *ptr++;
      uint16_t year = x;
      year <<= 8 ;
      x = *ptr++;
      year |= x;
      uint8_t count = *ptr++;
      auto& vec = arr_[property][year-1] ;
      vec.reserve(count*2);
      while (count>0) {
        vec.push_back(*ptr++);
        vec.push_back(*ptr++);
        count--;
      }
    }
  }
  std::vector<MonthDay> get(const int y, const DayProperty p) const
  {
    std::vector<MonthDay> result;
    const auto& a = arr_[static_cast<int>(p)][y-1];
    for (auto i=0u; i<a.size(); i+=2) result.emplace_back(a[i], a[i+1]) ;
    return result;
  }
};

} // namespace without name

namespace fullindiction {

std::vector<MonthDay> find_all_dates(const int y, const DayProperty p)
{
  static const ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR array_of_dates_by_property_and_year {};
  check_year_number(y) ;
  check_property_number(p) ;
  return array_of_dates_by_property_and_year.get(y, p);
}

MonthDay find_date(const int y, const DayProperty p)
{
  auto v = find_all_dates(y, p);
  return v.empty() ? MonthDay{} : v.front() ;
}

std::vector<MonthDay> find_all_dates(const int y, std::initializer_list<DayProperty> il)
{
  std::vector<MonthDay> result;
  for (auto p: il) {
    auto v = find_all_dates(y,p);
    std::move(v.begin(), v.end(), std::back_inserter(result));
  }
  return result;
}

MonthDay easter_date(const int y)
{
  return find_date(y, PASHA);
}

bool is_date_of(const int y, const MonthDay d, const DayProperty p)
{
  check_date(y, d);
  auto v = find_all_dates(y, p);
  return v.end() != std::find(v.begin(), v.end(), d);
}

int apostol_fast_length(const int y)
{
  check_year_number(y) ;
  const bool leap = is_leap(y) ;
  int x1 = 0;
  int x2 = leap ? 181 : 180 ;
  auto pasha = easter_date(y);
  for (int i=1; i<pasha.first; ++i) x1 += month_length(i, leap) ;
  x1 += pasha.second ;
  return x2 - x1 - 57 ;
}

} // namespace fullindiction
]]
  out2:write(c2, '\n\n')
  assert(out2:close())
end
