# This script is an autoload, that can be accessed from any other script!

extends Node

@onready var jump_sfx = $JumpSfx
@onready var coin_pickup_sfx = $CoinPickup
@onready var death_sfx = $DeathSfx
@onready var respawn_sfx = $RespawnSfx
@onready var level_complete_sfx = $LevelCompleteSfx

func play_hero_jump():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.HERO_JUMP):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.HERO_JUMP)
	else:
		jump_sfx.play()

func play_hero_damage():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.HERO_DAMAGE):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.HERO_DAMAGE)
	else:
		death_sfx.play()

func play_hero_death():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.HERO_DEATH):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.HERO_DEATH)
	else:
		death_sfx.play()

func play_enemy_hit():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.ENEMY_HIT):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.ENEMY_HIT)

func play_enemy_death():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.ENEMY_DEATH):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.ENEMY_DEATH)

func play_boss_roar():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.BOSS_ROAR):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.BOSS_ROAR)

func play_boss_death():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.BOSS_DEATH):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.BOSS_DEATH)

func play_level_complete():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.LEVEL_COMPLETE):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.LEVEL_COMPLETE)
	else:
		level_complete_sfx.play()

func play_game_over():
	if VoiceManager.has_voice(VoiceManager.VoiceCategory.GAME_OVER):
		VoiceManager.play_voice(VoiceManager.VoiceCategory.GAME_OVER)

func play_coin_pickup():
	coin_pickup_sfx.play()
