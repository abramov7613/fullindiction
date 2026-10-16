## fullindiction - это

Библиотека которая реализует календарные вычисления для православной христианской церкви на языке Lua 5.4 и предоставляет интерфейс для использования из приложений C++20. Вообще изначально проект задумывался как чистый C++ в режиме compile-time, но тесты показали что современные компиляторы пока что сильно ограничены при выполнении объемных вычислений на этапе компиляции, поэтому было решено перейти на Lua с последующим экспортом. Lua выбрана еще по причине что семантика таблиц в языке в сочетании с замыканиями позволяет более удобно описывать логику декларативным способом.

### Теория

**Великий индиктион** (на Руси иногда встречается название - великий миротворный круг) - Это период времени в 532 года в юлианском календаре, который содержит полный пасхальный цикл. Юлианский календарь был создан александрийским астрономом Созигеном в 46 году до Р.Х. для римского императора Юлия Цезаря, от имени которого и получил своё название. А пасхальный цикл был рассчитан в Константинополе в IV веке. Цифра 532 получается в результате умножения 28 (солнечный цикл) на 19 (лунный цикл). Ознакомиться с теоретическими основами можно [здесь](https://azbyka.ru/otechnik/Pravoslavnoe_Bogosluzhenie/pjatiperstnaja-pashalija-i-kalendar/2_2 ).
На григорианский календарь и западную пасхалию Великий индиктион не распространяется. Индиктионы было принято отсчитывать от начала византийской эры. Например:

- 12-й великий индиктион начался в 345 году;
- 13-й — в 877 году;
- 14-й — в 1409 году;
- 15-й великий индиктион начался в 1941 году и завершится в 2473 году.

По истечении Великого индиктиона даты христианской Пасхи, вычисленные по юлианскому календарю и православной пасхалии, повторяются в том же порядке. Это связано с тем, что через каждые 532 года расчётные фазы Луны и дни недели приходятся на те же числа месяца.

Итак, для расчетов мы имеем два числовых ряда: один - циклический, второй - стремится к бесконечности. Первый выражает порядковый номер года внутри своего великого индиктиона, второй выражает фактический год для любой даты:
```
первый ряд: 1, 2, ..., 532, 1, 2, 3, ...
второй ряд: 1941, 1942, 1943, 1944,  ...
```
Тогда, чтобы найти порядковый номер года для любой даты нужно: (при условии что для 1941 значение из второго ряда всегда равно 1) определить, насколько оно удалено от 1941 `n = YEAR − 1941`. И взять остаток по модулю 532 `N = (n mod 532) + 1`. Итого: `N = ((YEAR − 1941) mod 532) + 1`.

В Lua 5.4 оператор `%` работает с отрицательными числами так, как нужно для циклического индекса, поэтому формула корректна и ниже 1941 :
```lua
function to_year_number_in_fullindiction(year)
  return (year - 1941) % 532 + 1
end
```
В C++ для отрицательных чисел оператор `%` имеет другое поведение и если нужно учитывать значения меньше 1941, то придется делать нормализацию остатка:
```c++
int to_year_number_in_fullindiction(int year)
{
  return ((year - 1941) % 532 + 532) % 532 + 1;
}
```

### Как устроен проект

```
├── CMakeLists.txt
├── LICENSE
├── README.md
├── src
│   ├── fullindiction.lua
│   └── generate_cpp.lua
└── tests
    ├── catch_amalgamated.cpp
    ├── catch_amalgamated.hpp
    ├── CMakeLists.txt
    ├── easter_date_test.cpp
    ├── easter_date_test.txt
    ├── find_date_test.cpp
    ├── find_date_test.txt
    ├── find_properties_test.cpp
    ├── find_properties_test.txt
    └── my_test_framework.hpp

```
Все календарные вычисления вынесены в `fullindiction.lua` и ограничены круговым циклом в 532 года, поэтому одним из входных значений для API является не число года конкретной даты, а порядковый номер года в пределах своего великого индиктиона. Далее файл `generate_cpp.lua` импортирует все алгоритмы из `fullindiction.lua` и производит вычисления для всех возможных комбинаций, то есть для каждого дня/месяца/года в пределах 532-х летнего цикла, и сохраняет результат в `cpp` файл, предоставляя и `header` файл как интерфейс для доступа из C++ приложения. Все эти действия автоматизированы скриптами CMake, так что для интеграции в проект можно пользоваться такими стандартными методами как `add_subdirectory` или `FetchContent`. Если интерпретатор Lua не установлен в системе то при сборке проекта нужен доступ в интернет, так как CMake будет пытаться скачать исходники чтобы собрать свой интерпретатор.

### Как использовать

#### из Lua

```
...
```

#### из C++

 - Установить компилятор совместимый со стандартом C++20 (GCC 10+, Clang 12+, MSVC 2019 16.11+)
 - Установить CMake версии от 3.31 или выше
 - Установить интерпретатор Lua 5.4 или выше (не обязательно)

```
git clone https://github.com/abramov7613/fullindiction.git
cd fullindiction
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DFULLINDICTION_OFFLINEBUILD=OFF
cmake --build build
cd build
ctest
```
после этого в каталоге `src` появятся файлы `fullindiction.h` и `fullindiction.cpp`, a в каталоге `build` будет бинарный файл библиотеки готовый для линковки к стороннему приложению, имя файла зависит от платформы.

#### Пример

```c++
#include <iostream>
#include <string>
#include <stdexcept>
#include "fullindiction.h"

namespace fi = fullindiction;

int main(int argc, char** argv)
try
{
  if (argc != 2) {
    std::cout << "Usage: " << argv[0] << " YEAR\n" ;
    return 0;
  }
  std::cout << argv[1] << " год:\n";

  int year = std::stoi(argv[1]);
  int number = fi::to_year_number_in_fullindiction(year);

  auto [easter_month, easter_day] = fi::easter_date(number);
  std::cout << easter_day << '.' << easter_month << '\t'
            << fi::description(fi::PASHA) << '\n';

  auto [rm_month, rm_day] = fi::find_date(number, fi::RUS_MARTYRS);
  std::cout << rm_day << '.' << rm_month << '\t'
            << fi::description(fi::RUS_MARTYRS) << '\n';

  for ( auto m_feasts = fi::find_all_dates(number, fi::MOVE_FEAST);
        auto [month, day]: m_feasts )
  {
    std::cout
      << day << '.' << month << '\t'
      << fi::description(fi::find_properties(number, month, day))
      << '\n';
  }

  return 0;
}

catch(const std::exception& e)
{
  std::cout << "Exception: " << e.what() << '\n';
  return -1;
}

catch(...)
{
  std::cout << "Unknown Exception\n";
  return -1;
}

```
#### Заголовочный файл fullindiction.h (создается автоматически)

```c++
#pragma once
#include <utility>
#include <initializer_list>
#include <vector>
#include <string>

namespace fullindiction {

constexpr auto INDICTION_LENGTH = 532 ;

using MonthDay = std::pair<int,int> ;

enum class DayProperty {
  EASTER,///< Светлое Христово Воскресение. ПАСХА
  BRIGHT_MON,///< Понедельник Светлой седмицы
  BRIGHT_TUE,///< Вторник Светлой седмицы
  BRIGHT_WED,///< Среда Светлой седмицы
  BRIGHT_THU,///< Четверг Светлой седмицы
  BRIGHT_FRI,///< Пятница Светлой седмицы
  BRIGHT_SAT,///< Суббота Светлой седмицы
  SUN2_AFTER_EASTER,///< Неделя 2-я по Пасхе, апостола Фомы́. Антипасха
  WEEK2_AFTER_EASTER_MON,///< Понедельник 2-й седмицы по Пасхе
  WEEK2_AFTER_EASTER_TUE,///< Вторник 2-й седмицы по Пасхе. Ра́доница. Поминовение усопших
  WEEK2_AFTER_EASTER_WED,///< Среда 2-й седмицы по Пасхе
  WEEK2_AFTER_EASTER_THU,///< Четверг 2-й седмицы по Пасхе
  WEEK2_AFTER_EASTER_FRI,///< Пятница 2-й седмицы по Пасхе
  WEEK2_AFTER_EASTER_SAT,///< Суббота 2-й седмицы по Пасхе
  SUN3_AFTER_EASTER,///< Неделя 3-я по Пасхе, святых жен-мироносиц
  WEEK3_AFTER_EASTER_MON,///< Понедельник 3-й седмицы по Пасхе
  WEEK3_AFTER_EASTER_TUE,///< Вторник 3-й седмицы по Пасхе
  WEEK3_AFTER_EASTER_WED,///< Среда 3-й седмицы по Пасхе
  WEEK3_AFTER_EASTER_THU,///< Четверг 3-й седмицы по Пасхе
  WEEK3_AFTER_EASTER_FRI,///< Пятница 3-й седмицы по Пасхе
  WEEK3_AFTER_EASTER_SAT,///< Суббота 3-й седмицы по Пасхе
  SUN4_AFTER_EASTER,///< Неделя 4-я по Пасхе, о расслабленном
  WEEK4_AFTER_EASTER_MON,///< Понедельник 4-й седмицы по Пасхе
  WEEK4_AFTER_EASTER_TUE,///< Вторник 4-й седмицы по Пасхе
  WEEK4_AFTER_EASTER_WED,///< Среда 4-й седмицы по Пасхе. Преполове́ние Пятидесятницы
  WEEK4_AFTER_EASTER_THU,///< Четверг 4-й седмицы по Пасхе
  WEEK4_AFTER_EASTER_FRI,///< Пятница 4-й седмицы по Пасхе
  WEEK4_AFTER_EASTER_SAT,///< Суббота 4-й седмицы по Пасхе
  SUN5_AFTER_EASTER,///< Неделя 5-я по Пасхе, о самаряны́не
  WEEK5_AFTER_EASTER_MON,///< Понедельник 5-й седмицы по Пасхе
  WEEK5_AFTER_EASTER_TUE,///< Вторник 5-й седмицы по Пасхе
  WEEK5_AFTER_EASTER_WED,///< Среда 5-й седмицы по Пасхе. Отдание праздника Преполовения Пятидесятницы
  WEEK5_AFTER_EASTER_THU,///< Четверг 5-й седмицы по Пасхе
  WEEK5_AFTER_EASTER_FRI,///< Пятница 5-й седмицы по Пасхе
  WEEK5_AFTER_EASTER_SAT,///< Суббота 5-й седмицы по Пасхе
  SUN6_AFTER_EASTER,///< Неделя 6-я по Пасхе, о слепом
  WEEK6_AFTER_EASTER_MON,///< Понедельник 6-й седмицы по Пасхе
  WEEK6_AFTER_EASTER_TUE,///< Вторник 6-й седмицы по Пасхе
  WEEK6_AFTER_EASTER_WED,///< Среда 6-й седмицы по Пасхе. Отдание праздника Пасхи
  WEEK6_AFTER_EASTER_THU,///< Четверг 6-й седмицы по Пасхе. Вознесе́ние Госпо́дне
  WEEK6_AFTER_EASTER_FRI,///< Пятница 6-й седмицы по Пасхе
  WEEK6_AFTER_EASTER_SAT,///< Суббота 6-й седмицы по Пасхе
  SUN7_AFTER_EASTER,///< Неделя 7-я по Пасхе. Святых отцов Первого Вселенского Собора
  WEEK7_AFTER_EASTER_MON,///< Понедельник 7-й седмицы по Пасхе
  WEEK7_AFTER_EASTER_TUE,///< Вторник 7-й седмицы по Пасхе
  WEEK7_AFTER_EASTER_WED,///< Среда 7-й седмицы по Пасхе
  WEEK7_AFTER_EASTER_THU,///< Четверг 7-й седмицы по Пасхе
  WEEK7_AFTER_EASTER_FRI,///< Пятница 7-й седмицы по Пасхе. Отдание праздника Вознесения Господня
  AFTERFEAST_ASCENSION,///< Попразднство Вознесения Господня
  WEEK7_AFTER_EASTER_SAT,///< Суббота 7-й седмицы по Пасхе. Троицкая родительская суббота
  PENTECOST_SUN,///< Неделя 8-я по Пасхе. День Святой Тро́ицы. Пятидеся́тница
  PENTECOST_MON,///< Понедельник Пятидесятницы. День Святаго Духа
  PENTECOST_TUE,///< Вторник Пятидесятницы
  PENTECOST_WED,///< Среда Пятидесятницы
  PENTECOST_THU,///< Четверг Пятидесятницы
  PENTECOST_FRI,///< Пятница Пятидесятницы
  PENTECOST_SAT,///< Суббота Пятидесятницы. Отдание праздника Пятидесятницы
  AFTERFEAST_PENTECOST,///< Попразднство Пятидесятницы
  SUN1_AFTER_PENTECOST,///< Неделя 1-я по Пятидесятнице, Всех святых
  SUN2_AFTER_PENTECOST,///< Неделя 2-я по Пятидесятнице. Всех святых, в земле Русской просиявших
  SUN3_AFTER_PENTECOST,///< Неделя 3-я по Пятидесятнице
  SUN4_AFTER_PENTECOST,///< Неделя 4-я по Пятидесятнице
  PUBLICAN_PHARISEE_SUN,///< Неделя о мытаре́ и фарисе́е
  PRODIGAL_SON_SUN,///< Неделя о блудном сыне
  DREAD_JUDGEMENT_SUN,///< Неделя мясопу́стная, о Страшном Суде
  CHEESE_MON,///< Понедельник сырный
  CHEESE_TUE,///< Вторник сырный
  CHEESE_WED,///< Среда сырная
  CHEESE_THU,///< Четверг сырный
  CHEESE_FRI,///< Пятница сырная
  CHEESE_SAT,///< Суббота сырная
  CHEESE_SUN,///< Неделя сыропустная. Воспоминание Адамова изгнания. Прощеное воскресенье
  LENT_WEEK1_MON,///< Понедельник 1-й седмицы. Начало Великого поста
  GOD_MEETING,///< Сре́тение Господа Бога и Спаса нашего Иисуса Христа
  MEMORIAL_SAT,///< Суббота мясопу́стная. Вселенская родительская суббота
  LENT_WEEK1_TUE,///< Вторник 1-й седмицы великого поста
  LENT_WEEK1_WED,///< Среда 1-й седмицы великого поста
  LENT_WEEK1_THU,///< Четверг 1-й седмицы великого поста
  LENT_WEEK1_FRI,///< Пятница 1-й седмицы великого поста
  LENT_WEEK1_SAT,///< Суббота 1-й седмицы великого поста
  LENT_SUN1,///< Неделя 1-я Великого поста. Торжество Православия
  LENT_WEEK2_MON,///< Понедельник 2-й седмицы великого поста
  LENT_WEEK2_TUE,///< Вторник 2-й седмицы великого поста
  LENT_WEEK2_WED,///< Среда 2-й седмицы великого поста
  LENT_WEEK2_THU,///< Четверг 2-й седмицы великого поста
  LENT_WEEK2_FRI,///< Пятница 2-й седмицы великого поста
  LENT_WEEK2_SAT,///< Суббота 2-й седмицы великого поста
  LENT_SUN2,///< Неделя 2-я Великого поста
  LENT_WEEK3_MON,///< Понедельник 3-й седмицы великого поста
  LENT_WEEK3_TUE,///< Вторник 3-й седмицы великого поста
  LENT_WEEK3_WED,///< Среда 3-й седмицы великого поста
  LENT_WEEK3_THU,///< Четверг 3-й седмицы великого поста
  LENT_WEEK3_FRI,///< Пятница 3-й седмицы великого поста
  LENT_WEEK3_SAT,///< Суббота 3-й седмицы великого поста
  LENT_SUN3,///< Неделя 3-я Великого поста, Крестопоклонная
  LENT_WEEK4_MON,///< Понедельник 4-й седмицы вел. поста, Крестопоклонной
  LENT_WEEK4_TUE,///< Вторник 4-й седмицы вел. поста, Крестопоклонной
  LENT_WEEK4_WED,///< Среда 4-й седмицы вел. поста, Крестопоклонной
  LENT_WEEK4_THU,///< Четверг 4-й седмицы вел. поста, Крестопоклонной
  LENT_WEEK4_FRI,///< Пятница 4-й седмицы вел. поста, Крестопоклонной
  LENT_WEEK4_SAT,///< Суббота 4-й седмицы вел. поста, Крестопоклонной
  LENT_SUN4,///< Неделя 4-я Великого поста. Прп. Иоанна Лествичника
  LENT_WEEK5_MON,///< Понедельник 5-й седмицы великого поста
  LENT_WEEK5_TUE,///< Вторник 5-й седмицы великого поста
  LENT_WEEK5_WED,///< Среда 5-й седмицы великого поста
  LENT_WEEK5_THU,///< Четверг 5-й седмицы великого поста
  GREAT_CANON,///< Великий канон, Стояние Марии Египетской
  LENT_WEEK5_FRI,///< Пятница 5-й седмицы великого поста
  LENT_WEEK5_SAT,///< Суббота 5-й седмицы великого поста. Суббота Ака́фиста. Похвала́ Пресвятой Богородицы
  LENT_SUN5,///< Неделя 5-я Великого поста. Прп. Марии Египетской
  LENT_WEEK6_MON,///< Понедельник 6-й седмицы великого поста, ва́ий
  LENT_WEEK6_TUE,///< Вторник 6-й седмицы великого поста, ва́ий
  LENT_WEEK6_WED,///< Среда 6-й седмицы великого поста, ва́ий
  LENT_WEEK6_THU,///< Четверг 6-й седмицы великого поста, ва́ий
  LENT_WEEK6_FRI,///< Пятница 6-й седмицы великого поста, ва́ий
  LENT_WEEK6_SAT,///< Суббота 6-й седмицы великого поста, ва́ий. Лазарева суббота
  LENT_SUN6,///< Неделя ва́ий (цветоно́сная, Вербное воскресенье). Вход Господень в Иерусалим
  LENT_WEEK7_MON,///< Страстна́я седмица. Великий Понедельник
  LENT_WEEK7_TUE,///< Страстна́я седмица. Великий Вторник
  LENT_WEEK7_WED,///< Страстна́я седмица. Великая Среда
  LENT_WEEK7_THU,///< Страстна́я седмица. Великий Четверг. Воспоминание Тайной Ве́чери
  LENT_WEEK7_FRI,///< Страстна́я седмица. Великая Пятница
  LENT_WEEK7_SAT,///< Страстна́я седмица. Великая Суббота
  SAT_BEFORE_EXALTATION,///< Суббота пред Воздвижением
  SUN_BEFORE_EXALTATION,///< Неделя пред Воздвижением
  SAT_AFTER_EXALTATION,///< Суббота по Воздвижении
  SUN_AFTER_EXALTATION,///< Неделя по Воздвижении
  FATHERS_ECU_COUNCIL_7,///< Память святых отцов VII Вселенского Собора
  DIMITRI_SAT,///< Димитриевская родительская суббота
  SAT_BEFORE_CHRISTMAS,///< Суббота пред Рождеством Христовым
  SUN_BEFORE_CHRISTMAS,///< Неделя пред Рождеством Христовым, святых отец
  HOLY_FOREFATHERS_SUN,///< Неделя святых пра́отец
  SAT_AFTER_CHRISTMAS,///< Суббота по Рождестве Христовом
  SAT_AFTER_CHRISTMAS_READINGS,///< Чтения субботы по Рождестве Христовом
  SUN_AFTER_CHRISTMAS,///< Неделя по Рождестве Христовом
  SUN_AFTER_CHRISTMAS_READINGS,///< Чтения недели по Рождестве Христовом
  SAINTS_JOSEPH_DAVID_JAMES,///< Правв. Иосифа Обручника, Давида царя и Иакова, брата Господня
  SAT_BEFORE_BAPTISM,///< Суббота перед Богоявлением
  SUN_BEFORE_BAPTISM,///< Неделя перед Богоявлением
  SUN_BEFORE_BAPTISM_READINGS,///< Чтения недели пред Богоявлением
  SAT_AFTER_BAPTISM,///< Суббота по Богоявлении
  SUN_AFTER_BAPTISM,///< Неделя по Богоявлении
  NEW_MARTYRS_OF_RUSSIA,///< Собор новомучеников и исповедников Церкви Русской
  CONVENTION_OF_3_HIERARCHS,///< Собор 3-x свят. Василия Великого, Григория Богослова и Иоанна Златоустого
  FOREFEAST_GOD_MEETING,///< Предпразднство Сре́тения Господня
  ENDOF_GOD_MEETING,///< Отдание праздника Сретения Господня
  AFTERFEAST_GOD_MEETING,///< Попразднство Сретения Господня
  JOHN_BAPTIST_HEAD_DISCOVERY_1_2,///< Первое и второе Обре́тение главы Иоанна Предтечи
  JOHN_BAPTIST_HEAD_DISCOVERY_3,///< Третье обре́тение главы Предтечи и Крестителя Господня Иоанна
  HOLY_FORTY_MARTYRS_OF_SEBASTE,///< Святых сорока́ мучеников, в Севастийском е́зере мучившихся
  FOREFEAST_GOD_MOTHER_ANNUNCIATION,///< Предпразднство Благовещения Пресвятой Богородицы
  ENDOF_GOD_MOTHER_ANNUNCIATION,///< Отдание праздника Благовещения Пресвятой Богородицы
  HOLY_GREAT_MARTYR_GEORGE,///< Вмч. Гео́ргия Победоно́сца
  FATHERS_ECU_COUNCIL_1_6,///< Память святых отцов шести Вселенских Соборов
  MOVEABLE_FEAST,///< Двунадесятый переходящий праздник
  IMMOVEABLE_FEAST,///< Двунадесятый непереходящий праздник
  GREAT_FEAST,///< Великий праздник
  GREAT_LENT,///< Великий пост
  APOSTOL_LENT,///< Петров пост
  CHRISTMAS_LENT,///< Рождественский пост
  ASSUMPTION_LENT,///< Успенский пост
  SOLID_WEEK_BRIGHT,///< Сплошная седмица - Светлая
  SOLID_WEEK_CHRISTMAS,///< Сплошная седмица - Святки
  SOLID_WEEK_PENTECOST,///< Сплошная седмица - Троицкая
  SOLID_WEEK_CHEESE,///< Сплошная седмица - Сырная (Масленица)
  SOLID_WEEK_PUBLICAN_PHARISEE,///< Сплошная седмица - Мытаря и фарисея
  DAY_PROPERTY_SIZE
};
using enum DayProperty ;
//...
// функции
MonthDay easter_date(int year_number_in_fullindiction) ;
MonthDay find_date(int year_number_in_fullindiction, DayProperty property) ;
bool is_date_of(int year_number_in_fullindiction, MonthDay date, DayProperty property) ;
std::vector<MonthDay> find_all_dates(int year_number_in_fullindiction, DayProperty property) ;
std::vector<MonthDay> find_all_dates(int year_number_in_fullindiction,
                                     std::initializer_list<DayProperty> properties) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction, MonthDay date) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction, int month, int day) ;
std::vector<DayProperty> find_properties(int year_number_in_fullindiction,
                                         std::vector<MonthDay> dates) ;
int apostol_fast_length(int year_number_in_fullindiction) ;
std::string description(DayProperty) ; // in utf8
std::string description(std::vector<DayProperty>) ; // in utf8
int to_year_number_in_fullindiction(int year) ;

} // namespace fullindiction
```
