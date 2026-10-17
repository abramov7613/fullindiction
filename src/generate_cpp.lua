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

-- NOTE: this file contains the source code in 2 programming languages

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
local h_file   = assert(io.open(arg[1] ,"w"))
local cpp_file = assert(io.open(arg[2] ,"w"))
local DAY_PROPERTIES = {}
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

--##################################################################
--####################  Generate header file  ######################
--##################################################################
do
  h_file:write('/*\n', License, '*/\n')
  local temp_table = {}
  h_file:write([[
#pragma once
#include <utility>
#include <vector>
#include <string>

namespace fullindiction {

constexpr auto INDICTION_LENGTH = 532 ;

using MonthDay = std::pair<int,int> ;

enum class DayProperty {
]])
  for k,v in iterator_by_firstkeys_of_days_table() do
    h_file:write('  ', k, ',///< ', v.desc, '\n')
    temp_table[v.desc] = k
    DAY_PROPERTIES[#DAY_PROPERTIES+1] = k
  end
  h_file:write('  DAY_PROPERTY_SIZE\n};\n')
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
  h_file:write('using enum DayProperty ;\n')
  h_file:write('// таблица псевдонимов\n')
  for k,v in iterator_by_not_firstkeys_of_days_table() do
    h_file:write('constexpr auto ', k, ' = ', temp_table[v.desc], ' ; ///< ', v.desc, '\n')
  end
  h_file:write('\n', [[
// функции
MonthDay easter_date(int year_number_in_fullindiction) ;
MonthDay find_date(int year_number_in_fullindiction, DayProperty property) ;
bool is_date_of(int year_number_in_fullindiction,
                MonthDay date, DayProperty property) ;
std::vector<MonthDay> find_all_dates(int year_number_in_fullindiction,
                                     DayProperty property) ;
std::vector<MonthDay> find_all_dates(int year_number_in_fullindiction,
                                     const std::vector<DayProperty>& properties) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction,
                                         MonthDay date) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction,
                                         int month,
                                         int day) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction,
                                         const std::vector<MonthDay>& dates) ;
int apostol_fast_length(int year_number_in_fullindiction) ;
std::string description(DayProperty) ;                     // in utf8
std::string description(const std::vector<DayProperty>&) ; // in utf8
int to_year_number_in_fullindiction(int year) ;

} // namespace fullindiction
]])
  assert(h_file:close())
end

