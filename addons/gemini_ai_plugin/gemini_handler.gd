@tool
extends Node

# Use Gemini 2.0 Flash
const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"

var http_request: HTTPRequest
var api_key: String = ""  # No default key
var current_request_meta = {}

func _ready():
	# Verify we are in tool mode
	if not Engine.is_editor_hint():
		return
		
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("[Gemini AI] Handler ready in tool mode")

# Function to set API key from dock
func set_api_key(key: String):
	api_key = key.strip_edges()

# PUBLIC FUNCTION for dock to check errors
func has_syntax_errors(script_content: String) -> bool:
	return _has_real_syntax_errors(script_content)

func generate_gdscript(prompt: String, current_script: Script = null):
	if not Engine.is_editor_hint():
		return
		
	var full_prompt = "You are an expert in Godot 4.4 and GDScript. Generate ONLY the GDScript code without explanations, without markdown, without ```gdscript or ```. Prompt: " + prompt
	
	var request_body = {
		"contents": [{
			"parts": [{
				"text": full_prompt
			}]
		}],
		"generationConfig": {
			"temperature": 0.7,
			"topK": 40,
			"topP": 0.95,
			"maxOutputTokens": 2048
		}
	}
	
	# ALWAYS pass null as current_script to force new file creation
	_make_gemini_request(request_body, "generate", null)
	
func correct_syntax_errors(current_script: Script):
	if not Engine.is_editor_hint():
		return
		
	if not current_script or not current_script is GDScript:
		get_parent().set_status("Error: Invalid script for correction")
		get_parent().set_buttons_enabled(true)
		return
	
	var script_content = current_script.source_code
	
	# Verify if it really has errors using improved method
	if not _has_real_syntax_errors(script_content):
		get_parent().set_status("Script has no detectable syntax errors")
		get_parent().set_buttons_enabled(true)
		return
	
	var prompt = "Correct the syntax errors in this GDScript for Godot 4.4. Review ALL the code and fix any errors you find. Respond ONLY with the corrected code without explanations:\n\n" + script_content
	
	var request_body = {
		"contents": [{
			"parts": [{
				"text": prompt
			}]
		}],
		"generationConfig": {
			"temperature": 0.3,
			"topK": 20,
			"topP": 0.9,
			"maxOutputTokens": 2048
		}
	}
	
	_make_gemini_request(request_body, "correct", current_script)

func correct_syntax_errors_auto(current_script: Script, script_content: String):
	if not Engine.is_editor_hint():
		return
		
	if not current_script or not current_script is GDScript:
		get_parent().set_status("Error: Invalid script for auto-correction")
		return
	
	# Verify if it really has errors using improved method
	if not _has_real_syntax_errors(script_content):
		print("[Gemini AI] Script has no detectable errors: ", current_script.resource_path)
		return
	
	print("[Gemini AI] ERROR detected in script: ", current_script.resource_path)
	
	var prompt = "AUTOMATIC CORRECTION: This Godot 4.4 GDScript script has detected syntax errors. Analyze and fix ALL errors. Respond ONLY with the complete corrected GDScript code without explanations:\n\n" + script_content
	
	var request_body = {
		"contents": [{
			"parts": [{
				"text": prompt
			}]
		}],
		"generationConfig": {
			"temperature": 0.2,
			"topK": 15,
			"topP": 0.8,
			"maxOutputTokens": 2048
		}
	}
	
	_make_gemini_request(request_body, "correct_auto", current_script)

func _has_real_syntax_errors(script_content: String) -> bool:
	# IMPROVED method to detect real errors
	
	# 1. Verify if script can be compiled
	var test_script = GDScript.new()
	test_script.source_code = script_content
	
	# Try to compile script - this is the most reliable way
	var result = test_script.reload()
	if result != OK:
		print("[Gemini AI] Compilation error detected")
		return true
	
	# 2. Additional common syntax checks
	var lines = script_content.split("\n")
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# Check unbalanced parentheses
		if line.count("(") != line.count(")"):
			print("[Gemini AI] Unbalanced parentheses line ", i + 1)
			return true
		
		# Check unbalanced braces
		if line.count("{") != line.count("}"):
			print("[Gemini AI] Unbalanced braces line ", i + 1)
			return true
		
		# Check unbalanced brackets
		if line.count("[") != line.count("]"):
			print("[Gemini AI] Unbalanced brackets line ", i + 1)
			return true
		
		# Check if/for/while without colon
		if (line.begins_with("if ") or line.begins_with("for ") or line.begins_with("while ") or line.begins_with("elif ")) and not line.ends_with(":"):
			print("[Gemini AI] Conditional without ':' line ", i + 1)
			return true
		
		# Check func without colon
		if line.begins_with("func ") and not line.ends_with(":"):
			print("[Gemini AI] Function without ':' line ", i + 1)
			return true
		
		# Check unbalanced single quotes
		if line.count("'") % 2 != 0:
			print("[Gemini AI] Unbalanced single quotes line ", i + 1)
			return true
		
		# Check unbalanced double quotes
		if line.count('"') % 2 != 0:
			# But check if it's a valid multiline string
			if not line.begins_with('"""') and not (line.count('"') == 3 and line.ends_with('"""')):
				print("[Gemini AI] Unbalanced double quotes line ", i + 1)
				return true
	
	# 3. Check common structure errors
	var brace_stack = []
	var paren_stack = []
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		
		# Check nested braces
		for char in line:
			if char == "{":
				brace_stack.append(i)
			elif char == "}":
				if brace_stack.is_empty():
					print("[Gemini AI] Closing brace without opening line ", i + 1)
					return true
				brace_stack.pop_back()
		
		# Check nested parentheses
		for char in line:
			if char == "(":
				paren_stack.append(i)
			elif char == ")":
				if paren_stack.is_empty():
					print("[Gemini AI] Closing parenthesis without opening line ", i + 1)
					return true
				paren_stack.pop_back()
	
	# Check non-empty stacks at the end
	if not brace_stack.is_empty():
		print("[Gemini AI] Unclosed braces")
		return true
	if not paren_stack.is_empty():
		print("[Gemini AI] Unclosed parentheses")
		return true
	
	return false

