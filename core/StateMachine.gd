## Avanza estados/transiciones de un objeto. Agnóstico del contenido: solo opera sobre StateDef.
class_name StateMachine
extends RefCounted

var states: Array[StateDef] = []
var index: int = 0

func configure(p_states: Array[StateDef], initial_id: String = "") -> void:
	states = p_states
	index = 0
	if initial_id != "":
		for i in states.size():
			if states[i].id == initial_id:
				index = i
				return

func current() -> StateDef:
	if states.is_empty():
		return null
	return states[index]

## Avanza al siguiente estado (por next_state si está definido; si no, cicla) y lo devuelve.
func advance() -> StateDef:
	if states.is_empty():
		return null
	var cur := states[index]
	if cur.next_state != "":
		for i in states.size():
			if states[i].id == cur.next_state:
				index = i
				return states[index]
	index = (index + 1) % states.size()
	return states[index]
