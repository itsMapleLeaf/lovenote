using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

namespace StagePlay
{
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

		internal static LineEditor FromData(StageLine line)
		{
			var editor = GD.Load<PackedScene>("res://addons/stageplay/LineEditor.tscn")
				.Instantiate<LineEditor>();

			editor.Speaker = line.Speaker;

			foreach (var directive in line.Directives)
			{
				editor.AddDirectiveEditor(directive.CreateEditor());
			}

			return editor;
		}

		internal static LineEditor Empty()
		{
			var editor = GD.Load<PackedScene>("res://addons/stageplay/LineEditor.tscn")
				.Instantiate<LineEditor>();

			editor.Speaker = "Speaker";

			return editor;
		}

		public IEnumerable<IDirectiveEditor> DirectiveEditors =>
			DirectiveList.GetChildren().Cast<IDirectiveEditor>();

		public void AddDirectiveEditor(IDirectiveEditor editor)
		{
			DirectiveList.AddChild(editor.AsControl());
		}
	}
}
