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

### Как устроен проект

Все календарные вычисления вынесены в `fullindiction.lua` и ограничены круговым циклом в 532 года, поэтому одним из входных значений для API является не число года конкретной даты, а порядковый номер года в пределах своего великого индиктиона. Этот номер рассчитывается по формуле: `N = ((YEAR − 1941) mod 532) + 1`. Далее файл `generate_cpp.lua` импортирует все алгоритмы из `fullindiction.lua` в виде таблиц и производит вычисления для всех возможных комбинаций, то есть для каждого дня/месяца/года в пределах 532-х летнего цикла, и сохраняет результат `cpp` файл, предоставляя и `header` файл как интерфейс для доступа из C++ приложения. Все эти действия автоматизированы скриптами CMake, так что пользователю библиотеки понадобиться выполнить только несколько стандартных команд. Вот заголовочный файл (создается автоматически) `fullindiction.h` описывающий C++20 API:

```c++
#pragma once
#include <utility>
#include <initializer_list>
#include <vector>

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
  MOVEABLE_FEAST,///< Двунадесятые переходящие праздники
  IMMOVEABLE_FEAST,///< Двунадесятые непереходящие праздники
  GREAT_FEAST,///< Великие праздники
  GREAT_LENT,///< один из дней великого поста
  APOSTOL_LENT,///< один из дней Петрова поста
  CHRISTMAS_LENT,///< один из дней Рождественского поста
  ASSUMPTION_LENT,///< один из дней Успенского поста
  SOLID_WEEK_BRIGHT,///< один из дней сплошной седмицы. Светлая
  SOLID_WEEK_CHRISTMAS,///< один из дней сплошной седмицы. Рождественская
  SOLID_WEEK_PENTECOST,///< один из дней сплошной седмицы. Троицкая
  SOLID_WEEK_CHEESE,///< один из дней сплошной седмицы. Сырная (Масленица)
  SOLID_WEEK_PUBLICAN_PHARISEE,///< один из дней сплошной седмицы. Мытаря и фарисея
  SIZE_
};
using enum DayProperty ;
// таблица псевдонимов
constexpr auto PASHA = EASTER ; ///< Светлое Христово Воскресение. ПАСХА
constexpr auto PASCHA = EASTER ; ///< Светлое Христово Воскресение. ПАСХА
constexpr auto RESURRECTION = EASTER ; ///< Светлое Христово Воскресение. ПАСХА
constexpr auto ANTIPASHA = SUN2_AFTER_EASTER ; ///< Неделя 2-я по Пасхе, апостола Фомы́. Антипасха
constexpr auto FOMA_SUN = SUN2_AFTER_EASTER ; ///< Неделя 2-я по Пасхе, апостола Фомы́. Антипасха
constexpr auto ANTIPASCHA = SUN2_AFTER_EASTER ; ///< Неделя 2-я по Пасхе, апостола Фомы́. Антипасха
constexpr auto RADONICA = WEEK2_AFTER_EASTER_TUE ; ///< Вторник 2-й седмицы по Пасхе. Ра́доница. Поминовение усопших
constexpr auto MID_PENTECOST = WEEK4_AFTER_EASTER_WED ; ///< Среда 4-й седмицы по Пасхе. Преполове́ние Пятидесятницы
constexpr auto ENDOF_MID_PENTECOST = WEEK5_AFTER_EASTER_WED ; ///< Среда 5-й седмицы по Пасхе. Отдание праздника Преполовения Пятидесятницы
constexpr auto ENDOF_PASHA = WEEK6_AFTER_EASTER_WED ; ///< Среда 6-й седмицы по Пасхе. Отдание праздника Пасхи
constexpr auto ENDOF_PASCHA = WEEK6_AFTER_EASTER_WED ; ///< Среда 6-й седмицы по Пасхе. Отдание праздника Пасхи
constexpr auto ENDOF_EASTER = WEEK6_AFTER_EASTER_WED ; ///< Среда 6-й седмицы по Пасхе. Отдание праздника Пасхи
constexpr auto ASCENSION = WEEK6_AFTER_EASTER_THU ; ///< Четверг 6-й седмицы по Пасхе. Вознесе́ние Госпо́дне
constexpr auto FATHERS_ECU_COUNCIL_1 = SUN7_AFTER_EASTER ; ///< Неделя 7-я по Пасхе. Святых отцов Первого Вселенского Собора
constexpr auto COUNCIL_1 = SUN7_AFTER_EASTER ; ///< Неделя 7-я по Пасхе. Святых отцов Первого Вселенского Собора
constexpr auto ENDOF_ASCENSION = WEEK7_AFTER_EASTER_FRI ; ///< Пятница 7-й седмицы по Пасхе. Отдание праздника Вознесения Господня
constexpr auto TRINITY_SAT = WEEK7_AFTER_EASTER_SAT ; ///< Суббота 7-й седмицы по Пасхе. Троицкая родительская суббота
constexpr auto PENTECOST = PENTECOST_SUN ; ///< Неделя 8-я по Пасхе. День Святой Тро́ицы. Пятидеся́тница
constexpr auto TRINITY_SUN = PENTECOST_SUN ; ///< Неделя 8-я по Пасхе. День Святой Тро́ицы. Пятидеся́тница
constexpr auto HOLY_SPIRIT_DAY = PENTECOST_MON ; ///< Понедельник Пятидесятницы. День Святаго Духа
constexpr auto ENDOF_PENTECOST = PENTECOST_SAT ; ///< Суббота Пятидесятницы. Отдание праздника Пятидесятницы
constexpr auto ALL_SAINTS = SUN1_AFTER_PENTECOST ; ///< Неделя 1-я по Пятидесятнице, Всех святых
constexpr auto ALL_RUS_SAINTS = SUN2_AFTER_PENTECOST ; ///< Неделя 2-я по Пятидесятнице. Всех святых, в земле Русской просиявших
constexpr auto JUDG_SUN = DREAD_JUDGEMENT_SUN ; ///< Неделя мясопу́стная, о Страшном Суде
constexpr auto FORGIVENESS_SUN = CHEESE_SUN ; ///< Неделя сыропустная. Воспоминание Адамова изгнания. Прощеное воскресенье
constexpr auto FORGIVENESS = CHEESE_SUN ; ///< Неделя сыропустная. Воспоминание Адамова изгнания. Прощеное воскресенье
constexpr auto LENT_BEGIN = LENT_WEEK1_MON ; ///< Понедельник 1-й седмицы. Начало Великого поста
constexpr auto LENT_MON1 = LENT_WEEK1_MON ; ///< Понедельник 1-й седмицы. Начало Великого поста
constexpr auto LENT_TUE1 = LENT_WEEK1_TUE ; ///< Вторник 1-й седмицы великого поста
constexpr auto LENT_WED1 = LENT_WEEK1_WED ; ///< Среда 1-й седмицы великого поста
constexpr auto LENT_THU1 = LENT_WEEK1_THU ; ///< Четверг 1-й седмицы великого поста
constexpr auto LENT_FRI1 = LENT_WEEK1_FRI ; ///< Пятница 1-й седмицы великого поста
constexpr auto LENT_SAT1 = LENT_WEEK1_SAT ; ///< Суббота 1-й седмицы великого поста
constexpr auto THEODOR_SAT = LENT_WEEK1_SAT ; ///< Суббота 1-й седмицы великого поста
constexpr auto FEODOR_SAT = LENT_WEEK1_SAT ; ///< Суббота 1-й седмицы великого поста
constexpr auto ORTHODOXY_TRIUMPH = LENT_SUN1 ; ///< Неделя 1-я Великого поста. Торжество Православия
constexpr auto GREGORY_PALAMA = LENT_SUN2 ; ///< Неделя 2-я Великого поста
constexpr auto CROSS_WORSHIP = LENT_SUN3 ; ///< Неделя 3-я Великого поста, Крестопоклонная
constexpr auto IOAN_LADDER = LENT_SUN4 ; ///< Неделя 4-я Великого поста. Прп. Иоанна Лествичника
constexpr auto IOANN_LADDER = LENT_SUN4 ; ///< Неделя 4-я Великого поста. Прп. Иоанна Лествичника
constexpr auto AKAFIST_SAT = LENT_WEEK5_SAT ; ///< Суббота 5-й седмицы великого поста. Суббота Ака́фиста. Похвала́ Пресвятой Богородицы
constexpr auto AKATHIST_SAT = LENT_WEEK5_SAT ; ///< Суббота 5-й седмицы великого поста. Суббота Ака́фиста. Похвала́ Пресвятой Богородицы
constexpr auto THEOTOKOS_LAUDATION = LENT_WEEK5_SAT ; ///< Суббота 5-й седмицы великого поста. Суббота Ака́фиста. Похвала́ Пресвятой Богородицы
constexpr auto MARY_OF_EGYPT = LENT_SUN5 ; ///< Неделя 5-я Великого поста. Прп. Марии Египетской
constexpr auto PALM_MON = LENT_WEEK6_MON ; ///< Понедельник 6-й седмицы великого поста, ва́ий
constexpr auto PALM_TUE = LENT_WEEK6_TUE ; ///< Вторник 6-й седмицы великого поста, ва́ий
constexpr auto PALM_WED = LENT_WEEK6_WED ; ///< Среда 6-й седмицы великого поста, ва́ий
constexpr auto PALM_THU = LENT_WEEK6_THU ; ///< Четверг 6-й седмицы великого поста, ва́ий
constexpr auto PALM_FRI = LENT_WEEK6_FRI ; ///< Пятница 6-й седмицы великого поста, ва́ий
constexpr auto LAZAR_SAT = LENT_WEEK6_SAT ; ///< Суббота 6-й седмицы великого поста, ва́ий. Лазарева суббота
constexpr auto LAZARUS_SAT = LENT_WEEK6_SAT ; ///< Суббота 6-й седмицы великого поста, ва́ий. Лазарева суббота
constexpr auto PALM_SAT = LENT_WEEK6_SAT ; ///< Суббота 6-й седмицы великого поста, ва́ий. Лазарева суббота
constexpr auto PALM_SUN = LENT_SUN6 ; ///< Неделя ва́ий (цветоно́сная, Вербное воскресенье). Вход Господень в Иерусалим
constexpr auto JERUSALEM_ENTRANCE = LENT_SUN6 ; ///< Неделя ва́ий (цветоно́сная, Вербное воскресенье). Вход Господень в Иерусалим
constexpr auto GREAT_MON = LENT_WEEK7_MON ; ///< Страстна́я седмица. Великий Понедельник
constexpr auto GREAT_TUE = LENT_WEEK7_TUE ; ///< Страстна́я седмица. Великий Вторник
constexpr auto GREAT_WED = LENT_WEEK7_WED ; ///< Страстна́я седмица. Великая Среда
constexpr auto GREAT_THU = LENT_WEEK7_THU ; ///< Страстна́я седмица. Великий Четверг. Воспоминание Тайной Ве́чери
constexpr auto GREAT_FRI = LENT_WEEK7_FRI ; ///< Страстна́я седмица. Великая Пятница
constexpr auto GREAT_SAT = LENT_WEEK7_SAT ; ///< Страстна́я седмица. Великая Суббота
constexpr auto LENT_END = LENT_WEEK7_SAT ; ///< Страстна́я седмица. Великая Суббота
constexpr auto COUNCIL_7 = FATHERS_ECU_COUNCIL_7 ; ///< Память святых отцов VII Вселенского Собора
constexpr auto SAT_BEFORE_THEOPHANY = SAT_BEFORE_BAPTISM ; ///< Суббота перед Богоявлением
constexpr auto SUN_BEFORE_THEOPHANY = SUN_BEFORE_BAPTISM ; ///< Неделя перед Богоявлением
constexpr auto SUN_BEFORE_THEOPHANY_READINGS = SUN_BEFORE_BAPTISM_READINGS ; ///< Чтения недели пред Богоявлением
constexpr auto SAT_AFTER_THEOPHANY = SAT_AFTER_BAPTISM ; ///< Суббота по Богоявлении
constexpr auto SUN_AFTER_THEOPHANY = SUN_AFTER_BAPTISM ; ///< Неделя по Богоявлении
constexpr auto RUS_MARTYRS = NEW_MARTYRS_OF_RUSSIA ; ///< Собор новомучеников и исповедников Церкви Русской
constexpr auto HIERARCHS_3 = CONVENTION_OF_3_HIERARCHS ; ///< Собор 3-x свят. Василия Великого, Григория Богослова и Иоанна Златоустого
constexpr auto IOAN_HEAD_FINDING_12 = JOHN_BAPTIST_HEAD_DISCOVERY_1_2 ; ///< Первое и второе Обре́тение главы Иоанна Предтечи
constexpr auto IOANN_HEAD_FINDING_12 = JOHN_BAPTIST_HEAD_DISCOVERY_1_2 ; ///< Первое и второе Обре́тение главы Иоанна Предтечи
constexpr auto IOAN_HEAD_FINDING_3 = JOHN_BAPTIST_HEAD_DISCOVERY_3 ; ///< Третье обре́тение главы Предтечи и Крестителя Господня Иоанна
constexpr auto IOANN_HEAD_FINDING_3 = JOHN_BAPTIST_HEAD_DISCOVERY_3 ; ///< Третье обре́тение главы Предтечи и Крестителя Господня Иоанна
constexpr auto MARTYRS_40_SEBASTE = HOLY_FORTY_MARTYRS_OF_SEBASTE ; ///< Святых сорока́ мучеников, в Севастийском е́зере мучившихся
constexpr auto MARTYRS_40 = HOLY_FORTY_MARTYRS_OF_SEBASTE ; ///< Святых сорока́ мучеников, в Севастийском е́зере мучившихся
constexpr auto FOREFEAST_ANNUNCIATION = FOREFEAST_GOD_MOTHER_ANNUNCIATION ; ///< Предпразднство Благовещения Пресвятой Богородицы
constexpr auto ENDOF_ANNUNCIATION = ENDOF_GOD_MOTHER_ANNUNCIATION ; ///< Отдание праздника Благовещения Пресвятой Богородицы
constexpr auto MARTYR_GEORG = HOLY_GREAT_MARTYR_GEORGE ; ///< Вмч. Гео́ргия Победоно́сца
constexpr auto COUNCIL_1_6 = FATHERS_ECU_COUNCIL_1_6 ; ///< Память святых отцов шести Вселенских Соборов
constexpr auto MOVE_FEAST = MOVEABLE_FEAST ; ///< Двунадесятые переходящие праздники
constexpr auto IMMOVE_FEAST = IMMOVEABLE_FEAST ; ///< Двунадесятые непереходящие праздники

MonthDay easter_date(const int year_number_in_fullindiction) ;
MonthDay find_date(const int year_number_in_fullindiction, const DayProperty property) ;
int apostol_fast_length(const int year_number_in_fullindiction) ;
bool is_date_of(const int year_number_in_fullindiction, const MonthDay date, const DayProperty property) ;
std::vector<MonthDay> find_all_dates(const int year_number_in_fullindiction, const DayProperty property) ;
std::vector<MonthDay> find_all_dates(const int year_number_in_fullindiction,
                                     std::initializer_list<DayProperty> properties) ;
//...
} // namespace fullindiction

```

