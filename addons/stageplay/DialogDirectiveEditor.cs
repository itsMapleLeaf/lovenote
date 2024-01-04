using System;
using System.Collections.Generic;
using Godot;

[Tool]
public partial class DialogDirectiveEditor : TextEdit
{
	public DialogDirectiveResource ToResource() => new() { Text = Text };

	public override void _GuiInput(InputEvent @event)
	{
		this.HandleKeyboardVerticalFocus(@event);
	}
}
