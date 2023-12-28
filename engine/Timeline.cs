using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class Timeline
{
	static readonly RegEx textAndDirectiveRegex = RegEx.CreateFromString(
		@"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
	);

	private readonly StageLine[] lines = Array.Empty<StageLine>();
	private int currentLineIndex = 0;

	public Timeline(string source)
	{
		if (source == string.Empty)
		{
			throw new Exception("Timeline source is empty");
		}

		var state = new StageState();

		foreach (var sourceLine in source.Split("\n", false))
		{
			var line = new StageLine();

			foreach (var match in textAndDirectiveRegex.SearchAll(sourceLine))
			{
				var text = match.GetString("text");
				if (text != "")
				{
					line.AddDirective(new DialogDirective(text));
				}

				var directiveName = match.GetString("directive_name");
				var directiveValue = match.GetString("directive_value");
				if (directiveName != "" && directiveValue != "")
				{
					var args = new DirectiveArgs(directiveName, directiveValue);
					switch (directiveName)
					{
						case "speaker":
						{
							line.AddDirective(new SpeakerDirective(directiveValue));
							break;
						}

						case "background":
						{
							line.AddDirective(new BackgroundDirective(directiveValue));
							state.Background = directiveValue;
							break;
						}

						case "wait":
						{
							var duration = args.GetRequiredArg(0).ToFloat();
							line.AddDirective(new WaitDirective(duration));
							break;
						}

						case "enter":
						{
							var characterName = args.GetRequiredArg(0);
							var toPosition = args.GetRequiredArg("to").ToFloat();
							var fromPosition = args.GetRequiredArg("from").ToFloat();
							var duration = args.GetRequiredArg("duration").ToFloat();
							line.AddDirective(
								new EnterDirective(
									characterName,
									toPosition,
									fromPosition,
									duration
								)
							);
							state.AddCharacter(new CharacterState(characterName, fromPosition));
							break;
						}

						case "leave":
						{
							var characterName = args.GetRequiredArg(0);
							var byPosition = args.GetRequiredArg("by").ToFloat();
							var duration = args.GetRequiredArg("duration").ToFloat();

							line.AddDirective(
								new LeaveDirective(characterName, byPosition, duration)
							);

							state.RemoveCharacter(characterName);
							break;
						}

						default:
						{
							GD.PushError($"Unknown directive: [{directiveName}:{directiveValue}]");
							break;
						}
					}
				}
			}

			line.EndState = state.CreateSnapshot();
			lines = lines.Append(line).ToArray();
		}
	}

	public void Process(Stage stage, double delta)
	{
		lines[currentLineIndex].Process(stage, delta);
	}

	public void Advance(Stage stage)
	{
		if (lines[currentLineIndex].IsPlaying(stage))
		{
			lines[currentLineIndex].Skip(stage);
		}
		else if (currentLineIndex < lines.Length - 1)
		{
			currentLineIndex += 1;
			lines[currentLineIndex].Reset(stage);
		}
	}

	public bool IsReadyToAdvance(Stage stage)
	{
		return !lines[currentLineIndex].IsPlaying(stage);
	}

	private class DirectiveArgs
	{
		private readonly string directiveName;
		private readonly string directiveValue;
		private string[] positionalArgs = Array.Empty<string>();
		private readonly Dictionary<string, string> namedArgs = new();

		public DirectiveArgs(string directiveName, string directiveValue)
		{
			this.directiveName = directiveName;
			this.directiveValue = directiveValue;

			var position = 0;
			foreach (var valuePart in directiveValue.Split(",", false))
			{
				var argParts = valuePart.Split("=");
				if (argParts.Length == 2)
				{
					var argName = argParts[0];
					var argValue = argParts[1];
					namedArgs[argName] = argValue;
				}
				else
				{
					positionalArgs = positionalArgs.Append(valuePart).ToArray();
					position += 1;
				}
			}
		}

		public string GetRequiredArg(string name)
		{
			if (!namedArgs.ContainsKey(name))
			{
				GD.PushError(
					$"Missing required argument \"{name}\" in directive [{directiveName}:{directiveValue}]"
				);
				return "";
			}
			return namedArgs[name];
		}

		public string GetRequiredArg(int position)
		{
			if (positionalArgs.Length <= position)
			{
				GD.PushError(
					$"Missing required argument at position {position} in directive [{directiveName}:{directiveValue}]"
				);
				return "";
			}
			return positionalArgs[position];
		}
	}

	private class StageState
	{
		public string Background = "";
		public CharacterState[] Characters = Array.Empty<CharacterState>();

		public StageState CreateSnapshot()
		{
			var snapshot = new StageState
			{
				Background = Background,
				Characters = new CharacterState[Characters.Length]
			};
			for (var i = 0; i < Characters.Length; i++)
			{
				snapshot.Characters[i] = Characters[i].CreateSnapshot();
			}
			return snapshot;
		}

		public void RemoveCharacter(string name)
		{
			Characters = Characters.Where(c => c.Name != name).ToArray();
		}

		internal void AddCharacter(CharacterState characterState)
		{
			Characters = Characters.Append(characterState).ToArray();
		}
	}

	private class CharacterState
	{
		public string Name;
		public double Position;

		public CharacterState(string name, double position)
		{
			Name = name;
			Position = position;
		}

		public CharacterState CreateSnapshot()
		{
			return new CharacterState(Name, Position);
		}
	}

	private class StageLine
	{
		public StageState EndState = new();
		public StageDirective[] Directives = Array.Empty<StageDirective>();
		public int CurrentDirectiveIndex = 0;

		public void Reset(Stage stage)
		{
			CurrentDirectiveIndex = 0;
			foreach (var directive in Directives)
			{
				directive.Reset();
			}
			stage.Dialog.Reset();
		}

		public void Process(Stage stage, double delta)
		{
			while (CurrentDirectiveIndex < Directives.Length)
			{
				var directive = Directives[CurrentDirectiveIndex];
				directive.Process(stage, delta);
				if (directive.IsPlaying(stage))
				{
					break;
				}
				else
				{
					CurrentDirectiveIndex += 1;
				}
			}
		}

		public bool IsPlaying(Stage stage)
		{
			return CurrentDirectiveIndex < Directives.Length;
		}

		public void Skip(Stage stage)
		{
			while (CurrentDirectiveIndex < Directives.Length)
			{
				Directives[CurrentDirectiveIndex].Skip(stage);
				CurrentDirectiveIndex += 1;
			}
		}

		internal void AddDirective(StageDirective directive)
		{
			Directives = Directives.Append(directive).ToArray();
		}
	}

	private abstract class StageDirective
	{
		public virtual void Reset() { }

		public virtual void Process(Stage stage, double delta) { }

		public virtual bool IsPlaying(Stage stage)
		{
			return false;
		}

		public virtual void Skip(Stage stage) { }
	}

	private class DialogDirective : StageDirective
	{
		private readonly string text;
		private bool started = false;

		public DialogDirective(string text)
		{
			this.text = SimpleMarkdownToBBCode(text);
		}

		private static string SimpleMarkdownToBBCode(string text)
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

		public override void Reset()
		{
			started = false;
		}

		public override void Process(Stage stage, double delta)
		{
			if (!started)
			{
				stage.Dialog.Text += " " + text;
				started = true;
			}
		}

		public override bool IsPlaying(Stage stage)
		{
			return stage.Dialog.IsPlaying();
		}

		public override void Skip(Stage stage)
		{
			Process(stage, 0);
			stage.Dialog.Skip();
		}
	}

	private class SpeakerDirective : StageDirective
	{
		private readonly string speakerName;

		public SpeakerDirective(string speakerName)
		{
			this.speakerName = speakerName;
		}

		public override void Process(Stage stage, double delta)
		{
			stage.Dialog.Speaker = speakerName;
		}
	}

	private class BackgroundDirective : StageDirective
	{
		private readonly Texture2D? background;

		public BackgroundDirective(string file)
		{
			var resource = GD.Load($"res://content/backgrounds/{file}");
			if (resource is not Texture2D texture)
			{
				GD.PushError("Background not found: " + file);
			}
			else
			{
				background = texture;
			}
		}

		public override void Process(Stage stage, double delta)
		{
			if (background != null)
			{
				stage.SetBackground(background);
			}
		}

		public override void Skip(Stage stage)
		{
			Process(stage, 0);
		}
	}

	private class WaitDirective : StageDirective
	{
		private readonly double duration;
		private double remaining;

		public WaitDirective(double duration)
		{
			this.duration = duration;
			remaining = duration;
		}

		public override void Reset()
		{
			remaining = duration;
		}

		public override void Process(Stage stage, double delta)
		{
			remaining -= delta;
		}

		public override void Skip(Stage stage)
		{
			remaining = 0;
		}

		public override bool IsPlaying(Stage stage)
		{
			return remaining > 0;
		}
	}

	private class EnterDirective : StageDirective
	{
		private readonly string characterName;
		private readonly double toPosition;
		private readonly double fromPosition;
		private readonly double duration;

		public EnterDirective(
			string characterName,
			double toPosition,
			double fromPosition,
			double duration
		)
		{
			this.characterName = characterName;
			this.toPosition = toPosition;
			this.fromPosition = fromPosition;
			this.duration = duration;
		}

		public override void Process(Stage stage, double delta)
		{
			stage.EnterCharacter(characterName, fromPosition, toPosition, duration);
		}

		public override void Skip(Stage stage)
		{
			stage.EnterCharacter(characterName, fromPosition, toPosition, 0);
		}
	}

	private class LeaveDirective : StageDirective
	{
		private readonly string characterName;
		private readonly double byPosition;
		private readonly double duration;

		public LeaveDirective(string characterName, double byPosition, double duration)
		{
			this.characterName = characterName;
			this.byPosition = byPosition;
			this.duration = duration;
		}

		public override void Process(Stage stage, double delta)
		{
			stage.LeaveCharacter(characterName, byPosition, duration);
		}

		public override void Skip(Stage stage)
		{
			stage.LeaveCharacter(characterName, byPosition, 0);
		}
	}
}
