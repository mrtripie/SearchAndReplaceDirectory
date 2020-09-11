extends Control

onready var directory_line: LineEdit = find_node("DirectoryLine")
onready var recursive_button: Button = find_node("RecursiveButton")
onready var formats_line: LineEdit = find_node("FormatsLine")
onready var search_line: LineEdit = find_node("SearchLine")
onready var replace_line: LineEdit = find_node("ReplaceLine")
onready var replace_button: Button = find_node("ReplaceButton")
onready var undo_button: Button = find_node("UndoButton")
onready var file_dialog: FileDialog = find_node("FileDialog")

var files_to_search: Array
var file_text_dict: Dictionary #this keeps the original text, so that it can be undone
var formats: Array

func _ready():
	directory_line.text = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).replace("\\", "/")
	file_dialog.current_dir = directory_line.text


func _on_DirectoryLine_text_changed(new_text: String):
	var dir:= Directory.new()
	if dir.dir_exists(new_text):
		file_dialog.current_dir = new_text
		directory_line.add_color_override("font_color", Color.lightgray)
		replace_button.disabled = false
	else:
		directory_line.add_color_override("font_color", Color.red)
		replace_button.disabled = true


func _on_ReplaceButton_pressed():
	file_text_dict.clear()
	_update_formats()
	print(formats)
	files_to_search = _find_files_to_search(file_dialog.current_dir)
	_search_files_for_text()
	_replace_text_in_files()
	print(file_text_dict)


func _on_UndoButton_pressed():
	var file = File.new()
	for f in file_text_dict.keys():
		file.open(f, File.WRITE)
		file.store_string(file_text_dict[f])
		file.close()


func _on_FileDialog_dir_selected(path: String):
	directory_line.text = path
	replace_button.disabled = false
	directory_line.add_color_override("font_color", Color.lightgray)


func _find_files_to_search(path: String) -> Array:
	var files:= []
	var dir:= Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, false)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if recursive_button.pressed:
					files += _find_files_to_search(path + "/" + file_name)
			else:
				if _is_file_allowed_format(file_name):
					files.append(path + "/" + file_name)
			file_name = dir.get_next()
	return files


func _search_files_for_text():
	var file = File.new()
	for f in files_to_search:
		file.open(f, File.READ)
		var file_text = file.get_as_text()
		print(file_text)
		if file_text.count(search_line.text):
			print("has")
			file_text_dict[f] = file_text
		file.close()


func _replace_text_in_files():
	var file = File.new()
	for f in file_text_dict.keys():
		file.open(f, File.WRITE)
		file.store_string(file_text_dict[f].replace(search_line.text, replace_line.text))
		file.close()


func _update_formats():
	for f in formats_line.text.split(",", false):
		f = f.strip_edges() #removes edges of spaces/new liens
		if f.begins_with("."): #adds it and makes sure it starts with a .
			formats.append(f)
		else:
			formats.append("." + f)


func _is_file_allowed_format(file_name : String) -> bool:
	for f in formats:
		if file_name.ends_with(f):
			return true
	return false
