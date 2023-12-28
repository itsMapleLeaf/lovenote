using System;
using Godot;

public partial class Global : Node
{
	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed(InputActionName.Quit))
		{
			GetTree().Quit();
		}
	}
}
