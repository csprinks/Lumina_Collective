extends Control

class_name RollingNumbers

# Configuration variables
@export var font_size: int = 32
@export var font: FontFile  # Custom font choice
@export var digit_colors: Array[Color] = [Color.WHITE]  # Colors for digits
@export var digit_spacing: float = 0.0  # Horizontal space between digits
@export var roll_delay: float = 0.1  # Delay between digit reveals
@export var display_time: float = 1.0  # Time to show full number
@export var outline_size: int = 2  # Outline size for text
@export var outline_color: Color = Color.BLACK  # Color for text outline
@export var bottom_margin: int = 20  # Distance from bottom
@export var bounce_height: float = 20.0  # Maximum bounce height
@export var bounce_duration: float = 0.5  # Duration of each bounce
@export var bounce_count: int = 2  # Number of bounces
@export var bounce_decay: float = 0.5  # Height reduction per bounce
@export var debug: bool = false  # Enable debug visualization

var effects = []  # Stores active number effects

@onready var texture_rect = $TextureRect
@onready var fallback_font = ThemeDB.fallback_font

func _ready():
	# Connect mouse click signal
	texture_rect.gui_input.connect(_on_texture_rect_gui_input)
	# Set mouse filter to detect clicks
	texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set control size to match texture_rect using deferred call
	call_deferred("update_size")

func update_size():
	size = texture_rect.size

func _on_texture_rect_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Generate random number and start effect
		var number = randi_range(100, 1000)
		var effect = {
			"number": str(number),
			"current_index": 0,
			"timer": 0.0,
			"state": 0,  # 0=rolling, 1=displaying, 2=finished
			"bounce_data": []  # Stores bounce animation data for each digit
		}
		effects.append(effect)

func _process(delta):
	var needs_redraw = false
	
	# Update all effects
	for effect in effects:
		effect.timer += delta
		
		# Update bounce animations
		for i in range(len(effect.bounce_data)):
			var bounce = effect.bounce_data[i]
			if bounce.current_bounce < bounce_count:
				bounce.timer += delta
				
				# Calculate bounce progress
				var progress = bounce.timer / bounce_duration
				
				# Wrap progress for multiple bounces
				if progress > 1.0:
					# Move to next bounce
					bounce.current_bounce += 1
					bounce.timer = 0.0
					progress = 0.0
					
					# Apply decay to height
					bounce.current_height *= bounce_decay
				
				if bounce.current_bounce < bounce_count:
					# Calculate offset using sine wave
					var height = bounce.current_height
					bounce.offset = -height * sin(progress * PI)
					needs_redraw = true
		
		match effect.state:
			0:  # Rolling state
				if effect.timer >= roll_delay:
					effect.timer = 0.0
					effect.current_index += 1
					
					# Start bounce animation for the new digit
					var bounce = {
						"current_bounce": 0,
						"timer": 0.0,
						"offset": 0.0,
						"current_height": bounce_height
					}
					effect.bounce_data.append(bounce)
					
					if effect.current_index >= len(effect.number):
						effect.state = 1  # Move to display state
					needs_redraw = true
			1:  # Display state
				if effect.timer >= display_time:
					effect.state = 2  # Mark for removal
					needs_redraw = true
	
	# Remove finished effects
	var prev_count = len(effects)
	effects = effects.filter(func(e): return e.state != 2)
	if len(effects) != prev_count:
		needs_redraw = true
	
	if needs_redraw:
		queue_redraw()

func _draw():
	# Skip if we don't have a valid font or size
	if size.x <= 0 or size.y <= 0:
		return
	
	# Get current content scale factor
	var content_scale = get_tree().root.content_scale_factor
	var font_size_adjusted = font_size * content_scale
	var scaled_digit_spacing = digit_spacing * content_scale
	
	# Use custom font if available, otherwise fallback
	var draw_font = font if font != null else fallback_font
	if draw_font == null:
		return
	
	# Calculate bottom center position
	var base_position = Vector2(
		size.x / 2, 
		size.y - bottom_margin - (font_size_adjusted / 2)
	)
	
	# Draw debug markers
	if debug:
		# Draw crosshair at base_position
		draw_line(base_position - Vector2(10, 0), base_position + Vector2(10, 0), Color.RED, 2)
		draw_line(base_position - Vector2(0, 10), base_position + Vector2(0, 10), Color.RED, 2)
		
		# Draw text position info
		var debug_text = "Text Position: " + str(base_position)
		draw_string(
			draw_font, 
			Vector2(10, 20), 
			debug_text, 
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 
			font_size_adjusted,
			Color.YELLOW
		)
		
		# Draw control boundaries
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0, 0, 0.3), false, 2.0)
	
	for effect in effects:
		var display_text = effect.number.substr(0, effect.current_index + 1)
		
		# Pre-calculate total text width with spacing
		var total_width = 0.0
		for i in range(len(display_text)):
			var character = display_text[i]
			var char_size = draw_font.get_char_size(character.unicode_at(0), font_size_adjusted)
			total_width += char_size.x
			if i < len(display_text) - 1:
				total_width += scaled_digit_spacing
		
		var draw_pos = base_position - Vector2(total_width / 2, 0)
		
		# Draw each character separately with its own bounce offset and color
		var current_x = draw_pos.x
		for i in range(len(display_text)):
			var character = display_text[i]
			var char_size = draw_font.get_char_size(character.unicode_at(0), font_size_adjusted)
			
			# Apply bounce offset to this character
			var char_offset = Vector2(0, 0)
			if i < len(effect.bounce_data):
				char_offset.y = effect.bounce_data[i].offset
			
			var char_pos = Vector2(current_x, draw_pos.y) + char_offset
			
			# Determine color for this digit
			var digit_color = digit_colors[i % len(digit_colors)] if len(digit_colors) > 0 else Color.WHITE
			
			# Draw character outline
			draw_string_outline(
				draw_font, 
				char_pos, 
				character, 
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 
				font_size_adjusted,
				outline_size,
				outline_color
			)
			
			# Draw main character
			draw_string(
				draw_font, 
				char_pos, 
				character, 
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 
				font_size_adjusted,
				digit_color
			)
			
			current_x += char_size.x + scaled_digit_spacing
		
		# Draw debug text info
		if debug:
			var pos_text = "Pos: " + str(draw_pos) + " Width: " + str(total_width)
			draw_string(
				draw_font, 
				Vector2(10, 50), 
				pos_text, 
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 
				font_size_adjusted * 0.7,
				Color.YELLOW
			)
