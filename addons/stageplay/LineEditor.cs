using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

[Tool]
public partial class LineEditor : Control
{
	[Export]
	public string Speaker
	{
		get => SpeakerField?.Value ?? "";
		set => SpeakerField.Perform(sf => sf.Value = value);
	}

	TextField SpeakerField => GetNode<TextField>("%SpeakerField");
	BoxContainer DirectiveList => GetNode<BoxContainer>("%DirectiveList");
	Button AddDirectiveButton => GetNode<Button>("%AddDirectiveButton");

	public void AddDirective(DialogDirectiveEditor directive)
	{
		DirectiveList.AddChild(directive);
	}

	public LineResource ToResource()
	{
		return new() { Speaker = Speaker, Directives = GetDirectiveResources().ToArray(), };
	}

	IEnumerable<DialogDirectiveResource> GetDirectiveResources()
	{
		foreach (var directive in DirectiveList.GetChildren())
		{
			if (directive is DialogDirectiveEditor dialogDirective)
				yield return dialogDirective.ToResource();
		}
	}
}
