extends Node2D

signal pacify

const BARKS = [
	preload("res://Assets/Foe_sounds/0_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/1_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/2_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/3_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/4_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/5_Bark_01.wav"),
	preload("res://Assets/Foe_sounds/6_Bark_01.wav")
]

const DEATH_SCREAMS = [
	preload("res://Assets/Foe_sounds/0_Death_01.wav"),
	preload("res://Assets/Foe_sounds/1_Death_01.wav"),
	preload("res://Assets/Foe_sounds/2_Death_01.wav"),
	preload("res://Assets/Foe_sounds/3_Death_01.wav"),
	preload("res://Assets/Foe_sounds/4_Death_01.wav"),
	preload("res://Assets/Foe_sounds/5_Death_01.wav"),
	preload("res://Assets/Foe_sounds/6_Death_01.wav")
]

const HPS = [
	3,
	1,
	1,
	2,
	2,
	3,
	6
]

const WALK_SPEEDS = [
	130,
	400,
	200,
	190,
	180,
	100,
	50
]

const SAYING_CHANCES = [
	0.8,
	0.5,
	0.5,
	0.8,
	0.7,
	0.7,
	0.6
]

const SAYINGS = [
	[["*grumble*", "Harumph!", "Come now!", "Get on with it!"],["I Object!", "Harumph!", "*grumble*", "Be reasonable!", "See sense!"]],
	[["Are you getting married or not?", "Yaaaah!", "*yawn*"],["I Object!", "Yaaaaah!"]],
	[["Wed Already!", "I'm bored!", "Bleagh!"],["Can we go home?", "Waste of time!"]],
	[["We waste time!", "Get on with it!", "Hurry up!", "Must we force the issue?"],["You're no match for him!", "For shame!", "Disgraceful!", "This has gone far enough!"]],
	[["Get Married Already!", "OMG, what are you waiting for?", "Sweep him off his feet!"],["Don't do it!", "He's not worth it!", "Run girl run!"]],
	[["We don't have all year...", "*grumble*","I'll show you how it's done!"],["What a waste!", "You both look silly!", "*grumble*"]],
	[["*huff* *puff*", "*wheeze*","I was promised a wedding..."],["*huff* *puff*", "*wheeze*"]]
]


const MARRIAGE_BEGIN_DELAY = 1
const BRIDE_MARRY_POS = Vector2(864, 394)
const GROOM_MARRY_POS = Vector2(975, 394)
const BRIDE_DIVORCE_POS = Vector2(884, 394)
const GROOM_DIVORCE_POS = Vector2(956, 394)
const BRIDE_POST_DIVORCE_POS = Vector2(849, 394)
const GROOM_POST_DIVORCE_POS = Vector2(984, 394)

const POST_CEREMONY_ARMISTICE_DELAY = 0.3
const REMARRY_COOLDOWN = 5.0

const GROOM_BAR_HID_POS = Vector2(60, 800)
const GROOM_BAR_SHOW_POS = Vector2(60, 80)

# the state of the marriage.
# 0: Unmarried; Left side aggressive
# 1: Married; Right side aggressive
var marriageState = 0

# Whether or not enemies are spawning from the pews
var spawning = false

# Time until next enemy spawns; reduces as the game goes on
var spawnNextDelay = 1.8

# The fraction of the previous difficulty setting's delay that the new
# difficulty setting will perform
var waveDelayMultiplier = 0.9

# Time between difficulty increases
var timeBetweenWaves = 25.0

# HP
const PLAYER_HP_MAX = 6
var playerHP = PLAYER_HP_MAX
const GROOM_HP_MAX = 6
var groomHP = GROOM_HP_MAX
var groomRegenTime = 0.2 # Hearts per second
var groomHPHealStart = 0

# Score
var totalScore = 0


# Whether or not marriage state can be toggled (i.e. avatar is within altar range)
var marriageRange = false
var marriageLock = false