--##################################################################
--#################   Generate cpp file   ##########################
--##################################################################
do
  cpp_file:write('/*\n', License, '*/\n')
  cpp_file:write('#include "', arg[1], '"\n')
  cpp_file:write([[
#include <array>
#include <stdexcept>
#include <cstdint>
#include <string>
#include <algorithm>
#include <iterator>
#include <unordered_map>

namespace {

using namespace fullindiction ;

constexpr void check_year_number(const int year_number_in_fullindiction)
{
  if (year_number_in_fullindiction < 1 || year_number_in_fullindiction > INDICTION_LENGTH)
    throw std::runtime_error("fullindiction: value of 'year_number_in_fullindiction' must be in range [1,532]");
}

constexpr void check_property_number(DayProperty p)
{
  auto pnum = static_cast<int>(p);
  auto max = static_cast<int>(DayProperty::DAY_PROPERTY_SIZE) - 1;
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
}
]])
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
  local oct_str = {}
  for p = 1, #DAY_PROPERTIES do -- save all calculations to bytes sequence
    for y = 1, fi.INDICTION_LENGTH do
      oct_str[#oct_str + 1] = '  "'
      oct_str[#oct_str + 1] = to_octets(p-1, 2)       -- 2 bytes for DayProperty value as int
      oct_str[#oct_str + 1] = to_octets(y, 2)         -- 2 bytes for year number in indiction range
      local dates = { fi.days[DAY_PROPERTIES[p]].calc(y) }
      if dates[1]==0 then dates = {} end
      oct_str[#oct_str + 1] = to_octets(#dates//2)    -- 1 byte for count of dates
      for i=1, #dates, 2 do
        oct_str[#oct_str + 1] = to_octets(dates[i])   -- 1 byte for month number of each date
        oct_str[#oct_str + 1] = to_octets(dates[i+1]) -- 1 byte for day number of each date
      end
      oct_str[#oct_str + 1] = '"\n'
    end
  end
  cpp_file:write('\n', [[
class ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR {
  constexpr static auto data_ = std::string_view(
]])
  local buf = table.concat(oct_str)
  cpp_file:write(buf, '  , ', select(2, string.gsub(buf, '\\', '\\')), ');\n')
  cpp_file:write('  constexpr static auto P_COUNT = ', #DAY_PROPERTIES, ' ;\n')
  cpp_file:write([[
  std::array< std::array< std::vector<uint8_t>, INDICTION_LENGTH >, P_COUNT > arr_ ;
public:
  ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR()
  {
    auto ptr = reinterpret_cast<const uint8_t*>(data_.data()) ;
    auto pend = ptr + data_.size() ;
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
}; // class ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR
]])
  local ymd_table = {}
  for y = 1, fi.INDICTION_LENGTH do -- save all calculations to ymd_table
    for p = 1, #DAY_PROPERTIES do
      local dates = { fi.days[DAY_PROPERTIES[p]].calc(y) }
      if dates[1]==0 then goto continue end
      for i=1, #dates, 2 do
        local m = dates[i]
        local d = dates[i+1]
        local key = string.format("%.3d%.2d%.2d", y, m, d)
        if ymd_table[key] == nil then ymd_table[key] = {} end
        ymd_table[key][#ymd_table[key] + 1] = p
      end
      ::continue::
    end
  end
  oct_str = {}
  for key,val in pairs(ymd_table) do -- convert ymd_table to bytes sequence
    if #val > 0 then
      local year = tonumber(key:sub(1,3))
      local month = tonumber(key:sub(4,5))
      local day = tonumber(key:sub(6,7))
      oct_str[#oct_str + 1] = '  "'
      oct_str[#oct_str + 1] = to_octets(year, 2)  -- 2 bytes for year
      oct_str[#oct_str + 1] = to_octets(month)    -- 1 byte for month
      oct_str[#oct_str + 1] = to_octets(day)      -- 1 byte for day
      oct_str[#oct_str + 1] = to_octets(#val)     -- 1 byte for properties count
      for i,v in ipairs(val) do
        oct_str[#oct_str + 1] = to_octets(v-1, 2) -- 2 bytes for property as integer
      end
      oct_str[#oct_str + 1] = '"\n'
    end
  end
  cpp_file:write('\n', [[
class ARRAY_OF_PROPERTIES_BY_YMD {
  constexpr static auto data_ = std::string_view(
]])
  buf = table.concat(oct_str)
  cpp_file:write(buf, '  , ', select(2, string.gsub(buf, '\\', '\\')), ');\n')
  cpp_file:write([[
  std::vector<uint16_t> arr_ [532][12][31];
public:
  ARRAY_OF_PROPERTIES_BY_YMD()
  {
    auto ptr = reinterpret_cast<const uint8_t*>(data_.data()) ;
    auto pend = ptr + data_.size() ;
    while (ptr < pend) {
      uint8_t x = *ptr++;
      uint16_t year = x;
      year <<= 8 ;
      x = *ptr++;
      year |= x;
      uint8_t month = *ptr++;
      uint8_t day = *ptr++;
      uint8_t count = *ptr++;
      auto& vec = arr_[year-1][month-1][day-1] ;
      vec.reserve(count);
      while (count>0) {
        x = *ptr++;
        uint16_t val = x;
        val <<= 8 ;
        x = *ptr++;
        val |= x;
        vec.push_back(val);
        count--;
      }
    }
  }
  std::vector<DayProperty> get(int y, int m, int d) const
  {
    const auto& a = arr_[y-1][m-1][d-1];
    std::vector<DayProperty> result;
    if (a.size() > 0) {
      result.resize(a.size(), DAY_PROPERTY_SIZE);
      std::transform(a.cbegin(), a.cend(), result.begin(), [](auto x){
        return static_cast<DayProperty>(x);
      });
    }
    return result;
  }
}; // class ARRAY_OF_PROPERTIES_BY_YMD

} // namespace

namespace fullindiction {

std::vector<MonthDay> find_all_dates(int y, DayProperty p)
{
  static const ARRAY_OF_DATES_BY_PROPERTY_AND_YEAR array_of_dates_by_property_and_year {};
  check_year_number(y) ;
  check_property_number(p) ;
  return array_of_dates_by_property_and_year.get(y, p);
}

MonthDay find_date(int y, DayProperty p)
{
  auto v = find_all_dates(y, p);
  return v.empty() ? MonthDay{} : v.front() ;
}

std::vector<MonthDay> find_all_dates(int y, const std::vector<DayProperty>& vp)
{
  std::vector<MonthDay> result;
  for (auto p: vp) {
    auto v = find_all_dates(y,p);
    std::move(v.begin(), v.end(), std::back_inserter(result));
  }
  return result;
}

MonthDay easter_date(int y)
{
  return find_date(y, PASHA);
}

bool is_date_of(int y, MonthDay d, DayProperty p)
{
  check_date(y, d);
  auto v = find_all_dates(y, p);
  return v.end() != std::find(v.begin(), v.end(), d);
}

int apostol_fast_length(int y)
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

std::vector<DayProperty> find_properties(int y, MonthDay md)
{
  static const ARRAY_OF_PROPERTIES_BY_YMD array_of_properties_by_ymd {};
  check_date(y, md);
  return array_of_properties_by_ymd.get(y, md.first, md.second);
}

std::vector<DayProperty> find_properties(int y, int m, int d)
{
  return find_properties(y, {m, d});
}

std::vector<DayProperty> find_properties(int y, const std::vector<MonthDay>& dates)
{
  std::vector<DayProperty> result;
  for (auto md: dates) {
    auto v = find_properties(y, md);
    std::move(v.begin(), v.end(), std::back_inserter(result));
  }
  return result;
}

int to_year_number_in_fullindiction(int year)
{
  return ((year - 1941) % 532 + 532) % 532 + 1;
}

std::string description(DayProperty p)
{
  check_property_number(p) ;
  using namespace std::literals;
  static const std::unordered_map<DayProperty, std::string_view> data = {
]])
  for k,v in iterator_by_firstkeys_of_days_table() do
    cpp_file:write('    { ', k, ', "', v.desc, '"sv },\n')
  end
  cpp_file:write([[
  };
  if (auto x = data.find(p); x != data.end()) return std::string(x->second) ;
  return {};
}

std::string description(const std::vector<DayProperty>& p)
{
  std::string result;
  for (auto x: p) { result += description(x) + ". "; }
  return result;
}

} // namespace fullindiction

]])
  assert(cpp_file:close())
  buf = nil
  oct_str = nil
end
