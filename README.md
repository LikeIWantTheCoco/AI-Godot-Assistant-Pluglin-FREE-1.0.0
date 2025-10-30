# AI-Godot-Assistant-Pluglin-FREE-1.0.0
Plugin to generate and correct GDScript scripts using Gemini AI

A Godot 4.4 plugin that integrates Google Gemini AI to generate and correct GDScript code directly from the editor.

✨ Features
🚀 Code Generation
Smart Generation: Create GDScript scripts from natural language prompts

Native Integration: New scripts automatically open in the editor

Clean Output: Pure code responses without markdown or explanations

🔧 Error Correction
Manual Correction: Select specific scripts to fix syntax errors

Auto Correction: Automatic project scanning and real-time error fixing

Advanced Detection: Intelligent system that identifies real syntax issues

⚡ Advanced Features
Compact Interface: Optimized design that seamlessly integrates into the editor dock

Secure API Key: Local and secure storage of your API key (in "SavedAPIKey" file within the Plugin folder)

Continuous Scanning: Configurable timer for automatic project monitoring

🛠 Installation
Download the plugin:

Copy the gemini_ai_plugin folder to your project at res://addons/

Activate the plugin:

Go to Project → Project Settings → Plugins

Find "Gemini AI Assistant" and enable it

Configure API Key:

Open the Gemini AI dock (right side of the editor)

Enter your Google Gemini AI API Key

The key is automatically saved securely and locally in the "SavedAPIKey" file within the Plugin folder

🔑 Getting API Key
Go to Google AI Studio

Sign in with your Google account

Generate a new API Key (Free tier available with optional paid plans)

Copy and paste it into the dock

📖 Usage
Generate a New Script:
Open the Gemini AI dock

Write your prompt in the text area

Click "Generate"

Choose the location to save the new script

Correct a Specific Script Manually:
Click "Correct"

Select the .gd file you want to correct

The plugin will automatically analyze and fix the errors

Automatic Script Correction:
Check the "Auto Correction" box

The plugin will scan your project every 10 seconds

Scripts with syntax errors detected by Godot will be automatically corrected

🎯 Usage Examples
Script Generation
text
Prompt: "Create a player that moves with WASD and has gravity"

Result: Functional GDScript with movement and physics
Error Correction

# Script with errors:
func _ready()
    print("Hello world

# Corrected script:
func _ready():
    print("Hello world")
⚙️ Configuration
Auto Scan Timer
The time between automatic scans can be modified in the code:

Configuration Examples (Optional)
Auto Scan Timer Configuration

# In gemini_ai_dock.gd, line ~20
project_scan_timer.wait_time = 10.0  # Change to your preference
Configurable Scan Directories

# File: gemini_ai_dock.gd - Line ~120
var common_dirs = ["res://", "res://src", "res://scripts", "res://scenes", "res://nodes", "res://addons"]
# You can modify which folders the auto-correction can scan and correct
Configurable Delay Between Auto-Corrections

# File: gemini_ai_dock.gd - Line ~150
OS.delay_msec(2000) # You can modify the delay between automatic script corrections
🐛 Troubleshooting
Error: "API Key not configured"
Verify you've entered your Gemini API Key correctly

Ensure the key has permissions for Generative Language API

Error: "Connection error"
Check your internet connection

Verify the API Key is valid and not expired

Scripts don't reload automatically
The plugin forces reloading, but the current script tab might not update immediately

Simply reopen the script to see the updated version

The file is saved correctly - just refresh the view

🔒 Security

Your API Key is stored locally at res://addons/gemini_ai_plugin/SavedAPIKey
No information is sent to third-party servers, only to the official Google Gemini API
Generated code remains 100% local until you decide to save it

📝 Technical Notes
System Requirements
Godot 4.4 or higher

Internet connection to use the Gemini API

Valid Google Gemini AI API Key

Error Detection Features
The plugin detects:

Compilation errors
Unbalanced parentheses, braces, and brackets
Conditionals without colons
Functions without colons
Unbalanced quotes
Incorrect nested structures

# ⚠️ Important Considerations

## 🔧 About Auto-Correction
- Auto-correction only works on scripts with syntax errors detectable by Godot
- Automatically corrected scripts may require you to close and reopen the tab to visualize changes
- The system is designed to avoid unnecessary corrections in functional code

## ⚡ Performance and Usage
- Automatic scanning consumes resources; disable it if not needed
- In large projects, scanning may take several seconds
- Very extensive scripts (>1000 lines) may experience longer processing times
- The delay between corrections is configured to prevent system overload

## 🚫 Known Limitations
- Does not fix logic errors, only syntax errors
- Some complex errors may require manual intervention
- Code regeneration may alter the original format or style
- Not compatible with GDScript 1.0 or earlier versions of Godot

## 🛠️ In Case of Problems
- If a script doesn't appear updated: close and reopen it
- For failed corrections: use the specific manual correction option
- If auto-correction doesn't detect obvious errors: verify manually
- In case of unexpected behavior: temporarily disable auto-correction

## 🔒 Security and Privacy
- Your code is sent only to official Google Gemini AI servers
- The API Key is stored locally in your project
- Always review generated code before implementing it in production

## 💡 Usage Recommendations
- Use auto-correction mainly during development stages
- For critical code, prefer manual correction and detailed review
- Maintain important backups before massive corrections
- Experiment in test projects before implementing in production

## 🤖 AI Usage
- This plugin uses AI for script generation and correction
- Mandatory review: Always check and validate generated code before using it in production
- Limited context: The AI doesn't know your full project context, only what you provide in the prompt (An analysis function for the project's scripts will be attempted to be added to the plugin before a generation or correction)
- Security: Verify that generated code doesn't contain vulnerabilities or unsafe practices
- Performance: Evaluate if generated code meets your project's performance standards

  **The AI can make mistakes**

🤝 Contributions
Contributions are welcome! If you find any issues or have improvements:

Fork the project

Create a feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)

Open a Pull Request

📄 License
This project is under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments

Google Gemini AI for the powerful API
Godot community for the excellent game engine
Everyone using this plugin

Disclaimer: This plugin is not affiliated with Google LLC or the Godot Engine team. It's an open-source project maintained by the community.

I hope my plugin is useful and enjoyable for you. I will start releasing updates by implementing more functions, so it won’t just remain as 'Generate, specifically correct, and automatically correct.' I hope my plugin is of great help to you :)  
Unimportant note: This is my first project

GDMagic plugin for the community :)
