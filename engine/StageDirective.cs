using Godot;

public abstract class StageDirective
{
	internal static StageDirective? FromSourceDirective(
		TimelineFile.Directive directive,
		Stage stage
	)
	{
		if (directive.name == "speaker")
		{
			return new SpeakerDirective(directive.value);
		}

		if (directive.name == "background")
		{
			var resourcePath = $"res://content/backgrounds/{directive.value}";
			if (!ResourceLoader.Exists(resourcePath))
			{
				directive.PrintError($"Resource path {resourcePath} does not exist");
				return null;
			}

			var resource = GD.Load(resourcePath);
			if (resource is not Texture2D texture)
			{
				directive.PrintError($"Resource path {resourcePath} is not a valid texture");
				return null;
			}

			stage.AddBackground(directive.value, texture);
			return new BackgroundDirective(directive.value);
		}

		if (directive.name == "wait")
		{
			var durationArg = directive.GetRequiredArg(0)?.AsDouble();
			if (durationArg is not double duration)
				return null;

			return new WaitDirective(duration);
		}

		if (directive.name == "enter")
		{
			var characterName = directive.GetRequiredArg(0)?.AsString();
			var toPosition = directive.GetRequiredArg("to")?.AsDouble();
			var fromPosition = directive.GetRequiredArg("from")?.AsDouble();
			var duration = directive.GetOptionalArg("duration")?.AsDouble();

			if (characterName is null || toPosition is null || fromPosition is null)
			{
				return null;
			}

			var scenePath = $"res://content/characters/{characterName}.tscn";
			if (!ResourceLoader.Exists(scenePath))
			{
				directive.PrintError($"Resource path {scenePath} does not exist");
				return null;
			}

			var node = GD.Load<PackedScene>(scenePath).Instantiate();
			if (node is not Character character)
			{
				directive.PrintError($"Resource path {scenePath} is not a valid character scene");
				return null;
			}

			stage.AddCharacter(character);
			return new EnterDirective(character, toPosition.Value, fromPosition.Value, duration);
		}

		if (directive.name == "leave")
		{
			var characterName = directive.GetRequiredArg(0)?.AsString();
			var byPosition = directive.GetRequiredArg("by")?.AsDouble();
			var duration = directive.GetOptionalArg("duration")?.AsDouble();

			var character = characterName is null ? null : stage.GetCharacter(characterName);

			if (character is null)
			{
				directive.PrintError(
					$"Character {characterName} not added to stage. Are you missing an 'enter' directive?"
				);
				return null;
			}

			if (byPosition is null)
				return null;

			return new LeaveDirective(character, byPosition.Value, duration);
		}

		directive.PrintError("Unknown directive");
		return null;
	}

	internal abstract StageSnapshot UpdateSnapshot(StageSnapshot snapshot);
	internal abstract void Reset();
	internal abstract void Process(Stage stage, double delta);
	internal abstract bool IsPlaying(Stage stage);
	internal abstract void Skip(Stage stage);

	internal class DialogDirective : StageDirective
	{
		readonly string text;
		bool started = false;

		public DialogDirective(string text)
		{
			this.text = SimpleMarkdownToBBCode(text);
		}

		static string SimpleMarkdownToBBCode(string text)
		{
			// translates markdown bold and italics to bbcode
			var boldItalicsRegex = RegEx.CreateFromString(@"(\*\*\*|___)([^\1]*)\1");
			var boldRegex = RegEx.CreateFromString(@"(\*\*|__)([^\1]*)\1");
			var italicsRegex = RegEx.CreateFromString(@"([*_])([^\1]*)\1");

			text = boldItalicsRegex.Sub(text, "[b][i]$1$2[/i][/b]", true);
			text = boldRegex.Sub(text, "[b]$1$2[/b]", true);
			text = italicsRegex.Sub(text, "[i]$2[/i]", true);

			return text;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with { DialogText = text };
		}

