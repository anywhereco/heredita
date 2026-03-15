class_name ThreadingManager
extends Resource


func add_task(task: Callable, priority: bool = false, description: String = "") -> int:
	return WorkerThreadPool.add_task(task, priority, description)


func is_complete(task: int) -> bool:
	return WorkerThreadPool.is_task_completed(task)


func wait_until_complete(task: int) -> void:
	@warning_ignore("redundant_await")
	await WorkerThreadPool.wait_for_task_completion(task)
