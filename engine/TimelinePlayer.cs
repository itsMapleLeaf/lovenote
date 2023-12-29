using System;
using Godot;

public partial class TimelinePlayer : Node
{
	[Export(PropertyHint.File, "*.md")]
	public string? TimelineFile;

	private Timeline? timeline;
	private Stage Stage => GetNode<Stage>("%Stage");

	public override void _Ready()
	{
		if (TimelineFile != null)
		{
			timeline = Timeline.FromFile(TimelineFile);
		}
		else
		{
			GD.PrintErr("Timeline file is not set");
		}

		GetNode<Control>("%InputCover").GuiInput += (@event) =>
		{
			if (@event.IsActionPressed("dialog_advance"))
			{
				timeline?.Advance(Stage);
			}
		};
	}

	public override void _Process(double delta)
	{
		timeline?.Process(Stage, delta);
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed("dialog_advance"))
		{
			timeline?.Advance(Stage);
		}
	}
}
