extends Control

@onready var back_btn = $TopBar/BackBtn
@onready var privacy_text = $ScrollContainer/PrivacyText
@onready var delete_btn = $BottomBar/DeleteDataBtn

const PRIVACY_CONTENT = """[center][b]Privacy Policy[/b]
FaceRun Offline[/center]

[b]Your Privacy Matters[/b]

FaceRun Offline is designed to be fully offline. Your data never leaves your device.

[b]Photo & Face Data[/b]
• Only use photos you own or have permission to use.
• All face images stay on your device.
• This app detects face location only. It does not identify who the person is.
• Face detection runs entirely on-device using ML Kit bundled model.
• No photos or face data are uploaded to any server.
• No internet connection is required or used.

[b]What Data is Stored[/b]
• Cropped face images (PNG) — stored in app-private local storage
• Face-to-entity assignments — stored locally
• Voice/audio files — stored in app-private local storage
• Voice-to-entity assignments — stored locally
• Game progress (level, score) — stored locally
• Settings preferences — stored locally

[b]What Data is NOT Collected[/b]
• No personal information
• No location data
• No contacts
• No usage analytics
• No advertising identifiers
• No cloud backups

[b]Data Deletion[/b]
You can delete all face and voice data at any time:
• Go to Face Setup → Delete All Face Data
• Go to Voice & Audio Setup → Delete All Voice Data
• Or use the button below
• Uninstalling the app removes all local data

[b]Children's Privacy[/b]
This app does not collect any data from anyone, including children.

[b]Third Party Services[/b]
• Google ML Kit Face Detection (bundled, offline only)
  - Processes images on-device only
  - No data sent to Google servers
  - See: https://developers.google.com/ml-kit

[b]No Internet Required[/b]
This app works completely offline. It does not require, request, or use an internet connection.

[b]Contact[/b]
For questions about this privacy policy, please open an issue on the project repository.

[i]Last updated: 2025[/i]
"""

func _ready():
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if privacy_text:
		privacy_text.bbcode_enabled = true
		privacy_text.text = PRIVACY_CONTENT
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_data)

func _on_delete_data():
	var confirm = ConfirmationDialog.new()
	confirm.title = "Delete All Face & Voice Data"
	confirm.dialog_text = "This will permanently delete all face images\nand voice files stored on your device. Are you sure?"
	add_child(confirm)
	confirm.popup_centered()
	confirm.confirmed.connect(func():
		FaceManager.delete_all_faces()
		VoiceManager.delete_all_voices()
		confirm.queue_free()
		var info = AcceptDialog.new()
		info.title = "Done"
		info.dialog_text = "All face and voice data has been deleted."
		add_child(info)
		info.popup_centered()
		info.confirmed.connect(func(): info.queue_free())
	)
	confirm.canceled.connect(func(): confirm.queue_free())

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
