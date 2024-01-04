using System;
using System.Collections.Generic;
using Godot;

[Tool]
public partial class DialogDirectiveEditor : TextEdit
{
	public DialogDirectiveResource ToResource() => new() { Text = Text };
}
