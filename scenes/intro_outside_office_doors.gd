extends Node2D

@onready var dialog_ui: DialogUI = %DialogUI

@export var dialog_reveal_speed := 50 # in characters per second

var dialog_lines: Array[String] = [
	"I slow down at the front door for a bit. There's a small bit of anxiety that I might be entering the wrong door, or that I'm too early, or a trillion other dumb things my brain could come up with.",
	"I wait a bit to see if someone else goes in first. But not for too long, otherwise I'll look shifty.",
	"I'll get out my phone, make it look like I'm waiting for an Uber or something.",
	"...",
	"I feel like such a dumbass.",
	"???: Oh! Hey, Ryder!",
	"My anxiety immediately melts away, and my spirits are lifted.",
	"I am warm. I have transcended.",
	"Ryder: Oh, hey Reina.",
	"I couldn't be happier to hear a familiar face and voice.",
	"The plain, casual smile I give doesn't at all match the unending waterfall of joy and relief I feel inside.",
	"I slip my phone into the pocket of my hoodie, and I walk inside with Reina.",
	"She's my twin sister. We applied to the same company, but for different positions.",
	"I'm going in for UI design, and she's going in for soundtracks.",
	"Reina’s loved music since we were kids. She's godly at the piano, and her singing voice is divine.",
	"Makes me wonder if I grew up with an angel.",
	"It hurt a little when she left home to live on her own, but I wouldn't be a good brother if I selfishly held her back.",
	"Plus, we live like five minutes apart anyways.",
	"She calls for the elevator, and the big sliding doors open up right away. Then she hits the button for the third floor.",
	"Thank fuck she remembered the floor, because I sure as hell didn't.",
	"We lean back against the elevator wall. My stomach falls as it rises.",
	"I take a sip from my can of iced vanilla coffee. Simultaneously, she sips from her can of macha green tea.",
	"Reina: So, nervous for your first day?",
	"I shrug.",
	"Ryder: Not really. Kinda just going along with the flow.",
	"Reina: As a coping mechanism?",
	"She leans in with the deadliest, most annoying smirk. I look away, trying not to frown too hard. Failing.",
	"Ryder: S-so what? Don't act like you aren't nervous too.",
	"Reina softens her advance and reels back.",
	"Reina: And I'm willing to admit it. Because, as a responsible adult, I'm able to acknowledge my feelings instead of stoically hiding them and pretending everything's always fine all the time.",
	"I'm going to punch her.",
	"Reina: You wouldn't have even come in here if I hadn't met up with you, would you?",
	"I'm going to fucking punch her.",
	"Reina: But that's fine.",
	"She sighs, the smugness in her expression fading, as well as my childish disgruntledness.",
	"Reina: Growing old doesn't mean we grow out of dumb human feelings, right? With new opportunities, new frontiers, new environments, being anxious and nervous is only natural. And it goes away pretty quickly.",
	"Reina confidently sticks her nose up, with one eye opened looking at me.",
	"Reina: If you can't ease the anxiety, just push through knowing it'll all become another boring routine to you in the end. That's when you can find the small little things that make it special.",
	"...I hate her.",
	"I hate her so goddamn fucking much.",
	"How she teases me into a corner, then comes up with an actually motivating motivational speech.",
	"Ryder: ...Yeah. I guess.",
	"I smile like a goddamn fucking idiot. She mirrors it, as if taking yet another victory between us.",
	"And somehow, I don't mind.",
	"Maybe later I'll treat her to some cookies from her favorite bakery down the street.",
	"The elevator slows. My stomach rises. It kept rising even after stopping.",
	"Reina ruffles my hair before leaving. I used to protest and smack her hand away, but now I just take it and grumble like the bitchy queer-ass little bottom that I am.",
]

var tasks: Array[SceneTask] = []
var current_task_index := -1

var current_task: SceneTask:
	get: return tasks[current_task_index]

func _ready() -> void:
	for line: String in dialog_lines:
		var line_with_speaker_regex := RegEx.create_from_string(r"([A-Za-z ?]+):\s*(.+)")
		var line_with_speaker_match := line_with_speaker_regex.search(line)
		
		if not line_with_speaker_match:
			tasks.append(DialogSceneTask.new(line, dialog_ui))
			continue
		
		var speaker := line_with_speaker_match.strings[1]
		var text := line_with_speaker_match.strings[2]
		var task := DialogSceneTask.new(text, dialog_ui)
		task.speaker_name = speaker
		tasks.append(task)
	
	_next_task()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		_next_task()

func _next_task() -> void:
	if current_task != null and not current_task.is_finished():
		current_task.interrupt()
		return
	
	if current_task_index >= tasks.size() - 1:
		return

	current_task_index += 1
	current_task.start()
