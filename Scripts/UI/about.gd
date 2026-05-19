extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var about_text = $ScrollContainer/AboutText

const ABOUT_CONTENT = """[center][b]FaceRun Offline[/b]
Version 1.0.0

[i]Your face. Your enemies. Your offline adventure.[/i][/center]

[b]About[/b]
FaceRun Offline is a retro 2D platformer where you can assign real photos as faces to game characters. Everything runs offline — no internet, no login, no cloud.

[b]How to Play[/b]
• Run and jump through 5 unique worlds
• Collect gems and defeat enemies
• Assign your photos to Hero, Enemies, and Boss
• All data stays on your device

[b]Credits & Attribution[/b]

[b]Game Base:[/b]
2D Platformer Starter Kit by AdilDevStuff (Leon Oscar Kidando)
License: MIT
https://github.com/AdilDevStuff/2D-Platformer-Starter-Kit

[b]Android Plugin Template:[/b]
Godot Android Plugin Template by m4gr3d (Fredia Huya-Kouadio)
License: MIT
https://github.com/m4gr3d/Godot-Android-Plugin-Template

[b]Face Detection Reference:[/b]
ML Kit Samples by Google
License: Apache 2.0
https://github.com/googlesamples/mlkit

[b]2D Assets:[/b]
Kenney.nl — Asset packs
License: CC0 (Public Domain)
https://kenney.nl

[b]Sound Effects:[/b]
Generated with Gdfxr (Sfxr plugin for Godot)

[b]Engine:[/b]
Godot Engine 4.4
License: MIT
https://godotengine.org

[b]Face Detection:[/b]
Google ML Kit Face Detection (Bundled)
com.google.mlkit:face-detection:16.1.7

[b]Changes from Original Base:[/b]
• Renamed project to FaceRun Offline
• Changed package to com.aman.facerunoffline
• Added 5 original themed levels
• Added enemy types (Slime Bot, Flying Bug)
• Added boss system
• Added health/lives system
• Added checkpoint system
• Added touch controls for mobile
• Added face customization system
• Added ML Kit face detection via Android plugin
• Added main menu, level select, settings
• Added save/load system
• Added privacy and about screens
• Replaced all branding and UI identity
• Added mobile rendering mode
• Added pause system

[b]Package:[/b] com.aman.facerunoffline
[b]License:[/b] MIT (see LICENSE file)
"""

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if about_text:
		about_text.bbcode_enabled = true
		about_text.text = ABOUT_CONTENT

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