		internal override void Reset()
		{
			started = false;
		}

		internal override void Process(Stage stage, double delta)
		{
			if (!started)
			{
				stage.Dialog.Text += " " + text;
				started = true;
			}
		}

		internal override bool IsPlaying(Stage stage)
		{
			return stage.Dialog.IsPlaying();
		}

		internal override void Skip(Stage stage)
		{
			Process(stage, 0);
			stage.Dialog.Skip();
		}
	}

	class SpeakerDirective : StageDirective
	{
		readonly string speakerName;

		public SpeakerDirective(string speakerName)
		{
			this.speakerName = speakerName;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with { DialogSpeaker = speakerName };
		}

		internal override void Reset() { }

		internal override void Process(Stage stage, double delta)
		{
			stage.Dialog.Speaker = speakerName;
		}

		internal override bool IsPlaying(Stage stage)
		{
			return false;
		}

		internal override void Skip(Stage stage)
		{
			Process(stage, 0);
		}
	}

	class BackgroundDirective : StageDirective
	{
		readonly string name;

		public BackgroundDirective(string name)
		{
			this.name = name;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with { Background = name };
		}

		internal override void Reset() { }

		internal override void Process(Stage stage, double delta)
		{
			stage.ShowBackground(name);
		}

		internal override bool IsPlaying(Stage stage)
		{
			return false;
		}

		internal override void Skip(Stage stage)
		{
			Process(stage, 0);
		}
	}

	class WaitDirective : StageDirective
	{
		readonly double duration;
		double remaining;

		public WaitDirective(double duration)
		{
			this.duration = duration;
			remaining = duration;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot;
		}

		internal override void Reset()
		{
			remaining = duration;
		}

		internal override void Process(Stage stage, double delta)
		{
			remaining -= delta;
		}

		internal override void Skip(Stage stage)
		{
			remaining = 0;
		}

		internal override bool IsPlaying(Stage stage)
		{
			return remaining > 0;
		}
	}

	class EnterDirective : StageDirective
	{
		readonly Character character;
		readonly double initialPosition;
		readonly double targetPosition;
		readonly double? duration;

		public EnterDirective(
			Character character,
			double targetPosition,
			double initialOffset,
			double? duration
		)
		{
			this.character = character;
			this.initialPosition = targetPosition + initialOffset;
			this.targetPosition = targetPosition;
			this.duration = duration;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with
			{
				Characters = snapshot.Characters.SetItem(
					character.CharacterName,
					(character.CharacterName, targetPosition)
				),
			};
		}

		internal override void Reset()
		{
			character.FinishTweens();
			character.FadeOut(0);
		}

		internal override void Process(Stage stage, double delta)
		{
			character.StagePosition = initialPosition;
			character.MoveTo(targetPosition, duration);
			character.FadeIn(duration);
		}

		internal override bool IsPlaying(Stage stage)
		{
			return false;
		}

		internal override void Skip(Stage stage)
		{
			character.FinishTweens();
			character.FadeIn(0);
			character.StagePosition = targetPosition;
		}
	}

	class LeaveDirective : StageDirective
	{
		readonly Character character;
		readonly double byPosition;
		readonly double? duration;

		internal LeaveDirective(Character character, double byPosition, double? duration)
		{
			this.character = character;
			this.byPosition = byPosition;
			this.duration = duration;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with
			{
				Characters = snapshot.Characters.Remove(character.CharacterName),
			};
		}

		internal override void Reset()
		{
			character.FinishTweens();
			character.FadeIn(0);
		}

		internal override void Process(Stage stage, double delta)
		{
			character.MoveBy(byPosition, duration);
			character.FadeOut(duration);
		}

		internal override bool IsPlaying(Stage stage)
		{
			return false;
		}

		internal override void Skip(Stage stage)
		{
			character.FinishTweens();
			character.FadeOut(0);
		}
	}
}
