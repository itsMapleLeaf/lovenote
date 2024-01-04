using Godot;

public static class ControlExtensions
{
	public static void HandleKeyboardVerticalFocus(this Control node, InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.IsPressed())
		{
			var nextNode = keyEvent.Keycode switch
			{
				Key.Down => node.FindNextValidFocus(),
				Key.Up => node.FindPrevValidFocus(),
				_ => null,
			};

			var mainScreen = EditorInterface.Singleton.GetEditorMainScreen();
			if (nextNode is not null && mainScreen.IsAncestorOf(nextNode))
			{
				node.GetViewport().SetInputAsHandled();
				nextNode.CallDeferred(Control.MethodName.GrabFocus);
			}
		}
	}
}
