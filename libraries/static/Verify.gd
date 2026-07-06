class_name Verify


## Asserts that an array's elements are all of a variant type [code]type[/code].
static func array_is_type(array: Variant, type: Variant.Type) -> bool:
	if typeof(array) != TYPE_ARRAY:
		return false
	for element: Variant in array:
		if typeof(element) != type:
			return false
	return true


## Asserts that an array's elements are all of the variant types in [code]types[/code].
static func array_is_types(array: Variant, types: Array[Variant.Type]) -> bool:
	if typeof(array) != TYPE_ARRAY:
		return false
	for element: Variant in array:
		if typeof(element) not in types:
			return false
	return true


## Asserts that a variant is an int or float.
static func is_numeric(val: Variant) -> bool:
	return typeof(val) in [TYPE_INT, TYPE_FLOAT]
	
	
## Assert that a roleplay name is okay to use.
static func validate_rp_name(name: String) -> bool: #might be used for more things later idk
	if not name.strip_edges(): #basic whitespace check; maybe use something stronger for weird unicode characters in the future
		return false
	if len(name) == 0:
		return false
	if len(name) > 64:
		return false
	#maybe also an offensive-filter check?
	return true