#import "@preview/charged-ieee:0.1.3": ieee

#show link: set text(fill: blue)
#show link: underline

#show: ieee.with(
  title: [Модель QUBO для оптимизации проблемы маршрутизации транспортных средств],
  authors: (
    (
      name: "Морев Георгий",
      organization: [МФТИ],
    ),
  ),
  index-terms: ("Scientific writing", "Typesetting", "Document creation", "Syntax"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

= Введение

Задача маршрутизации транспортных средств (VRP) @TDP является базовой NP-полной математической задачей, связанной с оптимизацией планирования, логистики и транспортировки. Цель состоит в том, чтобы спланировать поездки на транспортных средствах для максимально эффективного обслуживания заданного количества клиентов. Благодаря недавнему интересу к квантовым отжиговым машинам, которые стали коммерчески доступными компанией D-Wave Systems Inc. @D-Wave, исследование VRP как квадратичная безусловная бинарная оптимизация (QUBO) стало очень важным, особенно в попытке достичь квантово-механической оптимизации реальных проблем. Также стоит отметить, что в данной статье будет рассматриваться более обобщенная версия задачи, а именно MDCVRP (Multi-depot capacitated vehicle routing problem), то есть у каждой машины будет грузоподъёмность, будет несколько складов и количество ресурсов на каждом складе будет ограничено.

= Постановка задачи

Пусть $G = (V, E)$ - полный граф, где $V = {1, ..., n}$ — набор вершин, представляющих n местоположений клиентов, также будут $k$ вершин, являющиеся складами, E — набор неориентированных рёбер. У каждого ребра $(i, j) ∈ E, i ≠ j$ есть неотрицательная стоимость $D_(i j)$. Эта стоимость может, например, представлять (географическое) расстояние между двумя клиентами $i$ и $j$. Кроме того, предположим, что на складе размещено $m_k$ транспортных средств с вместимостью $Q_k$. Кроме того, каждый клиент имеет определенный спрос $q_i$. MDCVRP состоит из поиска набора маршрутов транспортных средств, таких что:
- все маршруты начинаются и заканчиваются на депо
- каждый клиент в $V$ посещается ровно один раз ровно одним транспортным средством
- Для каждого маршрута сумма спросов клиентов не превышает вместимости транспортного средства
- Для каждого склада сумма спросов клиентов на пути машин, привязанных к этому складу не превышает вместимости склада
- сумма стоимостей всех маршрутов минимальна с учетом ограничений, указанных выше

= Модель QUBO

Модель QUBO (Quadratic Unconstrained Binary Optimization) описывает задачу оптимизации в виде квадратичной формы:

$ H(x) = sum_(1 <= i <= j <= N) Q_(i j) x_i x_j = x^T Q x $

, где:
- $x$ — вектор бинарных переменных (0 или 1),
- $Q$ — симметричная матрица коэффициентов размера $N times N$.
QUBO минимизирует гамильтониан $H(x)$, который соответствует энергии системы.

= Модель

== Параметры

Определим параметры, которые мы будем использовать:

- Задаваемые параметры
  - $T$ - Множество всех клиентов
  - $D$ - Множество всех складов
  - $K$ - множество всех машин
  - $D_(i j), (i, j in T)$ - расстояние между клиентами
  - $D_(d i), (d in D, i in T)$ - расстояние между клиентами и складами
  - $V_d, (d in D)$ - Количество товаров на складе
  - $Q_k, (k in K)$ - Вместимость машины
  - $q_i, (i in T)$ - Количество товаров необходимое клиенту
  - $y_(k d), (k in K, d in D)$ - 1, если машина $k$ стоит на складе $d$

- Оптимизируемые параметры
  - $x_(i j k), (i, j in T, k in K)$ - 1, если машина $k$ поедет к клиенту $j$ после клиента $i$
  - $u_(i k)$ - 1, если машина $k$ посетит клиента $i$ первым
  - $n_(i k)$ - 1, если машина $k$ посетит клиента $i$ последним

== Целевые функции и ограничения

_Целевая функция:_ Функия описывающая издержки для передвижения всех машин. Данную функцию мы хотим минимизировать.

$ "Min: " sum_(k in K) sum_(i in T) sum_(j in T) D_(i j)x_(i j k) + sum_(k in K) sum_(i in T) sum_(d in D) D_(i d)u_(i k)y_(k d) \ + sum_(k in K) sum_(i in T) sum_(d in D) D_(i d)n_(i k)y_(k d) $

_Ограничение 1:_ Нельзя поехать к тому же покупателю.

$ forall i in T, forall k in K: " " x_(i i k)=0 $

_Ограничение 2:_ К каждому покупателю должна приехать ровно одна машина.

$ forall i in T: " " sum_(k in K) sum_(j in T) x_(j i k) + sum_(k in K) u_(i k) = 1 $

_Ограничение 3:_ От каждого покупателя должна уехать ровно одна машина.

$ forall i in T: " " sum_(k in K) sum_(j in T) x_(i j k) + sum_(k in K) n_(i k) = 1 $

_Ограничение 4:_ Каждая машина должна отъехать ровно с одного склада.

$ forall k in K: " " sum_(i in T)u_(i k) = 1 $

_Ограничение 5:_ Каждая машина должна приехать ровно на один склад.

$ forall k in K: " " sum_(i in T)n_(i k) = 1 $

_Ограничение 6:_ "Целостность маршрута". Если машина приехала к покупателю, то она должна уехать от него.

$ forall k in K, forall i in T: \ u_(i k) + sum_(j in T)x_(j i k) - n_(i k) - sum_(p in T)x_(i p k) = 0 $

_Ограничение 7:_ У машин не должно быть возможности иметь на своем маршруте цикл из городов, который они не посещают.

Пример, удовлетворяющий ограничениям 1-6, который мы хотим запретить.

#image("constraint_7.png")

Например, представим сценарий, когда дано 2 склада $D_1, D_2$, в каждом из которых по 1 машине, $V_1$ на $D_1$ и $V_2$ на $D_2$. Пусть также есть 4 покупателя: $С_i, i = 1...4$. Потенциально маршруты могли распределиться так:
- Для $V_1: " " D_1 -> C_1 -> D_1, C_2->C_3, C_3->C_2$
- Для $V_2: " " D_2 -> C_4 -> D_2$
Данные маршруты удовлетворяют всем ограничениям, наложенным выше, но не являются правильными потому что в цикл из покупателей $C_2, C_3$ никто никогда не заедет.

Обозначим за $PP(T)$ - множество всех подмножеств $T$, тогда необходимо наложить ограничение:

$ forall S in PP(t), 2 <= |S| <= |T|: " " sum_(k in K)sum_(i, j in S)x_(i j k) <= |S|-1 $

_Ограничение 8:_ Суммарное количество продуктов, доставленное покупателям не должно превышать вместимости машины.

$ forall k in K: " " sum_(i in T)sum_(j in T)q_i x_(i j k) + sum_(i in T)q_i n_(i k) <= Q_k $

_Ограничение 9:_ Суммарное количество продуктов, доставленное покупателям с каждого склада не должно превышать его вместимости.

$ forall d in D: \ sum_(k in K)y_(k d)(sum_(i in T)sum_(j in T)q_i x_(i j k) + sum_(i in T)q_i n_(i k)) <= V_d $

*Замечание: * при реализации стоит создать фиктивные оптимизируемые параметры $u_(0 k)$ и $n_(0 k)$, которые будут равны 1 в случае, если машине не надо никуда ехать.

== Гамильтониан задачи

_Общий подход:_ 

Для ограничений вида $sum_(i=1)^(n_x)A_i x_i = b$, где $x_i$ - i-ый оптимизируемый параметр, Гамильтониан будет записан как $(sum_(i=1)^(n_x)A_i x_i - b)^2$

Для ограничений вида $sum_(i=1)^(n_x)A_i x_i<= b$, чтобы представить модель QUBO придется снчала представить ограничение в виде равенства @inequality. Это можно сделать путем введения резервных переменных, и записать Гамильтониан в виде $(sum_(i=1)^(n_x) A_i x_i + sum_(j=0)^(n_lambda) 2^lambda lambda_j - b)^2$, где $n_lambda = ceil.l log_2(b+1) ceil.r $.

Гамильтониан целевой функции:

$ H_O = sum_(k in K) sum_(i in T) sum_(j in T) D_(i j)x_(i j k) + sum_(k in K) sum_(i in T) sum_(d in D) D_(i d)u_(i k)y_(k d) \ + sum_(k in K) sum_(i in T) sum_(d in D) D_(i d)n_(i k)y_(k d) $

Ниже приведены члены Гамильтониана $H_C_i$, которые представляют i-ое ограничение, приведенное выше.

$ H_C_1 = B sum_(i in T) sum_(k in K)(x_(i i k)) $

$ H_C_2 = B sum_(i in T)(1 - (sum_(k in K) sum_(j in T) x_(j i k) + sum_(k in K) u_(i k) ))^2 $

$ H_C_3 = B sum_(i in T)(1 - (sum_(k in K) sum_(j in T) x_(i j k) + sum_(k in K) n_(i k) ))^2 $

$ H_C_4 = B sum_(k in K) (1 - (sum_(i in T)u_(i k)))^2 $

$ H_C_5 = B sum_(k in K) (1 - (sum_(i in T)n_(i k)))^2 $

$ H_C_6 = B sum_(i in T) sum_(k in K) (u_(i k) + sum_(j in T)x_(j i k) \ - n_(i k) - sum_(j in T)x_(i j k)) "" ^2 $

$ H_C_7 = B sum_(S in PP(T) 2 <= |S| <= |T|) (sum_(k in K)sum_(i, j in S)x_(i j k) \ + sum_(l=0)^(ceil.l log_2 (|S|) ceil.r) 2^l lambda_(l S) - |S|+1) "" ^2 $

$ H_C_8 = B sum_(k in K) (sum_(i in T)sum_(j in T)q_i x_(i j k) + sum_(i in T)q_i n_(i k) \ + sum_(l=0)^(ceil.l log_2 (Q_k + 1) ceil.r) 2^l lambda_(l k) - Q_k) "" ^2 $

$ H_C_9 = B sum_(d in D) (sum_(k in K)y_(k d)(sum_(i in T)sum_(j in T)q_i x_(i j k) + sum_(i in T)q_i n_(i k)) \ + sum_(l=0)^(ceil.l log_2 (V_d+1) ceil.r) 2^l lambda_(l d) - V_d) "" ^2 $

Где $B$ - большая константа, обозначающая штраф, который возникнет при нарушении ограничений.

Тогда Гамильтониан данной задачи получился равен: $ H_F = H_O + sum_(i=1)^9 H_C_i $

= Реалмзация

Для нас удобно, что это уже задача минимизации. В данном случае QUBO-матрица получается при помощи явного раскрытия скобок в выражении для стоимости. Можно заметить, что в этом случае получаем также элементы 0-й степени, но формат QUBO-матрицы такого не предусматривает. Но во-первых, в данном случае легко можем определить разницу между $X^T Q X$ и минимумом $H_F$, а во-вторых, для нас это не столь важно – нам нужно решение, а значение энергии/функции стоимости получается без каких-либо проблем за полиномиальное время. @QML

Для того, чтобы не усложнять реализацию, было написано решение задачи MDVRP, то есть мы не учитываем ограничения 8-9 (на вместимость складов и грузоподъёмность курьеров).

#link("https://github.com/GoshiX/quantum-computing")[Реализация на Python]

= Оптимизации

Можно заметить, что количество оптимизируемых параметров можно оценить как $O(2^(|T|))$, где $T$ - множество всех клиентов, т.к. нам нужно выполнить ограничение 7, которое запрещает иметь цикл, не пересекающийся с путем, то есть есть ограничение на каждое подмножество размера больше 2, количество которых оценивается как $O(2^(|T|))$.

Для более оптимального решения предлагается воспользоваться Формулой Миллера-Такера-Землина @MTZ. 

Основная её идея заключается в том, чтобы поставить в соответсвие каждому клиенту оптимизируемую переменную $t_i in NN_0$ и поддерживать инвариант: 

$ forall k in K, forall i, j in T: x_(i j k) = 1 -> t_i < t_j $

Таким образом количество оптимизируемых параметров для данного ограничения снизится с $2^(|T|)$ бинарных до $|T|$ целочисленных, которые будут задавать $t_i$ и $|T|*|T|*|K|$ целочисленных для сведения неравенства к матрице QUBO.

Цикл в таком случае невозможен, так как на цикле можно найти такой путь, который пройдет дважды по одной вершине, но тогда инвариант о том, что при переходе к следующей вершине её параметр $t$ увеличивается.

Заметим, что для любого расположения вершин на маршруте можно найти такие параметры $t_i$, что $forall i in T: t_i < |T|$.

Необходимо обойти все маршруты начиная с каждого из складов и поставить в соответствие каждому городу число от $0$ до $|T| - 1$ по возрастанию в порядке обхода. #align(right)[$qed$]

_Ограничение 10:_ У машин не должно быть возможности иметь на своем маршруте цикл из городов, который они не посещают (оптимальная версия).

Требуемое ограничение можно записать следующим образом:

$ forall i, j in T: t_i - t_j <= cases(-1", если " sum_(k in K) x_(i j k) = 1, |T| - 1", иначе") $

Проведем преобразования, чтобы описать данное ограничение Гамильтонианом.

$ forall i, j in T: t_i - t_j <= -1 + |T|(1 - sum_(k in K) x_(i j k)) $

Тогда запишем Гамильтониан, выразив оптимизируемую переменную через бинарные следующим образом: $t_i = sum_(l = 0)^(ceil.l log_2(t_i + 1) ceil.r) t_(l i)$ используя уже известное сведение @inequality:

$ H_C_(10) = B sum_(i, j in T \ i != j) ( sum_(l=0)^(ceil.l log_2(|T| + 1) ceil.r) 2^l t_(l i) - sum_(l=0)^(ceil.l log_2(|T| + 1) ceil.r) 2^l t_(l j) \ + sum_(l=0)^(ceil.l log_2(2(|T| + 1)) ceil.r) 2^l lambda_l_(i j) + |T| sum_(k in K) x_(i j k) - |T| + 1 ) "" ^ 2 $

Таким образом, теперь можно использовать ограничение 10 вместо ограничения 7.

= Методы решения на классическом компьютере

== Полный перебор

Для каждой из машин рекурсивно переберем количество клинетов, которые будут к ней относиться и также рекурсивно выбираем количество тех клиентов, которые относятся к текущей машине, передаваая оставшихся клиентов следующим машинам, затем после того, как зафиксировано, какая машина обслуживает какой набор клиентов возьмем декартово произведение между всеми возможными перестановками для каждой машины.

_Пример:_ Хотим разделить 3 клиентов между 2 машинами

- Первая машина обслуживает 0 клиентов $->$ вторая - 3 клиентов
- - Добавить к ответам все перестановки ({}, {1, 2, 3})
- - - Ответ: *((), (1, 2, 3))*
- - - Ответ: *((), (1, 3, 2))*
- - - Ответ: *((), (2, 1, 3))*
- - - Ответ: *((), (2, 3, 1))*
- - - Ответ: *((), (3, 1, 2))*
- - - Ответ: *((), (3, 2, 1))*
- Первая машина обслуживает 1 клиента $->$ вторая - 2 клиентов
- - Первая обслуживает {1} $->$ добавить к ответам все перестановки ({1}, {2, 3})
- - - Ответ: *((1), (2, 3))*
- - - Ответ: *((1), (3, 2))*
- - Первая обслуживает {2} $->$ добавить к ответам все перестановки ({2}, {1, 3})
- - - Ответ: *((2), (1, 3))*
- - - Ответ: *((2), (3, 1))*
- - Первая обслуживает {3} $->$ добавить к ответам все перестановки ({3}, {1, 2})
- - - Ответ: *((3), (1, 2))*
- - - Ответ: *((3), (2, 1))*
- Первая машина обслуживает 2 клиентов $->$ вторая - 1 клиента
- - Первая обслуживает {1, 2} $->$ добавить к ответам все перестановки ({1, 2}, {3})
- - - Ответ: *((1, 2), (3))*
- - - Ответ: *((2, 1), (3))*
- - Первая обслуживает {1, 3} $->$ добавить к ответам все перестановки ({1, 3}, {2})
- - - Ответ: *((1, 3), (2))*
- - - Ответ: *((3, 1), (2))*
- - Первая обслуживает {2, 3} $->$ добавить к ответам все перестановки ({2, 3}, {1})
- - - Ответ: *((2, 3), (1))*
- - - Ответ: *((3, 2), (1))*
- Первая машина обслуживает 3 клиентов $->$ вторая - 0 клиентов
- - Добавить к ответам все перестановки ({1, 2, 3}, {})
- - - Ответ: *((1, 2, 3), ())*
- - - Ответ: *((1, 3, 2), ())*
- - - Ответ: *((2, 1, 3), ())*
- - - Ответ: *((2, 3, 1), ())*
- - - Ответ: *((3, 1, 2), ())*
- - - Ответ: *((3, 2, 1), ())*

== Генетический алгоритм @genetic-algo

Данный алгоритм представляет собой гибридный генетический алгоритм (HGA) для решения задачи MDVRP. Основная идея заключается в комбинации генетического алгоритма с эвристическими методами, такими как метод сбережений Кларка-Райта и метод ближайшего соседа. Алгоритм включает три ключевых этапа: группировку клиентов по депо, маршрутизацию внутри каждого депо и оптимизацию последовательности доставки. Данные этапы можно сделать как сгенеровав начальное решения путем случайного распределения клиентов по депо и маршрутам, так и жадными алгоритмами. После этого для улучшения решений используется процедура итераций, где случайные мутации (например, swap, insert, 2-opt) модифицируют маршруты, а новые решения принимаются либо жадно, либо с вероятностным критерием (например, алгоритм Метрополиса-Гастингса). Такой подход прост в рализации и позволяет избегать локальных оптимумов, но не гарантирует высокого качества решений и может требовать тонкой настройки параметров (например, температуры в имитации отжига). Для улучшения эффективности случайные методы часто комбинируют с  Критерием остановки может служить максимальное число итераций, отсутствие улучшений или ограничение по времени. Хотя метод гибок и легко адаптируется, его основными недостатками остаются медленная сходимость для больших задач и зависимость от начальных условий.

Работу генетического алгоритма можно описать следующей схемой:

#image("geneticAlgo.png", width: 100%)

= Сравнение результатов

#emph(text(red)[
  В процесее написания, следите за обновлениями!
])