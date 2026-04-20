@tool
extends Node
class_name DungeonGenerator
## Used to gernerate a dungeon map
##
## An extend description

## The directions of travel
"""
const DIRECTIONS = [
	[ 0,-1],
	[ 0, 1],
	[-1, 0],
	[ 1, 0],
]
"""


@export var tileset: TileSet 
@export var seed: int = 100

var visited: Array[Vector2i] = []
@export var base_data: Array[Array] = []
var TOTAL_SQUARES: int = 0 
var b_width: int = 0
var b_height: int = 0
var curr_squares: int = 0

func generate_dungeon(width: int, height: int, tot_squ: int) -> void:
	b_height = height
	b_width = width
	TOTAL_SQUARES = tot_squ
	_init_grid()
	build_base_array()

func _init_grid() -> Array:
	curr_squares = 0
	var grid: Array = []
	visited = []
	for r in b_height:
		var grid_row = []
		for c in b_width:
			grid_row.append(null)
		grid.append(grid_row)
	return grid

func build_base_array():
	var start_row = 0
	var start_col = 0
	var start_grid = _init_grid()
	base_data = _build_base_array(start_col, start_row, start_grid, 15)

func choose_random_bitmask(mask: int) -> DungeonTile:
	var choices: Array[DungeonTile]
	for tile in TilePalette.tile_definitions:
		if tile.tile_openings | mask == tile.tile_openings:
			choices.append(tile)
	return choices.pick_random()

func _find_openings(loc: Vector2i) -> int:
	# look around itself and if theres a visited tile around
	# use that to set the bitmask
	var mask = 0
	if visited.has(Vector2i(loc.y-1,loc.x)):
		mask |= DungeonTile.NORTH
	if visited.has(Vector2i(loc.y+1,loc.x)):
		mask |= DungeonTile.SOUTH
	if visited.has(Vector2i(loc.y,loc.x+1)):
		mask |= DungeonTile.EAST
	if visited.has(Vector2i(loc.y,loc.x-1)):
		mask |= DungeonTile.WEST
	return mask

func _in_range(loc: Vector2i) -> bool:
	if loc.x >= 0 && loc.x <= b_height && loc.y >= 0 && loc.y <= b_width:
		return true
	return false

func _build_base_array(pos_x: int, pos_y: int, grid: Array[Array], mask: int ) -> Array:
	
	"""
	create something that forms a certain size 2d array, carves out
	the maze with some of the outside walls just having paths out and 
	then add a room of a set size to the corridor that leads out

	first implementation: start from 0,0 and randomly spread out like a tree 
	until you cant go any further
	and whether you branch or not is also random, and spread until a set number 
	of tiles has been placed
	"""

	# make curr spot visited, random chance split out with recursion (if possible)
	# if we reach a spot where we cannot go forward -> backtrack, if you backtrack
	# all the way back to the start, return that grid. if you can spread in any of the
	# cardinal directions, use the bitmask to choose which tile can be placed
	#
	# Base Case
	# new idea: I use dfs and randomly choose a tile that would work in that spot and 
	# based on the tiles current opening 

	if curr_squares >= TOTAL_SQUARES:
		return grid
	
	var currMask = mask
	var fringe: Array[Vector2i] = []
	fringe.append(Vector2i(pos_x,pos_y))
	while(!fringe.is_empty()):
		var currlocTile = fringe.pop_back()
		currMask = _find_openings(Vector2i(pos_x,pos_y))
		visited.append(currlocTile)
		# 
		# take the bitmask and grab the actual tile pattern  
		var actualTile = choose_random_bitmask(currMask)
		
		# place the tile pattern at the location
		grid[pos_y][pos_x] = actualTile
		# this line finds the opening 
		var openings = actualTile.tile_openings
		
		
		
		if openings & DungeonTile.NORTH && !visited.has(Vector2i(pos_x-1,pos_y)) && _in_range(Vector2i(pos_x-1,pos_y)):
			fringe.append(Vector2i(pos_x-1,pos_y))
		if openings & DungeonTile.SOUTH && !visited.has(Vector2i(pos_x+1,pos_y)) && _in_range(Vector2i(pos_x+1,pos_y)):
			fringe.append(Vector2i(pos_x+1,pos_y))
		if openings & DungeonTile.EAST && !visited.has(Vector2i(pos_x,pos_y+1)) && _in_range(Vector2i(pos_x,pos_y+1)):
			fringe.append(Vector2i(pos_x,pos_y+1))
		if openings & DungeonTile.NORTH && !visited.has(Vector2i(pos_x,pos_y-1)) && _in_range(Vector2i(pos_x,pos_y-1)):
			fringe.append(Vector2i(pos_x,pos_y-1))	
		
	return	grid
