## The top level settings resource which all classes are expected to branch from.
@abstract
class_name SettingsResource
extends Resource

## The category of this resource.
@export var category: StringName = &"General"

## The label to be shown alongside this resource.
@export var label: String
