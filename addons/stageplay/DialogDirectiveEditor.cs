using Godot;

namespace StagePlay
{
	[Tool]
	partial class DialogDirectiveEditor : TextEdit, IDirectiveEditor
	{
		private DialogDirectiveEditor() { }

		internal static DialogDirectiveEditor Create()
		{
			return GD.Load<PackedScene>("res://addons/stageplay/DialogDirectiveEditor.tscn")
				.Instantiate<DialogDirectiveEditor>();
		}

		public static IDirectiveEditor Unpack(EditorData.Directive data)
		{
			var instance = Create();
			instance.Text = data.Dialog ?? "";
			return instance;
		}

		EditorData.Directive IDirectiveEditor.Pack()
		{
			return new() { Dialog = Text };
		}

		Control IDirectiveEditor.AsControl()
		{
			return this;
		}
	}
}