### Как использовать

#### из Lua

```
...
```

#### из C++

 - Установить компилятор совместимый со стандартом C++20 (GCC 10+, Clang 12+, MSVC 2019 16.11+)
 - Установить CMake версии от 3.31 или выше
 - Установить интерпретатор Lua 5.4 или выше (не обязательно)

Если интерпретатор Lua не установлен в системе то при сборке проекта нужен доступ в интернет, так как CMake будет пытаться скачать исходники чтобы собрать интерпретатор. Далее выполнить команды
```
git clone https://github.com/abramov7613/fullindiction.git
cd fullindiction
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DFULLINDICTION_OFFLINEBUILD=OFF
cmake --build build
```
после этого в каталоге src появятся файлы `fullindiction.h` и `fullindiction.cpp`, a в каталоге `build` будет бинарный файл библиотеки готовый для линковки к стороннему приложению, имя файла зависит от платформы.

#### Пример

```c++
#include <iostream>
#include <string>
#include <stdexcept>
#include "fullindiction.h"

namespace fi = fullindiction;

int year_to_fullindiction_number(int year)
{
  return ((year - 1941) % 532 + 532) % 532 + 1;
}

int main(int argc, char** argv)
try
{
  if (argc != 2) {
    std::cout << "Usage: " << argv[0] << " YEAR\n" ;
    return 0;
  }
  int year = std::stoi(argv[1]);
  int fullindiction_number = year_to_fullindiction_number(year);
  auto [easter_month, easter_day] = fi::easter_date(fullindiction_number);
  std::cout << "дата пасхи в "  << year << " году: "
            << easter_day << '.' << easter_month << '\n';
  auto [rus_martyrs_month, rus_martyrs_day] = fi::find_date(fullindiction_number, fi::RUS_MARTYRS);
  std::cout << "Собор новомучеников и исповедников Церкви Русской "
            << rus_martyrs_month << '.' << rus_martyrs_day << '\n';
  auto moveable_feasts = fi::find_all_dates(fullindiction_number, fi::MOVE_FEAST);
  std::cout << "даты всех переходящих праздников в " << year << " году:\n";
  for (const auto& [month, day]: moveable_feasts) {
    std::cout << day << '.' << month << '\n';
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

