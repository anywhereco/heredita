## Library for creating prompt windows.
extends Node

## The override UI.
##
## The override UI is used if you need to have the prompt attached to a specific node.
## If your scene does not have a top-level control, this must be set.
var override_ui: Node

## If the user is currently already in a prompt.
var in_prompt := false

## If a prompt was already closed in this frame.
var prompt_already_closed := false

## The prompts the user is in.
var prompts: Array[PromptInstance] = []

enum PromptCreationResult { SUCCESSFUL, NO_SUITABLE_UI, IN_PROMPT }

enum PromptActionResult { SUCCESSFUL, NOT_IN_PROMPT, INDEX_INVALID }


func _process(_delta: float) -> void:
	prompt_already_closed = false


## Returns a Result with the PanelContainer for the Prompt.
func new_fullscreen_prompt(force: bool = false, exclusive: bool = false) -> Result:
	if in_prompt and exclusive and not force:
		return Result.err(PromptCreationResult.IN_PROMPT)
	elif in_prompt and exclusive:
		for prompt in prompts:
			prompt.close()

	var prompt_inst := preload("res://libraries/ui/prompt/Prompt.tscn").instantiate()
	var ui: Node = TopLevel.get_ui()
	if override_ui != null:
		ui = override_ui

	if ui == null:
		return Result.err(PromptCreationResult.NO_SUITABLE_UI)

	ui.add_child(prompt_inst)
	var _prompt: PromptInstance = prompt_inst.get_child(0).get_child(0)
	_prompt.idx = prompts.size()
	_prompt.z_index = 32 * prompts.size()
	prompts.append(_prompt)
	_prompt.get_parent().get_parent().name = "prompt_%d" % _prompt.idx
	return Result.ok(_prompt)


## Hides the prompt and returns it in a Result.
func hide_prompt(idx: int) -> Result:
	if not in_prompt:
		return Result.err(PromptActionResult.NOT_IN_PROMPT)
	prompts[idx].hide_prompt()
	return Result.ok(prompts[idx])


## Shows the prompt and returns it in a Result.
func show_prompt(idx: int) -> Result:
	if not in_prompt:
		return Result.err(PromptActionResult.NOT_IN_PROMPT)
	prompts[idx].show_prompt()
	return Result.ok(prompts[idx])


## Closes the prompt.
func close_prompt(idx: int) -> PromptActionResult:
	if prompts.size() <= idx:
		return PromptActionResult.NOT_IN_PROMPT
	prompts[idx].close()
	_update_prompt_ids()
	return PromptActionResult.SUCCESSFUL


func close_top_prompt() -> PromptActionResult:
	if prompts.size() == 0:
		return PromptActionResult.NOT_IN_PROMPT
	close_prompt(prompts.size() - 1)
	return PromptActionResult.SUCCESSFUL


func _update_prompt_ids() -> void:
	var to_be_erased: Array[int] = []
	for idx in range(prompts.size()):
		if not is_instance_valid(prompts[idx]):
			to_be_erased.append(idx)
			continue
		prompts[idx].idx = idx
	for idx in to_be_erased:
		prompts.erase(idx)


## Will return null in the case of the node not being in a prompt.
func get_prompt_in(node: Node) -> PromptInstance:
	var parents: Array[Node] = []
	var current_node: Node = node.get_parent()

	while current_node != null and current_node != node.get_tree().get_root():
		parents.append(current_node)
		current_node = current_node.get_parent()

	for parent in parents:
		var script := parent.get_script() as Script
		if script == null:
			continue
		if script.get_global_name() == "PromptInstance":
			return parent
	return null
