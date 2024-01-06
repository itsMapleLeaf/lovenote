using System;
using Godot;

[Tool]
public partial class TextField : PanelContainer
{
	[Export]
	public string Label
	{
		get => LabelNode?.Text ?? "Label";
		set { LabelNode.Perform(node => node.Text = value); }
	}

	[Export]
	public string Placeholder
	{
		get => InputNode?.PlaceholderText ?? "Placeholder";
		set { InputNode.Perform(node => node.PlaceholderText = value); }
	}

	[Export]
	public string Value
	{
		get => InputNode?.Text ?? "";
		set { InputNode.Perform(node => node.Text = value); }
	}

	[Export]
	public HorizontalAlignment InputAlignment
	{
		get => InputNode?.Alignment ?? HorizontalAlignment.Left;
		set { InputNode.Perform(node => node.Alignment = value); }
	}

	Label? LabelNode => GetNodeOrNull<Label>("%Label");
	LineEdit? InputNode => GetNodeOrNull<LineEdit>("%Input");
}
