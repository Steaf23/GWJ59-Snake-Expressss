class_name GridOverlay
extends TileMapLayer


func setup(grid_rect: Rect2) -> void:
	for y in range(grid_rect.position.y, grid_rect.end.y):
		for x in range(grid_rect.position.x, grid_rect.end.x):
			if x % 2 == y % 2:
				set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
