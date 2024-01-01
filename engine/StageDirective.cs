using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Reflection;
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

		if (directive.name == "speed")
		{
			var speed = directive.GetRequiredArg(0)?.AsDouble();
			if (speed is null)
				return null;

			return new SpeedDirective(speed.Value);
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
			var args = ParseDirectiveArgs<EnterDirective.Args>(directive);
			if (args is null)
				return null;

			var (character, error) = stage.AddCharacter(args.CharacterName);
			if (character is null)
			{
				if (error is not null)
				{
					directive.PrintError(error);
				}
				return null;
			}

			return new EnterDirective(args, character);
		}

		// [move:<character>,to=<position>,(delay=<seconds>,duration=<seconds>))]
		// [move:<character>,by=<amount>,(delay=<seconds>,duration=<seconds>))]
		if (directive.name == "move")
		{
			var args = ParseDirectiveArgs<MoveDirective.Args>(directive);
			if (args is null)
			{
				return null;
			}

			if (args.ToPosition is null && args.ByPosition is null)
			{
				directive.PrintError("Missing required argument 'to' or 'by'");
				return null;
			}

			var character = stage.GetCharacter(args.CharacterName);
			if (character is null)
			{
				directive.PrintError(
					$"Character {args.CharacterName} not added to stage. Are you missing an 'enter' directive?"
				);
				return null;
			}

			return new MoveDirective(args, character);
		}

		if (directive.name == "leave")
		{
			var args = ParseDirectiveArgs<LeaveDirective.Args>(directive);
			if (args is null)
				return null;

			var character = stage.GetCharacter(args.CharacterName);
			if (character is null)
			{
				directive.PrintError(
					$"Character {args.CharacterName} not added to stage. Are you missing an 'enter' directive?"
				);
				return null;
			}

			return new LeaveDirective(args, character);
		}

		directive.PrintError("Unknown directive");
		return null;
	}

	internal abstract StageSnapshot UpdateSnapshot(StageSnapshot snapshot);
	internal abstract Action Run(Stage stage, Action complete);

	internal class DialogDirective : StageDirective
	{
		readonly string text;

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
			return snapshot with { DialogText = snapshot.DialogText + " " + text };
		}

		internal override Action Run(Stage stage, Action complete)
		{
			var tween = stage.Dialog.PlayText(text);
			tween.Finished += complete;
			return () => stage.Dialog.Skip();
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

		internal override Action Run(Stage stage, Action complete)
		{
			stage.Dialog.Speaker = speakerName;
			complete();
			return () => { };
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

		internal override Action Run(Stage stage, Action complete)
		{
			stage.ShowBackground(name);
			complete();
			return () => { };
		}
	}

	class WaitDirective : StageDirective
	{
		readonly double duration;

		public WaitDirective(double duration)
		{
			this.duration = duration;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot;
		}

		internal override Action Run(Stage stage, Action complete)
		{
			var timer = new Timer
			{
				WaitTime = duration,
				OneShot = true,
				Autostart = true,
			};
			timer.Timeout += complete;
			stage.AddChild(timer);
			return () => timer.QueueFree();
		}
	}

	class EnterDirective(EnterDirective.Args args, Character character) : StageDirective
	{
		public record Args
		{
			[PositionalArg(0)]
			public required string CharacterName { get; init; }

			[NamedArg("to")]
			public required double ToPosition { get; init; }

			[NamedArg("from")]
			public required double FromPosition { get; init; }

			[NamedArg("duration")]
			public required double? Duration { get; init; }
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with
			{
				Characters = snapshot.Characters.SetItem(
					args.CharacterName,
					(args.CharacterName, args.ToPosition)
				),
			};
		}

		internal override Action Run(Stage stage, Action complete)
		{
			character.StagePosition = args.ToPosition + args.FromPosition;
			character.MoveTo(args.ToPosition, args.Duration);
			character.FadeIn(args.Duration);
			complete();
			return () => { };
		}
	}

	class LeaveDirective(LeaveDirective.Args args, Character character) : StageDirective
	{
		public record Args
		{
			[PositionalArg(0)]
			public required string CharacterName { get; init; }

			[NamedArg("by")]
			public required double ByPosition { get; init; }

			[NamedArg("duration")]
			public required double? Duration { get; init; }
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot with
			{
				Characters = snapshot.Characters.Remove(character.CharacterName),
			};
		}

		internal override Action Run(Stage stage, Action complete)
		{
			character.MoveBy(args.ByPosition, args.Duration);
			character.FadeOut(args.Duration);
			complete();
			return () => { };
		}
	}

	class MoveDirective(MoveDirective.Args args, Character character) : StageDirective
	{
		public record Args
		{
			[PositionalArg(0)]
			public required string CharacterName { get; init; }

			[NamedArg("to")]
			public required double? ToPosition { get; init; }

			[NamedArg("by")]
			public required double? ByPosition { get; init; }

			[NamedArg("duration")]
			public required double? Duration { get; init; }
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			if (!snapshot.Characters.TryGetValue(args.CharacterName, out var character))
			{
				return snapshot;
			}

			double position;
			if (args.ToPosition is not null)
			{
				position = args.ToPosition.Value;
			}
			else if (args.ByPosition is not null)
			{
				position = character.position + args.ByPosition.Value;
			}
			else
			{
				position = character.position;
			}

			return snapshot with
			{
				Characters = snapshot.Characters.SetItem(
					args.CharacterName,
					(args.CharacterName, position)
				),
			};
		}

		internal override Action Run(Stage stage, Action complete)
		{
			if (args.ToPosition is not null)
			{
				character.MoveTo(args.ToPosition.Value, args.Duration);
			}
			else if (args.ByPosition is not null)
			{
				character.MoveBy(args.ByPosition.Value, args.Duration);
			}
			else
			{
				throw new Exception("Invalid move directive");
			}

			complete();
			return () => { };
		}
	}

	class SpeedDirective : StageDirective
	{
		private readonly double speed;

		public SpeedDirective(double speed)
		{
			this.speed = speed;
		}

		internal override StageSnapshot UpdateSnapshot(StageSnapshot snapshot)
		{
			return snapshot;
		}

		internal override Action Run(Stage stage, Action complete)
		{
			stage.Dialog.revealSpeedScale = speed;
			complete();
			return () => { };
		}
	}

	[AttributeUsage(AttributeTargets.Property)]
	class PositionalArgAttribute(int index) : Attribute
	{
		public int Index => index;
	}

	[AttributeUsage(AttributeTargets.Property)]
	class NamedArgAttribute(string name) : Attribute
	{
		public string Name => name;
	}

	static T? ParseDirectiveArgs<T>(TimelineFile.Directive directive)
		where T : class
	{
		var type = typeof(T);

		var positionalArgProperties = type.GetProperties()
			.Where(p => p.GetCustomAttribute<PositionalArgAttribute>() is not null)
			.OrderBy(p => p.GetCustomAttribute<PositionalArgAttribute>()!.Index)
			.ToArray();

		var namedArgProperties = type.GetProperties()
			.Where(p => p.GetCustomAttribute<NamedArgAttribute>() is not null)
			.ToDictionary(p => p.GetCustomAttribute<NamedArgAttribute>()!.Name, p => p);

		var result = Activator.CreateInstance(type);
		var failed = false;

		foreach (
			var index in Enumerable.Range(
				0,
				Mathf.Max(positionalArgProperties.Length, directive.PositionalArgs.Count)
			)
		)
		{
			var arg = directive.PositionalArgs.ElementAtOrDefault(index);

			if (arg is null)
			{
				directive.PrintError($"Missing required positional argument #{index + 1}");
				failed = true;
				continue;
			}

			if (index >= positionalArgProperties.Length)
			{
				directive.PrintError($"Extra argument \"{arg.Value}\"");
				continue;
			}

			var propertyType = positionalArgProperties[index].PropertyType;
			var propertyIsNullable = Nullable.GetUnderlyingType(propertyType) is not null;

			if (propertyType == typeof(double))
			{
				var argValue = arg.AsDouble();
				if (argValue is null && !propertyIsNullable)
				{
					directive.PrintError($"Argument {index} must be a number");
					failed = true;
					continue;
				}
				positionalArgProperties[index].SetValue(result, argValue);
			}
			else if (propertyType == typeof(string))
			{
				positionalArgProperties[index].SetValue(result, arg.Value);
			}
			else
			{
				directive.PrintError($"Argument {index} has unsupported type {propertyType}");
			}
		}

		foreach (
			var name in directive
				.NamedArgs.Keys.ToImmutableHashSet()
				.Union(namedArgProperties.Keys.AsEnumerable())
		)
		{
			var property = namedArgProperties.GetValueOrDefault(name);
			if (property is null)
			{
				directive.PrintError($"Unknown argument \"{name}\"");
				continue;
			}

			var propertyType =
				Nullable.GetUnderlyingType(property.PropertyType) ?? property.PropertyType;
			var propertyIsNullable = Nullable.GetUnderlyingType(property.PropertyType) is not null;

			var arg = directive.NamedArgs.GetValueOrDefault(name);
			if (arg is null && !propertyIsNullable)
			{
				directive.PrintError($"Missing required argument \"{name}\"");
				failed = true;
				continue;
			}

			if (propertyType == typeof(double))
			{
				var argValue = arg?.AsDouble();
				if (argValue is null && !propertyIsNullable)
				{
					directive.PrintError($"Argument \"{name}\" must be a number");
					failed = true;
					continue;
				}
				property.SetValue(result, argValue);
			}
			else if (propertyType == typeof(string) && arg is not null)
			{
				property.SetValue(result, arg.Value);
			}
			else
			{
				directive.PrintError($"Argument \"{name}\" has unsupported type {property}");
			}
		}

		return failed ? default : (T?)result;
	}
}
