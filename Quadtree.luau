--!optimize 2
--!strict

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

	GetItemsInRange: (self: Quadtree, point: Vector2, radius: number) -> (),
	Contains: (self: Quadtree, position: Vector2) -> (boolean),
	Insert: (self: Quadtree, position: Vector2, item: any) -> (boolean),
	Subdivide: (self: Quadtree) -> (),

	new: (x: number, y: number, width: number, height: number, capacity: number?) -> (Quadtree)
}, Quadtree))

function Quadtree:Contains(position: Vector2): (boolean)
	return
		self._position.X >= position.X and
		self._position.Y >= position.Y and
		(self._position + self._size).X <= position.X and
		(self._position + self._size).Y <= position.Y
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

function Quadtree:Insert(position: Vector2, item: any): (boolean)
	if not self:Contains(position) then return false end

	if #self._items < self._capacity and not self._subdivided then
		table.insert(self._items, {
			_position = position,
			_data = item,
		})
	elseif self._subdivided then
		self:Subdivide()

		for _, child in pairs(self._children) do
			child:Insert(position, item)
		end
	else
		return false
	end

	return true
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