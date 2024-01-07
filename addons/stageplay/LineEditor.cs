using System.Collections.Generic;
using System.Linq;
using Godot;

namespace StagePlay
{
	[Tool]
	partial class LineEditor : Control
	{
		TextField SpeakerField => GetNode<TextField>("%SpeakerField");
		BoxContainer DirectiveList => GetNode<BoxContainer>("%DirectiveList");
		Button AddDirectiveButton => GetNode<Button>("%AddDirectiveButton");

		[Export]
		internal string Speaker
		{
			get => SpeakerField?.Value ?? "";
			set => SpeakerField.Perform(sf => sf.Value = value);
		}

		internal static LineEditor Create()
		{
			return GD.Load<PackedScene>("res://addons/stageplay/LineEditor.tscn")
				.Instantiate<LineEditor>();
		}

		internal static LineEditor Unpack(EditorData.Line data)
		{
			var instance = Create();
			instance.Speaker = data.Speaker;
			foreach (var directive in data.Directives)
			{
				if (directive.Dialog is not null)
				{
					instance.AddDirectiveEditor(DialogDirectiveEditor.Unpack(directive));
				}
			}
			return instance;
		}

		internal EditorData.Line Pack()
		{
			var directives =
				from directive in DirectiveList.GetChildren().AsEnumerable()
				where directive is IDirectiveEditor
				select directive.Pack();
			return new(Speaker, directives);
		}

		public override void _Ready()
		{
			AddDirectiveButton.Pressed += () => AddDirectiveEditor(DialogDirectiveEditor.Create());
		}

		internal void AddDirectiveEditor(IDirectiveEditor editor)
		{
			DirectiveList.AddChild(editor.AsControl());
		}
	}
}
