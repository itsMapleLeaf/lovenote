using System;
using System.Linq;
using System.Text.Json;
using Godot;
using Godot.Collections;

[Tool]
public partial class TimelineEditor : Control
{
	Control LineList => GetNode<Control>("%LineList");

	public override void _Ready()
	{
		GetNode<Button>("%MenuBar/NewButton").Pressed += () => Unpack(new TimelineData([]));
		GetNode<Button>("%MenuBar/OpenButton").Pressed += LoadWithDialog;
		GetNode<Button>("%MenuBar/SaveButton").Pressed += () => { };
		GetNode<Button>("%MenuBar/SaveAsButton").Pressed += SaveWithDialog;
		GetNode<Button>("%AddLineButton").Pressed += AddLine;
		Unpack(TimelineData.Mock());
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.IsPressed())
		{
			var node = GetTree().Root.GuiGetFocusOwner();
			var nextNode = keyEvent.Keycode switch
			{
				Key.Down => node.FindNextValidFocus(),
				Key.Up => node.FindPrevValidFocus(),
				_ => null,
			};

			if (nextNode is not null)
			{
				GetViewport().SetInputAsHandled();

				var mainScreen = EditorInterface.Singleton.GetEditorMainScreen();
				if (mainScreen.IsAncestorOf(nextNode))
				{
					nextNode.CallDeferred(Control.MethodName.GrabFocus);
				}
			}
		}
	}

	void AddLine()
	{
		LineList.AddChild(LineEditor.Empty());
	}

	TimelineData ToTimelineData() =>
		new(
			from lineEditor in LineList.GetChildren().Cast<LineEditor>()
			select new TimelineData.Line(
				lineEditor.Speaker,
				from directiveEditor in lineEditor.DirectiveEditors
				select directiveEditor.GetData()
			)
		);

	void Unpack(TimelineData data)
	{
		LineList.RemoveAllChildren();
		foreach (var line in data.Lines)
		{
			LineList.AddChild(LineEditor.FromData(line));
		}
	}

	void SaveWithDialog()
	{
		var dialog = new FileDialog
		{
			FileMode = FileDialog.FileModeEnum.SaveFile,
			Filters = ["*.json"]
		};
		AddChild(dialog);
		dialog.PopupCentered(new Vector2I(800, 800));

		dialog.FileSelected += (path) =>
		{
			ToTimelineData().Save(path);
		};
	}

	void LoadWithDialog()
	{
		var dialog = new FileDialog
		{
			FileMode = FileDialog.FileModeEnum.OpenFile,
			Filters = ["*.json"]
		};
		AddChild(dialog);
		dialog.PopupCentered(new Vector2I(800, 800));

		dialog.FileSelected += (path) =>
		{
			var data = TimelineData.FromFile(path);
			if (data is null)
			{
				GD.PushError("File is empty");
				return;
			}
			Unpack(data);
		};
	}
}
