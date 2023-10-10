extends Node

# Repository for the enemy level graph; the Foe entity queries this node
# to obtain its next move

const ALTAR = Vector2(920, 400)	# "Other side" coords are reflected around the altar

const EXIT = Vector2(920, 1000)

const PEW_YS = [472, 509, 549]
const PEW_INNER_EDGE = 800
const PEW_OUTER_EDGE = 300
const OUTER_AISLE = 110


const DAIS_EDGE = Vector2(165, 400)
const BALCONY_FAR = Vector2(220, 230)
const BALCONY_NEAR = Vector2(590, 220)


# Queried by Foe entities; returns the coordinates of the next graph vertex,
# the means for getting there ("walk" or "jump") and the vertex thereby reached
func getNextTarget(var step, var side):
	var nextStep = 0
	var method = "walk"
	var coord = Vector2.ZERO
	if step == -2:
		# Die
		nextStep = -2
	elif step == -1:
		# Spawn in
		nextStep = randi() % 3
		coord = Vector2(rand_range(PEW_OUTER_EDGE, PEW_INNER_EDGE), PEW_YS[nextStep])
		pass
	elif step < 3:
		coord = Vector2(OUTER_AISLE, PEW_YS[step])
		nextStep = 3
	elif step == 3:
		coord = DAIS_EDGE
		nextStep = 4
	elif step == 4:
		# Decide whether to jump up to balcony or not
		if (randi() % 2 > 0):
			coord = BALCONY_FAR
			method = "jump"
			nextStep = 6
		else:
			coord = ALTAR
			nextStep = 5
	elif step == 5:
		# At altar, flee
		coord = EXIT
		nextStep = 8	
	elif step == 6:
		coord = BALCONY_NEAR
		nextStep = 7
	elif step == 7:
		coord = ALTAR
		method = "jump"
		nextStep = 5
	elif step == 8:
		nextStep = -1
	if side:
		coord.x = (2 * ALTAR.x) - coord.x	# If we're on the right side, reflect
	return [coord, method, nextStep]

func getFlightTarget(var pos):
	return Vector2((-10 if pos.x < ALTAR.x else 2000), pos.y)
