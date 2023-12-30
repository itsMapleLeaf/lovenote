using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

/// <summary>
/// Plays out a scripted timeline on the stage.
/// </summary>
public partial class Timeline
{
	readonly List<StageLine> lines = new();
	int currentLineIndex = 0;

	public static Timeline FromFile(string path)
	{
		return new Timeline(TimelineSourceFile.FromFile(path));
	}

	Timeline(TimelineSourceFile sourceFile)
	{
		foreach (var sourceLine in sourceFile.Lines())
		{
			var line = new StageLine();

			foreach (var (text, directive) in sourceLine.Parts())
			{
				if (text is not null)
				{
					line.AddDirective(new DialogDirective(text));
				}

				if (directive is not null)
				{
					switch (directive.Name)
					{
						case "speaker":
						{
							line.AddDirective(new SpeakerDirective(directive.Value));
							break;
						}

						case "background":
						{
							var resourcePath = $"res://content/backgrounds/{directive.Value}";
							if (!ResourceLoader.Exists(resourcePath))
							{
								directive.PrintError(
									$"Resource path {resourcePath} does not exist"
								);
								break;
							}

							var resource = GD.Load(resourcePath);
							if (resource is not Texture2D texture)
							{
								directive.PrintError(
									$"Resource path {resourcePath} is not a valid texture"
								);
								break;
							}

							line.AddDirective(new BackgroundDirective(texture));
							break;
						}

						case "wait":
						{
							var durationArg = directive.GetRequiredArg(0)?.AsDouble();
							if (durationArg is not double duration)
								break;

							line.AddDirective(new WaitDirective(duration));
							break;
						}

						case "enter":
						{
							var characterName = directive.GetRequiredArg(0)?.AsString();
							if (characterName is null)
								break;

							var toPosition = directive.GetRequiredArg("to")?.AsDouble();
							if (toPosition is null)
								break;

							var fromPosition = directive.GetRequiredArg("from")?.AsDouble();
							if (fromPosition is null)
								break;

							var duration = directive.GetRequiredArg("duration")?.AsDouble();
							if (duration is null)
								break;

							line.AddDirective(
								new EnterDirective(
									characterName,
									toPosition.Value,
									fromPosition.Value,
									duration.Value
								)
							);
							break;
						}

						case "leave":
						{
							var characterName = directive.GetRequiredArg(0)?.AsString();
							if (characterName is null)
								break;

							var byPosition = directive.GetRequiredArg("by")?.AsDouble();
							if (byPosition is null)
								break;

							var duration = directive.GetRequiredArg("duration")?.AsDouble();
							if (duration is null)
								break;

							line.AddDirective(
								new LeaveDirective(characterName, byPosition.Value, duration.Value)
							);

							break;
						}

						default:
						{
							directive.PrintError("Unknown directive");
							break;
						}
					}
				}
			}

			if (!line.IsEmpty())
			{
				lines.Add(line);
			}
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
		else if (currentLineIndex < lines.Count - 1)
		{
			currentLineIndex += 1;
			lines[currentLineIndex].Reset(stage);
		}
	}

	public bool IsReadyToAdvance(Stage stage)
	{
		return !lines[currentLineIndex].IsPlaying(stage);
	}

	private class StageLine
	{
		public List<IStageDirective> Directives = new();
		public int CurrentDirectiveIndex = 0;

		internal bool IsEmpty()
		{
			return !Directives.Any();
		}

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
			while (CurrentDirectiveIndex < Directives.Count)
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
			return CurrentDirectiveIndex < Directives.Count;
		}

		public void Skip(Stage stage)
		{
			while (CurrentDirectiveIndex < Directives.Count)
			{
				Directives[CurrentDirectiveIndex].Skip(stage);
				CurrentDirectiveIndex += 1;
			}
		}

		internal void AddDirective(IStageDirective directive)
		{
			Directives.Add(directive);
		}
	}

	private interface IStageDirective
	{
		public void Reset() { }

		public void Process(Stage stage, double delta) { }

		public bool IsPlaying(Stage stage)
		{
			return false;
		}

		public void Skip(Stage stage) { }
	}

	private class DialogDirective : IStageDirective
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

		public void Reset()
		{
			started = false;
		}

		public void Process(Stage stage, double delta)
		{
			if (!started)
			{
				stage.Dialog.Text += " " + text;
				started = true;
			}
		}

		public bool IsPlaying(Stage stage)
		{
			return stage.Dialog.IsPlaying();
		}

		public void Skip(Stage stage)
		{
			Process(stage, 0);
			stage.Dialog.Skip();
		}
	}

	private class SpeakerDirective : IStageDirective
	{
		private readonly string speakerName;

		public SpeakerDirective(string speakerName)
		{
			this.speakerName = speakerName;
		}

		public void Process(Stage stage, double delta)
		{
			stage.Dialog.Speaker = speakerName;
		}
	}

	private class BackgroundDirective : IStageDirective
	{
		private readonly Texture2D background;

		public BackgroundDirective(Texture2D background)
		{
			this.background = background;
		}

		public void Process(Stage stage, double delta)
		{
			if (background != null)
			{
				stage.SetBackground(background);
			}
		}

		public void Skip(Stage stage)
		{
			Process(stage, 0);
		}
	}

	private class WaitDirective : IStageDirective
	{
		private readonly double duration;
		private double remaining;

		public WaitDirective(double duration)
		{
			this.duration = duration;
			remaining = duration;
		}

		public void Reset()
		{
			remaining = duration;
		}

		public void Process(Stage stage, double delta)
		{
			remaining -= delta;
		}

		public void Skip(Stage stage)
		{
			remaining = 0;
		}

		public bool IsPlaying(Stage stage)
		{
			return remaining > 0;
		}
	}

	private class EnterDirective : IStageDirective
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

		public void Process(Stage stage, double delta)
		{
			stage.EnterCharacter(characterName, fromPosition, toPosition, duration);
		}

		public void Skip(Stage stage)
		{
			stage.EnterCharacter(characterName, fromPosition, toPosition, 0);
		}
	}

	private class LeaveDirective : IStageDirective
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

		public void Process(Stage stage, double delta)
		{
			stage.LeaveCharacter(characterName, byPosition, duration);
		}

		public void Skip(Stage stage)
		{
			stage.LeaveCharacter(characterName, byPosition, 0);
		}
	}
}
