extends ColorRect

signal PopulateTeam

var thumbURL : String
var teamName : String
var teamDisp : String

# Called when the node enters the scene tree for the first time.
func _ready():
	set_thumb(thumbURL)
	%Name.text = teamDisp


func set_thumb(url):
	%Thumb.texture = await load_thumbnail(get_uri_path(url))


func get_uri_path(uri: String) -> String:
	return uri.replace(TwitchSetting.twitch_image_cdn_host, "")

func load_thumbnail(thumb: String) -> ImageTexture:
	if (ResourceLoader.has_cached(thumb)):
		return ResourceLoader.load(thumb)
	var client : BufferedHTTPClient = HttpClientManager.get_client(TwitchSetting.twitch_image_cdn_host)
	var request := client.request(thumb, HTTPClient.METHOD_GET, BufferedHTTPClient.HEADERS, "")
	var response_data := await client.wait_for_request(request)
	var texture : ImageTexture = ImageTexture.new()
	var response = response_data.response_data
	if !response.is_empty():
		var img := Image.new()
		var content_type = response_data.response_header["Content-Type"]

		match content_type:
			"image/png": img.load_png_from_buffer(response)
			"image/jpeg": img.load_jpg_from_buffer(response)
			_: return TwitchSetting.fallback_profile
		texture.set_image(img)
	else:
		texture.set_image(TwitchSetting.fallback_profile.get_image())
	texture.take_over_path(thumb)
	return texture


func _on_mouse_entered():
	self.color.a = 0.2


func _on_mouse_exited():
	self.color.a = 0


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			PopulateTeam.emit(teamName)
