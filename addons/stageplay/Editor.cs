using System;
using System.Linq;
using System.Text.Json;
using Godot;
using Godot.Collections;

namespace StagePlay
{
	[Tool]
	partial class Editor : Control
	{
		Control Lines => GetNode<Control>("%LineList");

		static EditorData PlaceholderData =>
			new(
				[
					new("Ryder", [new() { Dialog = "Do you ever wonder what it's like to die?" },]),
					new(
						"Reina",
						[
							new() { DialogSpeed = 0.1 },
							new() { Dialog = "..." },
							new() { Wait = 1 },
							new() { Dialog = "Ryder, what?" },
						]
					),
					new("Ryder", [new() { Dialog = "I'm just curious." },]),
				]
			);

		public override void _Ready()
		{
			GetNode<Button>("%MenuBar/NewButton").Pressed += () => Unpack(new EditorData([]));
			GetNode<Button>("%MenuBar/OpenButton").Pressed += ShowLoadDialog;
			GetNode<Button>("%MenuBar/SaveButton").Pressed += () => { };
			GetNode<Button>("%MenuBar/SaveAsButton").Pressed += ShowSaveDialog;
			GetNode<Button>("%AddLineButton").Pressed += AddEmptyLine;
			Unpack(PlaceholderData);
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

		void AddEmptyLine()
		{
			Lines.AddChild(LineEditor.Create());
		}

		void Unpack(EditorData data)
		{
			Lines.RemoveAllChildren();
			foreach (var line in data.Lines)
			{
				Lines.AddChild(LineEditor.Unpack(line));
			}
		}

		EditorData Pack()
		{
			return new(Lines.GetChildren().Cast<LineEditor>().Select(line => line.Pack()));
		}

		void ShowSaveDialog()
		{
			var dialog = new FileDialog
			{
				FileMode = FileDialog.FileModeEnum.SaveFile,
				Filters = ["*.json"]
			};
			AddChild(dialog);
			dialog.FileSelected += Save;
			dialog.PopupCentered(new Vector2I(800, 800));
		}

		void Save(string filePath)
		{
			using var file = FileAccess.Open(filePath, FileAccess.ModeFlags.Write);
			file.StoreBuffer(JsonSerializer.SerializeToUtf8Bytes(Pack()));
		}

		void ShowLoadDialog()
		{
			var dialog = new FileDialog
			{
				FileMode = FileDialog.FileModeEnum.OpenFile,
				Filters = ["*.json"]
			};
			AddChild(dialog);
			dialog.FileSelected += Load;
			dialog.PopupCentered(new Vector2I(800, 800));
		}

		void Load(string path)
		{
			var bytes = FileAccess.GetFileAsBytes(path);
			var data = JsonSerializer.Deserialize<EditorData>(bytes);
			if (data is null)
			{
				GD.PrintErr("Failed to deserialize data");
				return;
			}
			Unpack(data);
		}
	}
}
