using System;
using Godot;

namespace StagePlay
{
	[Tool]
	partial class TextField : PanelContainer
	{
		[Export]
		internal string Label
		{
			get => LabelNode?.Text ?? "Label";
			set { LabelNode.Perform(node => node.Text = value); }
		}

		[Export]
		internal string Placeholder
		{
			get => InputNode?.PlaceholderText ?? "Placeholder";
			set { InputNode.Perform(node => node.PlaceholderText = value); }
		}

		[Export]
		internal string Value
		{
			get => InputNode?.Text ?? "";
			set { InputNode.Perform(node => node.Text = value); }
		}

		[Export]
		internal HorizontalAlignment InputAlignment
		{
			get => InputNode?.Alignment ?? HorizontalAlignment.Left;
			set { InputNode.Perform(node => node.Alignment = value); }
		}

		Label? LabelNode => GetNodeOrNull<Label>("%Label");
		LineEdit? InputNode => GetNodeOrNull<LineEdit>("%Input");
	}
}