func _make_gemini_request(body: Dictionary, request_type: String, current_script: Script):
	if not Engine.is_editor_hint():
		return
		
	if api_key.is_empty():
		get_parent().set_status("Error: API Key not configured")
		get_parent().set_buttons_enabled(true)
		return
	
	var url = GEMINI_API_URL + "?key=" + api_key
	var json_body = JSON.stringify(body)
	
	var headers = ["Content-Type: application/json"]
	
	# Save metadata in class variable
	current_request_meta = {
		"request_type": request_type,
		"current_script": current_script
	}
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		get_parent().set_status("Connection error: " + str(error))
		get_parent().set_buttons_enabled(true)
		return

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if not Engine.is_editor_hint():
		return
		
	get_parent().set_buttons_enabled(true)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		get_parent().set_status("Connection error: " + str(result))
		return
	
	if response_code != 200:
		get_parent().set_status("HTTP Error " + str(response_code) + ": Verify your API Key")
		print("Response body: ", body.get_string_from_utf8())
		return
	
	var response_body = body.get_string_from_utf8()
	var json_response = JSON.parse_string(response_body)
	
	if not json_response:
		get_parent().set_status("Error: Invalid JSON response")
		return
	
	if not "candidates" in json_response or json_response["candidates"].is_empty():
		get_parent().set_status("Error: No content generated")
		if "error" in json_response:
			get_parent().set_status("API Error: " + str(json_response["error"]["message"]))
		return
	
	var candidate = json_response["candidates"][0]
	if not "content" in candidate or candidate["content"]["parts"].is_empty():
		get_parent().set_status("Error: Empty content in response")
		return
	
	var generated_text = candidate["content"]["parts"][0]["text"]
	generated_text = generated_text.replace("```gdscript", "").replace("```", "").strip_edges()
	
	# Use metadata from class variable
	var request_type = current_request_meta.get("request_type", "")
	var current_script = current_request_meta.get("current_script", null)
	
	_handle_generated_code(generated_text, request_type, current_script)

func _handle_generated_code(code: String, request_type: String, current_script: Script):
	if not Engine.is_editor_hint():
		return
		
	# Normalize indentation to tabs for consistency
	var normalized_code = _normalize_indentation(code)
		
	match request_type:
		"generate":
			# ALWAYS create new file, ignore current_script
			get_parent().create_new_script_file(normalized_code)
		
		"correct", "correct_auto":
			if current_script and current_script is GDScript:
				current_script.source_code = normalized_code
				if ResourceSaver.save(current_script, current_script.resource_path) == OK:
					if request_type == "correct_auto":
						get_parent().set_status("Script auto-corrected successfully!")
						# IMPORTANT: Remove from scripts with errors list
						_remove_script_from_errors_list(current_script.resource_path)
					else:
						get_parent().set_status("Script corrected successfully!")
					
					# Force script reload
					_force_script_reload(current_script)
				else:
					get_parent().set_status("Error: Could not save script")
			else:
				get_parent().set_status("Error: Could not correct script")
				
# Add this function to clean error list
func _remove_script_from_errors_list(script_path: String):
	if get_parent() and get_parent().has_method("remove_script_from_errors"):
		get_parent().remove_script_from_errors(script_path)
		
func _normalize_indentation(code: String) -> String:
	# Convert indentation spaces to tabs
	var lines = code.split("\n")
	var normalized_lines = []
	
	for line in lines:
		var original_line = line
		# Count initial spaces
		var space_count = 0
		while space_count < line.length() and line[space_count] == ' ':
			space_count += 1
		
		if space_count > 0:
			# Convert spaces to tabs (4 spaces = 1 tab)
			var tab_count = space_count / 4
			var new_indentation = "\t".repeat(tab_count)
			line = new_indentation + line.substr(space_count)
		
		normalized_lines.append(line)
	
	return "\n".join(normalized_lines)

func _force_script_reload(script: Script):
	if not Engine.is_editor_hint():
		return
		
	var editor_interface = get_parent().get_editor_interface()
	if not editor_interface:
		return
	
	var script_path = script.resource_path
	
	# Method 1: Manually save file to force external change detection
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(script.source_code)
		file.close()
	
	# Method 2: Multiple rescans with delays
	call_deferred("_step1_reload", script_path, editor_interface)

func _step1_reload(script_path: String, editor_interface: EditorInterface):
	var filesystem = editor_interface.get_resource_filesystem()
	filesystem.scan()
	call_deferred("_step2_reload", script_path, editor_interface)

func _step2_reload(script_path: String, editor_interface: EditorInterface):
	var filesystem = editor_interface.get_resource_filesystem()
	filesystem.update_file(script_path)
	
	# Method 3: Try to reload script in editor
	var script = load(script_path)
	if script:
		editor_interface.edit_resource(script)
	
	print("[Gemini AI] Script forcefully reloaded: ", script_path.get_file())
