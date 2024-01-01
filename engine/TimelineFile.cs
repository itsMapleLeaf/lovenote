using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public class TimelineFile(string path)
{
	readonly string path = path;
	readonly string content = FileAccess.GetFileAsString(path);

	IEnumerable<Line> Lines()
	{
		var number = 1;
		foreach (var content in content.Split("\n"))
		{
			yield return new Line(this, content, number);
			number += 1;
		}
	}

	public static IEnumerable<Line> Lines(string path)
	{
		return new TimelineFile(path).Lines();
	}

	void PrintError(string message)
	{
		PrintError($"{path}: {message}");
	}

	public class Line(TimelineFile file, string content, int number)
	{
		static readonly RegEx textAndDirectiveRegex = RegEx.CreateFromString(
			@"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
		);

		public IEnumerable<(string? text, Directive? directive)> Parts()
		{
			foreach (var match in textAndDirectiveRegex.SearchAll(content))
			{
				var text = match.GetString("text");
				if (text != "")
				{
					yield return (text, null);
				}

				var directiveName = match.GetString("directive_name");
				var directiveValue = match.GetString("directive_value");

				if (directiveName != "" && directiveValue != "")
				{
					yield return (null, new Directive(this, directiveName, directiveValue));
				}
			}
		}

		public void PrintError(string message)
		{
			GD.PrintErr($"{file.path}:{number}: {message}");
		}
	}

	public class Directive(Line line, string name, string value)
	{
		public readonly string name = name;
		public readonly string value = value;

		readonly string[] directiveParts = value.Split(",", false);

		public Dictionary<string, DirectiveArg> NamedArgs =>
			directiveParts
				.Where(part => part.Contains('='))
				.Select(part => part.Split("="))
				.ToDictionary(parts => parts[0], parts => new DirectiveArg(this, parts[1]));

		public List<DirectiveArg> PositionalArgs =>
			directiveParts
				.Where(part => !part.Contains('='))
				.Select(part => new DirectiveArg(this, part))
				.ToList();

		public void PrintError(string message)
		{
			line.PrintError($"Invalid directive [{name}:{value}]: {message}");
		}

		public DirectiveArg? GetOptionalArg(string name)
		{
			return NamedArgs.GetValueOrDefault(name);
		}

		public DirectiveArg? GetOptionalArg(int position)
		{
			return PositionalArgs.ElementAtOrDefault(position);
		}

		public DirectiveArg? GetRequiredArg(string name)
		{
			var arg = GetOptionalArg(name);
			if (arg is null)
			{
				PrintError($"Missing required argument '{name}'");
			}
			return arg;
		}

		public DirectiveArg? GetRequiredArg(int position)
		{
			var arg = GetOptionalArg(position);
			if (arg is null)
			{
				PrintError($"Missing required argument at position {position}");
			}
			return arg;
		}
	}

	public class DirectiveArg(Directive directive, string value)
	{
		public string Value => value;

		public double? AsDouble()
		{
			if (!double.TryParse(Value, out var result))
			{
				directive.PrintError($"\"{Value}\" is not a valid number");
				return null;
			}
			return result;
		}
	}
}
