using System;
using Godot;

[Tool]
public partial class TextField : PanelContainer
{
	[Export]
	public string Label
	{
		get => LabelNode?.Text ?? "Label";
		set
		{
			if (LabelNode != null)
				LabelNode.Text = value;
		}
	}

	[Export]
	public string Placeholder
	{
		get => InputNode?.PlaceholderText ?? "Placeholder";
		set
		{
			if (InputNode != null)
				InputNode.PlaceholderText = value;
		}
	}

	[Export]
	public string Value
	{
		get => InputNode?.Text ?? "";
		set
		{
			if (InputNode != null)
				InputNode.Text = value;
		}
	}

	[Export]
	public HorizontalAlignment InputAlignment
	{
		get => InputNode?.Alignment ?? HorizontalAlignment.Left;
		set
		{
			if (InputNode != null)
				InputNode.Alignment = value;
		}
	}

	Label? LabelNode => GetNodeOrNull<Label>("%Label");
	LineEdit? InputNode => GetNodeOrNull<LineEdit>("%Input");
}
