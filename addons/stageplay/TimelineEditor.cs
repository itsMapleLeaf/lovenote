using System;
using System.Linq;
using Godot;
using Godot.Collections;

[Tool]
public partial class TimelineEditor : Control
{
	Control LineList => GetNode<Control>("%LineList");
	Button AddLineButton => GetNode<Button>("%AddLineButton");
	PopupMenu FileMenu => GetNode<PopupMenu>("%MenuBar/File");

	record MenuOption(string Text, Action Action);

	MenuOption[] FileMenuOptions =>
		[
			new("New", Reset),
			new("Open", OpenFile),
			new("Save", () => { }),
			new("Save As...", SaveAs),
		];

	public override void _Ready()
	{
		foreach (var index in Enumerable.Range(0, FileMenu.ItemCount))
		{
			FileMenu.RemoveItem(0);
		}
		foreach (var (option, index) in FileMenuOptions.Select((option, index) => (option, index)))
		{
			FileMenu.AddItem(option.Text, index);
		}
		FileMenu.IdPressed += index => FileMenuOptions[index].Action();

		AddLineButton.Pressed += () => {
			// var lineEditor = GD.Load<PackedScene>("res://addons/stageplay/LineEditor.tscn")
			// 	.Instantiate();
			// LineList.AddChild(lineEditor);
		};

		Reset();
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

	void Reset()
	{
		UnpackResource(
			new()
			{
				Lines =
				[
					new LineResource
					{
						Speaker = "Ryder",
						Directives =
						[
							new DialogDirectiveResource { Text = "What's it like to die?" },
						]
					},
					new LineResource
					{
						Speaker = "Reina",
						Directives = [new DialogDirectiveResource { Text = "Ryder, what?" },]
					},
					new LineResource
					{
						Speaker = "Ryder",
						Directives = [new DialogDirectiveResource { Text = "I'm just curious." },]
					},
				]
			}
		);
	}

	void SaveAs()
	{
		var dialog = new FileDialog
		{
			FileMode = FileDialog.FileModeEnum.SaveFile,
			Filters = ["*.tres"]
		};
		AddChild(dialog);
		dialog.PopupCentered(new Vector2I(800, 800));

		dialog.FileSelected += (path) =>
		{
			var error = ResourceSaver.Save(new TimelineResource(), path);
			if (error != Error.Ok)
			{
				GD.PushError($"Error saving file: {error}");
			}
		};
	}

	void OpenFile()
	{
		var dialog = new FileDialog
		{
			FileMode = FileDialog.FileModeEnum.OpenFile,
			Filters = ["*.tres"]
		};
		AddChild(dialog);
		dialog.PopupCentered(new Vector2I(800, 800));

		dialog.FileSelected += (path) =>
		{
			var resource = GD.Load<TimelineResource>(path);
			if (resource is null)
			{
				GD.PushError($"Error loading file: {path}");
				return;
			}
			UnpackResource(resource);
		};
	}

	TimelineResource CreateResource()
	{
		var resource = new TimelineResource()
		{
			Lines = LineList
				.GetChildren()
				.OfType<LineEditor>()
				.Select(lineEditor => lineEditor.ToResource())
				.ToArray()
		};
		return resource;
	}

	void UnpackResource(TimelineResource timeline)
	{
		LineList.RemoveAllChildren();

		foreach (var line in timeline.Lines)
		{
			var lineEditor = GD.Load<PackedScene>("res://addons/stageplay/LineEditor.tscn")
				.Instantiate<LineEditor>();
			lineEditor.Speaker = line.Speaker;
			LineList.AddChild(lineEditor);

			foreach (var directive in line.Directives)
			{
				if (directive is DialogDirectiveResource dialogDirective)
				{
					var editor = GD.Load<PackedScene>(
							"res://addons/stageplay/DialogDirectiveEditor.tscn"
						)
						.Instantiate<DialogDirectiveEditor>();
					editor.Text = dialogDirective.Text;
					lineEditor.AddDirective(editor);
				}
			}
		}
	}
}
