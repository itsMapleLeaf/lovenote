using System.Collections.Generic;
using Godot;

public class TimelineFile
{
	readonly string path;
	readonly string content;

	public TimelineFile(string path)
	{
		this.path = path;
		content = FileAccess.GetFileAsString(path);
	}

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

	public class Line
	{
		static readonly RegEx textAndDirectiveRegex = RegEx.CreateFromString(
			@"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
		);

		readonly TimelineFile file;
		readonly string content;
		readonly int number;

		public Line(TimelineFile file, string content, int number)
		{
			this.file = file;
			this.content = content;
			this.number = number;
		}

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

	public class Directive
	{
		public readonly string name;
		public readonly string value;

		readonly Line line;
		readonly Dictionary<string, string> namedArgs = new();
		readonly List<string> positionalArgs = new();

		public Directive(Line line, string name, string value)
		{
			this.line = line;
			this.name = name;
			this.value = value;

			foreach (var valuePart in value.Split(",", false))
			{
				var argParts = valuePart.Split("=");
				if (argParts.Length == 2)
				{
					namedArgs[argParts[0]] = argParts[1];
				}
				else
				{
					positionalArgs.Add(argParts[0]);
				}
			}
		}

		public void PrintError(string message)
		{
			line.PrintError($"Invalid directive [{name}:{value}]: {message}");
		}

		public DirectiveArg? GetOptionalArg(string name)
		{
			if (!namedArgs.ContainsKey(name))
			{
				return null;
			}
			return new DirectiveArg(this, namedArgs[name]);
		}

		public DirectiveArg? GetOptionalArg(int position)
		{
			if (positionalArgs.Count <= position)
			{
				return null;
			}
			return new DirectiveArg(this, positionalArgs[position]);
		}

		public DirectiveArg? GetRequiredArg(string name)
		{
			if (!namedArgs.ContainsKey(name))
			{
				PrintError($"Missing required argument '{name}'");
				return null;
			}
			return new DirectiveArg(this, namedArgs[name]);
		}

		public DirectiveArg? GetRequiredArg(int position)
		{
			if (positionalArgs.Count <= position)
			{
				PrintError($"Missing required argument at position {position}");
				return null;
			}
			return new DirectiveArg(this, positionalArgs[position]);
		}
	}

	public class DirectiveArg
	{
		readonly Directive directive;
		readonly string value;

		public DirectiveArg(Directive directive, string value)
		{
			this.directive = directive;
			this.value = value;
		}

		public string AsString()
		{
			return value;
		}

		public double? AsDouble()
		{
			if (!value.IsValidFloat())
			{
				directive.PrintError($"Invalid float value '{value}'");
				return null;
			}
			return value.ToFloat();
		}
	}
}
