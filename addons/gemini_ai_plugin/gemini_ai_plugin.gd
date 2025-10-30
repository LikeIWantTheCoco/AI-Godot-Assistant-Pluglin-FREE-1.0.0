@tool
extends EditorPlugin

var gemini_dock: Control

func _enter_tree():
	gemini_dock = preload("res://addons/gemini_ai_plugin/gemini_ai_dock.tscn").instantiate()
	
	if gemini_dock.has_method("set_editor_interface"):
		gemini_dock.set_editor_interface(get_editor_interface())
	
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, gemini_dock)
	
	# Apply compact configuration AFTER adding to dock
	call_deferred("_apply_compact_layout")
	
	print("[Gemini AI] Plugin loaded as right side dock")

func _apply_compact_layout():
	print("Applying compact layout...")
	
	# Configure root control
	gemini_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gemini_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Configure ALL controls recursively
	_configure_node_recursive(gemini_dock)
	
	print("Compact layout applied")

func _configure_node_recursive(node: Node):
	if node is Control:
		var control = node as Control
		
		# UNIVERSAL configuration for all controls
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Specific configuration by node type
		if node is MarginContainer:
			control.add_theme_constant_override("margin_top", 2)
			control.add_theme_constant_override("margin_bottom", 2)
			control.add_theme_constant_override("margin_left", 2)
			control.add_theme_constant_override("margin_right", 2)
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
		elif node is VBoxContainer:
			control.add_theme_constant_override("separation", 2)
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
		elif node is HBoxContainer:
			control.add_theme_constant_override("separation", 2)
			control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
		elif node is TextEdit:
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			control.custom_minimum_size = Vector2(0, 80)
			
		elif node is Button:
			control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			control.custom_minimum_size = Vector2(0, 30)
			
		elif node is LineEdit:
			control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			control.custom_minimum_size = Vector2(0, 30)
			
		elif node is Label:
			control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			control.custom_minimum_size = Vector2(0, 20)
			control.autowrap_mode = TextServer.AUTOWRAP_WORD
			
		elif node is CheckBox:
			control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			control.custom_minimum_size = Vector2(0, 20)
			
		else:
			# For any other control, expand vertically by default
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Configure all children recursively
	for child in node.get_children():
		_configure_node_recursive(child)

func _exit_tree():
	if gemini_dock:
		remove_control_from_docks(gemini_dock)
		gemini_dock.queue_free()
		gemini_dock = null
	print("[Gemini AI] Plugin unloaded")

func _make_visible(visible: bool):
	if gemini_dock:
		gemini_dock.visible = visible

func _has_main_screen():
	return false

func _get_plugin_name():
	return "Gemini AI Assistant"

func _get_plugin_icon():
	return null
