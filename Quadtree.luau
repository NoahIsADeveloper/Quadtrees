--!optimize 2
--!strict

--[[

MIT License

	Copyright (c) 2025 NoahIsADeveloper

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

]]

local Quadtree = {} :: Quadtree
Quadtree.__index = Quadtree
type Quadtree = typeof(setmetatable({} :: {
	__index: Quadtree,
	_position: Vector2,
	_size: Vector2,
	_children: {Quadtree},
	_items: {any},
	_capacity: number,
	_subdivided: boolean,

	GetItemsInRange: (self: Quadtree, point: Vector2, radius: number) -> ({any}),
	Contains: (self: Quadtree, position: Vector2) -> (boolean),
	Insert: (self: Quadtree, position: Vector2, item: any) -> (boolean),
	Clear: (self: Quadtree) -> (),
	Subdivide: (self: Quadtree) -> (),

	new: (x: number, y: number, width: number, height: number, capacity: number?) -> (Quadtree)
}, Quadtree))

function Quadtree:Contains(position: Vector2): boolean
	return
		position.X >= self._position.X and
		position.X <= self._position.X + self._size.X and
		position.Y >= self._position.Y and
		position.Y <= self._position.Y + self._size.Y
end

function Quadtree:GetItemsInRange(point: Vector2, radius: number): {any}
	local results = {}

	local x1, y1 = self._position.X, self._position.Y
	local x2, y2 = x1 + self._size.X, y1 + self._size.Y
	if point.X + radius < x1 or point.X - radius > x2 or
	   point.Y + radius < y1 or point.Y - radius > y2 then
		return results
	end

	for _, entry in ipairs(self._items) do
		if (entry._position - point).Magnitude <= radius then
			table.insert(results, entry._data)
		end
	end

	if self._subdivided then
		for _, child in pairs(self._children) do
			local childResults = child:GetItemsInRange(point, radius)
			for _, r in ipairs(childResults) do
				table.insert(results, r)
			end
		end
	end

	return results
end

function Quadtree:Clear()
	self._items = {}
	if self._subdivided then
		for _, child in pairs(self._children) do
			child:Clear()
		end
	end
end


function Quadtree:Subdivide()
	local halfX = math.floor(self._size.X / 2)
	local halfY = math.floor(self._size.Y / 2)

	self._children = {
		Quadtree.new(self._position.X, self._position.Y, halfX, halfY),
		Quadtree.new(self._position.X + halfX, self._position.Y, self._size.X - halfX, halfY),
		Quadtree.new(self._position.X, self._position.Y + halfY, halfX, self._size.Y - halfY),
		Quadtree.new(self._position.X + halfX, self._position.Y + halfY, self._size.X - halfX, self._size.Y - halfY),
	}

	for _, child in pairs(self._children) do
		child:Subdivide()
	end

	self._subdivided = true
end

function Quadtree:Insert(position: Vector2, item: any): boolean
	if not self:Contains(position) then return false end

	if #self._items < self._capacity and not self._subdivided then
		table.insert(self._items, { _position = position, _data = item })
		return true
	end

	if not self._subdivided then
		self:Subdivide()
	end

	for _, child in pairs(self._children) do
		if child:Insert(position, item) then
			return true
		end
	end

	return false
end

function Quadtree.new(x: number, y: number, width: number, height: number, capacity: number?): Quadtree
	local object = setmetatable({
		_position = Vector2.new(x, y),
		_size = Vector2.new(width, height),
		_children = {},
		_items = {},
		_capacity = capacity or 5,
		_subdivided = false,
	}, Quadtree)

	return object :: any
end

return Quadtree
