using System;
using System.Collections.Generic;
using Godot;

public partial class TimelinePlayer : Node
{
	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export]
	int PreviewLineIndex
	{
		get => _previewLineIndex;
		set
		{
			if (lines.Count == 0)
			{
				_previewLineIndex = value;
				return;
			}

			_previewLineIndex = Mathf.Clamp(value, 0, lines.Count - 1);
			SeekTo(_previewLineIndex);
		}
	}
	int _previewLineIndex = 0;

	readonly List<StageLine> lines = new();

	int currentLineIndex = 0;

	StageLine? CurrentLine => currentLineIndex < lines.Count ? lines[currentLineIndex] : null;

	Stage? _stage;
	Stage Stage => _stage ??= GetNode<Stage>("%Stage");

	Control? _inputCover;
	Control InputCover => _inputCover ??= GetNode<Control>("%InputCover");

	public override void _Ready()
	{
		LoadTimeline();
		InputCover.GuiInput += _UnhandledInput;
		CurrentLine?.Reset();
		SeekTo(PreviewLineIndex);
	}

	void LoadTimeline()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file is not set");
			return;
		}

		var currentEndState = StageSnapshot.Empty;

		foreach (var sourceLine in TimelineFile.Lines(timelineFilePath))
		{
			var line = new StageLine(sourceLine, Stage, currentEndState);
			if (!line.IsEmpty())
			{
				lines.Add(line);
				currentEndState = line.endState;
			}
		}

		GD.PrintRich(
			$"[color=gray]Loaded timeline with [color=white]{lines.Count}[/color] lines[/color]"
		);
	}

	public override void _Process(double delta)
	{
		CurrentLine?.Process(delta);
		Stage.Dialog.AdvanceIndicatorVisible = CurrentLine?.IsPlaying() != true;
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed(InputActionName.DialogAdvance))
		{
			Advance();
		}
		if (@event.IsActionPressed(InputActionName.DialogBack))
		{
			Back();
		}
		if (@event.IsActionPressed(InputActionName.DialogNext))
		{
			Next();
		}
	}

	void Advance()
	{
		if (CurrentLine?.IsPlaying() == true)
		{
			CurrentLine?.Skip();
		}
		else if (currentLineIndex < lines.Count - 1)
		{
			currentLineIndex += 1;
			CurrentLine?.Reset();
		}
	}

	void Next()
	{
		if (currentLineIndex < lines.Count - 1)
		{
			currentLineIndex += 1;
		}
		if (CurrentLine is not null)
		{
			CurrentLine.Skip();
			Stage.ApplySnapshot(CurrentLine.endState);
		}
	}

	void Back()
	{
		if (currentLineIndex > 0)
		{
			currentLineIndex -= 1;
		}
		if (CurrentLine is not null)
		{
			CurrentLine.Skip();
			Stage.ApplySnapshot(CurrentLine.endState);
		}
	}

	void SeekTo(int index)
	{
		while (currentLineIndex < index)
		{
			Next();
		}
		while (currentLineIndex > index)
		{
			Back();
		}
	}
}