func moveCameraTo(var to: Vector2, var delay):
	$Camera/Mover.stop_all()
	$Camera/Mover.interpolate_property($Camera, "global_position", $Camera.global_position, to, delay, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Camera/Mover.start()
	pass


func toggleMarriageState():
	$HUD/PlayerHPBar.show() # Kludge from opening cinematic
	$ScoreBar.show()	# Likewise
	marriageLock = true
	$Groom/Gun.hide()
	$Difficulty_increase_timer.paused = true
	$Priest/Prompt.hide()
	spawning = false
	emit_signal("pacify", marriageState)
	$Player.frozen = true
	moveCameraTo(Vector2(916, 300), MARRIAGE_BEGIN_DELAY)
	$Priest/Tween.interpolate_property($Player, "global_position", $Player.global_position, BRIDE_MARRY_POS if (marriageState == 0) else BRIDE_DIVORCE_POS, MARRIAGE_BEGIN_DELAY, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Priest/Tween.interpolate_property($Groom, "global_position", $Groom.global_position, GROOM_MARRY_POS if (marriageState == 0) else GROOM_DIVORCE_POS, MARRIAGE_BEGIN_DELAY, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Priest/Tween.start()

func priestTweenCallback():
	$Player.hide()
	$Groom.hide()
	$Priest.frame = 1 if marriageState == 0 else 5
	$Priest/AnimationPlayer.play("Marriage" if marriageState == 0 else "Divorce")

func priestAnimationCallback():
	$Difficulty_increase_timer.paused = false
	$Camera/ScreenShake.shake(0.1, 10, 10)
	$ScoreBar.resetMultiplier()
	$Player.show()
	$Groom.show()
	$Player.frozen = false
	$Priest.frame = 0
	if marriageState == 1:
		marriageState = 0
		ScoreStorage.divorced += 1
		$Player.global_position = BRIDE_POST_DIVORCE_POS
		$Groom.global_position = GROOM_POST_DIVORCE_POS
		# Effect gameplay change: Strip Groom of gun, give to Bride
		$Player.get_node("Gun").frame = 1
		$Player.gun_doubled = true
		$Player/Gun.show()
		# Hide Groom's HP bar
		$HUD/GroomHPFlyIn.interpolate_property($HUD/GroomHPBar, "position", GROOM_BAR_SHOW_POS, GROOM_BAR_HID_POS, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN)
		$HUD/GroomHPFlyIn.start()
		groomHPHealStart = OS.get_unix_time()
		moveCameraTo(Vector2(540.0, 300.0), POST_CEREMONY_ARMISTICE_DELAY)
	else:
		marriageState = 1
		ScoreStorage.married += 1
		# Effect gameplay change: Strip Bride of gun, give to Groom
		$Player.get_node("Gun").frame = 0
		$Player.gun_doubled = false
		$Groom/Gun.show()
		$Player/Gun.show()
		# Show Groom's HP bar
		$HUD/GroomHPFlyIn.interpolate_property($HUD/GroomHPBar, "position", GROOM_BAR_HID_POS, GROOM_BAR_SHOW_POS, 0.8, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$HUD/GroomHPFlyIn.start()
		# Restore some portion of Groom's HP
		groomHP = min(GROOM_HP_MAX, groomHP + floor((OS.get_unix_time() - groomHPHealStart) * groomRegenTime))
		for i in range(groomHP):
			$HUD/GroomHPBar.get_child(i + 1).frame = 1 
		moveCameraTo(Vector2(1300.0, 300.0), POST_CEREMONY_ARMISTICE_DELAY)
	$Armistice_cndw.start(POST_CEREMONY_ARMISTICE_DELAY)

func armisticeCountdownCallback():
	spawning = true
	$Remarry_cndw.start(REMARRY_COOLDOWN)

func remarryCountdownCallback():
	marriageLock = false
	if marriageRange:
		$Priest/Prompt.frame = marriageState
		$Priest/Prompt.show()




func foe_has_reached_altar():
	$Groom/AnimationPlayer.stop()
	$Groom/AnimationPlayer.play("Hurt")
	$Groom/AudioStreamPlayer2D.play()
	reduce_HP()

func foe_has_died():
	ScoreStorage.finalScore += $ScoreBar.multiplier


# Reduces the appropriate HP bar(s) by 1 heart
func reduce_HP():
	if marriageState == 0 or groomHP == 0:
		$HUD/PlayerHPBar.get_child(playerHP).frame = 0
		playerHP -= 1
		if playerHP == 0:
			perish()
	else:
		$HUD/GroomHPBar.get_child(groomHP).frame = 0
		groomHP -= 1


func perish():
	get_tree().change_scene("res://GameOverScreen.tscn")


var temp = spawnNextDelay
onready var foeClass = preload("res://Foe.tscn")
onready var textSplashClass = preload("res://TextSplash.tscn")
func _process(delta):
	if spawning:
		temp -= delta
		if temp <= 0:
			var id = randi() % 7
			temp = spawnNextDelay
			var foe = foeClass.instance()
			foe.health = HPS[id]
			foe.side = marriageState
			connect("pacify", foe, "pacify")
			foe.connect("reached_altar", self, "foe_has_reached_altar")
			foe.connect("dead", self, "foe_has_died")
			foe.get_node("Sprite").frame = id * 2
			foe.get_node("BarkSFX").stream = BARKS[id]
			foe.get_node("DeathSFX").stream = DEATH_SCREAMS[id]
			foe.walkingSpeed = WALK_SPEEDS[id]
			$PewSet.add_child(foe)
			if(randf() < SAYING_CHANCES[id]):
				# NPC says something
				var textSplash = textSplashClass.instance()
				textSplash.set_text(SAYINGS[id][marriageState][randi() % SAYINGS[id][marriageState].size() - 1])
				textSplash.global_position = foe.global_position + Vector2(0, -10)
				add_child(textSplash)
	if Input.is_action_just_pressed("ui_accept"):
		if marriageRange and not marriageLock:
			toggleMarriageState()



func _on_Player_fire():
	$Camera/ScreenShake.shake(0.2, 20, 10)


func _on_MarriageField_body_entered(body):
	if body == $Player:
		marriageRange = true
		if not marriageLock:
			$Priest/Prompt.frame = marriageState
			$Priest/Prompt.show()



func _on_MarriageField_body_exited(body):
	if body == $Player:
		marriageRange = false
		$Priest/Prompt.hide()


func _on_Difficulty_increase_timer_timeout():
	# Increase difficulty
	$ScoreBar.augmentMultiplier()
	spawnNextDelay *= waveDelayMultiplier
	$Difficulty_increase_timer.start(timeBetweenWaves)


func setup_HP_bars():
	var playerHeartTexture = load("res://Assets/Heart_player.png")
	var groomHeartTexture = load("res://Assets/Heart_groom.png")
	for i in range(PLAYER_HP_MAX):
		var s = Sprite.new()
		s.texture = playerHeartTexture
		s.hframes = 2
		s.frame = 1
		s.scale = Vector2(2, 2)
		s.position = Vector2(50 + i * 28, 0)
		$HUD/PlayerHPBar.add_child(s)
	for i in range(GROOM_HP_MAX):
		var s = Sprite.new()
		s.texture = groomHeartTexture
		s.hframes = 2
		s.frame = 1
		s.scale = Vector2(2, 2)
		s.position = Vector2(50 + i * 28, 0)
		$HUD/GroomHPBar.add_child(s)


func _ready():
	ScoreStorage.married = 0
	ScoreStorage.divorced = 0
	ScoreStorage.finalScore = 0
	$Player.frozen = true
	randomize()
	setup_HP_bars()
	$Difficulty_increase_timer.start(timeBetweenWaves)
	$OpeningCinematic.play("Opening")

func openingCinematicCallback():
	$Priest/MarriageField/CollisionShape2D.disabled = false

func cinematicBlurbSplashHelper(var text, var side, var delay):
	var textSplash = textSplashClass.instance()
	textSplash.set_text(text)
	textSplash.reveal_delay = delay
	add_child(textSplash)
	textSplash.global_position = Vector2(rand_range(250, 700), rand_range(490, 520))
	if side:
		# Mirror around altar
		textSplash.global_position.x = 1840 - textSplash.global_position.x 

# Called with false for left, true for right
func openingCinematicMidBlurbs(var side):
	if side:
		# Arguments against wedding
		cinematicBlurbSplashHelper("I object!", side, 0.1)
		cinematicBlurbSplashHelper("Don't do it!", side, 0.5)
		cinematicBlurbSplashHelper("You're better that this!", side, 1.0)
		cinematicBlurbSplashHelper("You'll regret it!", side, 1.5)
	else:
		# Arguments for wedding
		cinematicBlurbSplashHelper("Marry Him!", side, 0.1)
		cinematicBlurbSplashHelper("Get on with it!", side, 0.5)
		cinematicBlurbSplashHelper("What are you waiting for?", side, 1.0)
		cinematicBlurbSplashHelper("Wed Already!", side, 1.5)
