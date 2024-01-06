using System;
using System.Collections.Generic;
using Godot;

namespace StagePlay
{
	[Tool]
	public partial class DialogDirectiveEditor : TextEdit, IDirectiveEditor
	{
		private DialogDirectiveEditor() { }

		public static DialogDirectiveEditor Create(string text = "")
		{
			var instance = GD.Load<PackedScene>("res://addons/stageplay/DialogDirectiveEditor.tscn")
				.Instantiate<DialogDirectiveEditor>();
			instance.Text = text;
			return instance;
		}

		public Control AsControl() => this;

		public IDirective GetData() => new DialogDirective(Text);
	}
}
