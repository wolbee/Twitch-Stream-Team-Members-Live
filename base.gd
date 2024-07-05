extends Control

@export var teamEntry: PackedScene
@export var memberEntry: PackedScene

var broadcaster

# Called when the node enters the scene tree for the first time.
func _ready():
	TwitchService.auth.initialized.connect(_handle_init)
	await TwitchService.setup()
	print("Connected to Twitch")
	populate_teams()


func _handle_init():
	TwitchService.auth.auth.device_code_requested.connect(_handle_code)


func _handle_code(device_code : OAuth.OAuthDeviceCodeResponse):
	OS.shell_open(device_code.verification_uri)


func populate_teams():
	for child in %TeamList.get_children():
		child.queue_free()
	broadcaster = await TwitchService.api.get_users([],[])
	var teams = await TwitchService.api.get_channel_teams(str(broadcaster.data[0].id))
	for team in teams.data.map(func(team): return {"name": team.team_name, "disp": team.team_display_name, "url": team.thumbnail_url}):
		var entry = teamEntry.instantiate()
		entry.teamName = team.name
		entry.teamDisp = team.disp
		entry.thumbURL = team.url
		entry.PopulateTeam.connect(populate_team_members)
		%TeamList.add_child(entry)


func _on_team_name_search_button_pressed():
	var team = %TeamNameEntry.text
	if team:
		populate_team_members(team)


func populate_team_members(team : String):
	for child in %Outcome.get_children():
		child.queue_free()
	var response = await TwitchService.api.get_teams(team.replace(" ",""), "")
	if response.data.size() == 0:
		return
	var users = Array(response.data[0].users.map(func(user): return user.user_name), TYPE_STRING, &"", null)
	users.erase(broadcaster.data[0].display_name)
	var liveCheck = await TwitchService.api.get_streams([],users,[],"live",[],100,"","")
	
	# sort liveCheck by viewer count
	var liveUsers = liveCheck.data.map(func(user): return user.user_name)
	# filter out users in liveCheck, and sort by name
	var others = users.filter(func(user): return !liveUsers.has(user))
	others.sort_custom(func(a, b): return a.to_lower() < b.to_lower())
	if others.has("Falinere"):
		others.erase("Falinere")
		others.push_front("Falinere")
	
	# iterate through liveUsers
	for user in liveUsers:
		var entry = memberEntry.instantiate()
		entry.displayName = user
		entry.viewerCount = liveCheck.data.filter(func(user): return user.user_name == entry.displayName)[0].viewer_count
		%Outcome.add_child(entry)
		
	# iterate through users
	for user in others:
		var entry = memberEntry.instantiate()
		entry.displayName = user
		%Outcome.add_child(entry)


func _on_team_name_entry_text_changed(_text):
	if %TeamNameEntry.text.length() == 0:
		%TeamNameSearchButton.disabled = true
		%TeamNameSearchButton.mouse_default_cursor_shape = CURSOR_FORBIDDEN
	else:
		%TeamNameSearchButton.disabled = false
		%TeamNameSearchButton.mouse_default_cursor_shape = CURSOR_POINTING_HAND


# TO DO
# More info on live channels:
# - time live
# - category
# - title
