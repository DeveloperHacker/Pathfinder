
local Deque = dofile("std/deque.lua")
local Stream = dofile("std/stream.lua")

local Graph = {}

local inf = 1/0

function Graph.mfae(A)
    local way = {}
    local dump = {}
    local V
    A, V = Graph.reduction(0, A)

    while (Stream.valueOf(A):toLine({#A, #A}):filter(function (value) return value ~= inf end):length() > 1) do
        local nway = Stream.deepcopy(way)
        local V1, A1, V2, A2, i, j = Graph.slice(V, A)
        way[#way + 1] = {["left"] = i, ["right"] = j}
        if (#way < #A - 1) then
            A1 = Graph.correct(A1, way)
        end
        dump[#dump + 1] = {["way"] = way, ["V"] = V1, ["A"] = A1}
        dump[#dump + 1] = {["way"] = nway, ["V"] = V2, ["A"] = A2}
        V, key = Stream.valueOf(dump):map(function (value) return value.V end):min()
        A = dump[key].A
        way = dump[key].way
        table.remove(dump, key)
    end

    return V, way
end

function Graph.slice(V, A)
    local B = {}
    local I = {}
    local J = {}
    for i = 1, #A do
        for j = 1, #A do
            if (A[i][j] == 0) then
                minC, _ = Stream.valueOf(A[i]):replace(j, inf):min()
                minD, _ = Stream.valueOf(A):indexedMap(function (key, value) return (key == i) and inf or value[j] end):min()
                B[#B + 1] = minC + minD
                I[#I + 1] = i
                J[#J + 1] = j
            end
        end
    end
    local V2, key = Stream.valueOf(B):max()
    local i = I[key]
    local j = J[key]
    V2 = V + V2
    local A1 = Stream.deepcopy(A)
    A1[j][i] = inf
    A1 = Stream.valueOf(A1):map(function (value)
        value[j] = inf
        return value
    end):replace(i, Stream.replicate(inf, #A):toTable()):toTable()
    A1, V1 = Graph.reduction(V, A1)
    local A2 = Stream.deepcopy(A)
    A2[i][j] = inf
    return V1, A1, V2, A2, i, j
end
    
function Graph.reduction(Vprev, A)
    local A = Stream.deepcopy(A)
    local RowMin = Stream.valueOf(A)
        :map(function (value) return Stream.valueOf(value):min() end)
        :map(function (value) return value == inf and 0 or value end)
        :toTable()
    for i = 1, #A do
        for j = 1, #A do
            A[i][j] = A[i][j] - RowMin[i]
        end
    end
    local ColumnMin = Stream.valueOf(A)
        :reduce(function (acc, value) return Stream.valueOf(acc):indexedMap(function (i, min) return (min > value[i]) and value[i] or min end) end)
        :map(function (value) return value == inf and 0 or value end)
        :toTable()
    for i = 1, #A do
        for j = 1, #A do
            A[i][j] = A[i][j] - ColumnMin[j]
        end
    end
    local V = Vprev + Stream.valueOf(RowMin):sum() + Stream.valueOf(ColumnMin):sum()
    return A, V
end

function Graph.correct(A, way)
    local A = Stream.deepcopy(A)
       local ways = Graph.forbidden(way)
    for i = 1, #ways do
        local left = ways[i]:left()
        local right = ways[i]:right()
        if (A[left][right] ~= inf) then
            A[left][right] = inf
        end
    end
    return A
end

function Graph.forbidden(links)
    local ways = {}
    local links = Stream.deepcopy(links)
    while (#links > 0) do
        local left = links[1].left
        local right = links[1].right
        table.remove(links, 1)
        local way = Deque:new()
        way:leftPush(left)
        way:rightPush(right)
        while (true) do
            local tmp = Stream.valueOf(links):map(function (value) return (left == value.right) and 1 or 0 end)
            if ((tmp:sum() or 0) == 0) then break end
            _, i = tmp:max()
            left = links[i].left
            table.remove(links, i)
            way:leftPush(left)
        end
        while (true) do
            local tmp = Stream.valueOf(links):map(function (value) return (right == value.left) and 1 or 0 end)
            if ((tmp:sum() or 0) == 0) then break end
            _, i = tmp:max()
            right = links[i].right
            table.remove(links, i)
            way:rightPush(right)
        end
        ways[#ways + 1] = way
    end
    return ways
end

return Graph
