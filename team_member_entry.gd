extends ColorRect

var displayName : String
var viewerCount : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	set_PFP(displayName)
	%DisplayName.text = displayName
	if viewerCount > -1:
		%LiveLamp.visible = true
		%ViewCount.text = str(viewerCount)
		%ViewCount.visible = true


func set_PFP(username):
	%PFP.texture = await TwitchService.load_profile_image(await TwitchService.get_user(username))


func _on_mouse_entered():
	self.color.a = 0.2


func _on_mouse_exited():
	self.color.a = 0


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			OS.shell_open("https://www.twitch.tv/%s" % %DisplayName.text)
