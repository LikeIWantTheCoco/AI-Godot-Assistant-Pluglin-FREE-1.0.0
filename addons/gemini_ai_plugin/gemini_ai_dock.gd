@tool
extends Control

var _editor_interface = null
var auto_correction_enabled: bool = false
var project_scan_timer: Timer
var scripts_with_errors: Array = []
var currently_scanning: bool = false

@onready var prompt_text: TextEdit = $MarginContainer/VBoxContainer/PromptTextEdit
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var generate_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/GenerateButton
@onready var correct_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CorrectButton
@onready var api_key_edit: LineEdit = $MarginContainer/VBoxContainer/ApiKeyContainer/ApiKeyEdit
@onready var auto_correct_checkbox: CheckBox = $MarginContainer/VBoxContainer/AutoCorrectContainer/AutoCorrectCheckbox

func set_editor_interface(editor_iface):
	_editor_interface = editor_iface
	if is_inside_tree():
		_initialize_dock()

func _ready():
	# ONLY functional initialization - NO LAYOUT CONFIGURATION
	project_scan_timer = Timer.new()
	project_scan_timer.wait_time = 10.0
	project_scan_timer.timeout.connect(_scan_project_for_errors)
	add_child(project_scan_timer)
	
	if _editor_interface:
		_initialize_dock()
	else:
		set_status("Waiting for initialization...")

func _initialize_dock():
	if not _editor_interface:
		return
	
	load_settings()
	connect_signals()
	set_status("Ready to use")

func load_settings():
	# Load API Key from local file
	var api_key = load_api_key()
	if api_key_edit:
		api_key_edit.text = api_key
	
	if auto_correct_checkbox:
		auto_correct_checkbox.button_pressed = false  # Disabled by default
		auto_correction_enabled = false

func load_api_key() -> String:
	var file_path = "res://addons/gemini_ai_plugin/SavedAPIKey"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var api_key = file.get_as_text().strip_edges()
		file.close()
		return api_key
	return ""

func save_api_key(api_key: String):
	var file_path = "res://addons/gemini_ai_plugin/SavedAPIKey"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(api_key.strip_edges())
		file.close()
		print("[Gemini AI] API Key saved locally")

func connect_signals():
	if generate_button:
		generate_button.pressed.connect(_on_generate_pressed)
	if correct_button:
		correct_button.pressed.connect(_on_correct_pressed)
	if api_key_edit:
		api_key_edit.text_changed.connect(_on_api_key_changed)
	if auto_correct_checkbox:
		auto_correct_checkbox.toggled.connect(_on_auto_correct_toggled)

func _on_auto_correct_toggled(enabled: bool):
	auto_correction_enabled = enabled
	
	if enabled:
		set_status("Auto-correction ACTIVATED")
		project_scan_timer.start()
		scripts_with_errors.clear()
		_scan_project_for_errors()
	else:
		set_status("Auto-correction DEACTIVATED")
		project_scan_timer.stop()

func _scan_project_for_errors():
	if not auto_correction_enabled or not _editor_interface or currently_scanning:
		return
	
	currently_scanning = true
	var gd_scripts = _find_all_gdscripts_simple()
	call_deferred("_process_scripts_scan", gd_scripts)

func _find_all_gdscripts_simple() -> Array:
	var gd_scripts = []
	var common_dirs = ["res://", "res://src", "res://scripts", "res://scenes", "res://nodes", "res://addons"]
	
	for dir_path in common_dirs:
		if DirAccess.dir_exists_absolute(dir_path):
			var dir = DirAccess.open(dir_path)
			if dir:
				dir.list_dir_begin()
				var file_name = dir.get_next()
				while file_name != "":
					if not dir.current_is_dir() and file_name.ends_with(".gd"):
						var full_path = dir_path.path_join(file_name)
						gd_scripts.append(full_path)
					file_name = dir.get_next()
	
	return gd_scripts

func _process_scripts_scan(gd_scripts: Array):
	var scripts_with_errors_found = 0
	var gemini_handler = $GeminiHandler
	
	for script_path in gd_scripts:
		var script = load(script_path)
		if script and script is GDScript:
			var script_content = script.source_code
			var has_real_errors = false
			
			if gemini_handler and gemini_handler.has_method("has_syntax_errors"):
				has_real_errors = gemini_handler.has_syntax_errors(script_content)
			
			if has_real_errors:
				scripts_with_errors_found += 1
				if not scripts_with_errors.has(script_path):
					scripts_with_errors.append(script_path)
				
				if gemini_handler and gemini_handler.has_method("correct_syntax_errors_auto"):
					gemini_handler.correct_syntax_errors_auto(script, script_content)
					OS.delay_msec(2000)
			else:
				if scripts_with_errors.has(script_path):
					scripts_with_errors.erase(script_path)
	
	currently_scanning = false
	
	if scripts_with_errors_found == 0:
		set_status("Scan completed - No errors")
	else:
		set_status("Scan completed - " + str(scripts_with_errors_found) + " scripts corrected")

func remove_script_from_errors(script_path: String):
	if scripts_with_errors.has(script_path):
		scripts_with_errors.erase(script_path)

func _on_generate_pressed():
	if not _validate_editor_interface() or not _validate_inputs():
		return
	
	set_status("Generating script...")
	set_buttons_enabled(false)
	
	var current_script = get_current_script()
	var gemini_handler = $GeminiHandler
	
	if gemini_handler:
		gemini_handler.set_api_key(api_key_edit.text.strip_edges())  # Pass API key to handler
		gemini_handler.generate_gdscript(prompt_text.text.strip_edges(), current_script)
	else:
		set_status("Error: Gemini module not available")
		set_buttons_enabled(true)

func _on_correct_pressed():
	if not _validate_editor_interface() or not _validate_api_key():
		return
	
	set_status("Selecting script to correct...")
	set_buttons_enabled(false)
	select_script_to_correct()

func select_script_to_correct():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.gd", "GDScript Files")
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	
	var base_control = get_tree().root
	base_control.add_child(file_dialog)
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.popup_centered(Vector2i(700, 500))

func _on_file_selected(path: String):
	var script = load(path)
	if script and script is GDScript:
		set_status("Correcting script...")
		var gemini_handler = $GeminiHandler
		if gemini_handler:
			gemini_handler.set_api_key(api_key_edit.text.strip_edges())  # Pass API key to handler
			gemini_handler.correct_syntax_errors(script)
		else:
			set_status("Error: Gemini module not available")
			set_buttons_enabled(true)
	else:
		set_status("Error: Invalid file")
		set_buttons_enabled(true)

func _validate_editor_interface() -> bool:
	if not _editor_interface:
		set_status("Error: Editor interface not available")
		return false
	return true

func _validate_inputs() -> bool:
	if prompt_text.text.strip_edges().is_empty():
		set_status("Error: Write a prompt first")
		return false
	return _validate_api_key()

func _validate_api_key() -> bool:
	if api_key_edit.text.strip_edges().is_empty():
		set_status("Error: Enter Gemini API Key")
		return false
	return true

func get_current_script():
	if _editor_interface:
		return _editor_interface.get_script_editor().get_current_script()
	return null

func _on_api_key_changed(new_text: String):
	# Save API Key to local file when changed
	save_api_key(new_text)

func set_status(message: String):
	if status_label:
		status_label.text = message

func set_buttons_enabled(enabled: bool):
	if generate_button:
		generate_button.disabled = !enabled
	if correct_button:
		correct_button.disabled = !enabled

func create_new_script_file(code: String):
	if not _validate_editor_interface():
		return
		
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.gd", "GDScript Files")
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	
	var base_control = get_tree().root
	base_control.add_child(file_dialog)
	file_dialog.file_selected.connect(_on_save_file_selected.bind(code))
	file_dialog.popup_centered(Vector2i(600, 400))

func _on_save_file_selected(path: String, code: String):
	var new_script = GDScript.new()
	new_script.source_code = code
	
	if ResourceSaver.save(new_script, path) == OK:
		set_status("Script saved: " + path)
		if _editor_interface:
			_editor_interface.edit_resource(new_script)
	else:
		set_status("Error saving script")

func get_editor_interface():
	return _editor_interface
