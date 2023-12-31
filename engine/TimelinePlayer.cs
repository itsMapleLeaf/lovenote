using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class TimelinePlayer : Node
{
	List<StageLine> lines = new();
	bool isTimelineLoaded = false;

	int _currentLineIndex = 0;
	int CurrentLineIndex
	{
		get => _currentLineIndex;
		set { _currentLineIndex = Mathf.Clamp(value, 0, lines.Count - 1); }
	}

	StageLine? CurrentLine => lines.ElementAtOrDefault(CurrentLineIndex);

	Stage? _stage;
	Stage Stage => _stage ??= GetNode<Stage>("%Stage");

	Control? _inputCover;
	Control InputCover => _inputCover ??= GetNode<Control>("%InputCover");

	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export]
	int PreviewLineIndex
	{
		get => _previewLineIndex;
		set
		{
			if (!isTimelineLoaded)
			{
				_previewLineIndex = value;
				return;
			}

			_previewLineIndex = value;
			SeekTo(value - 1);
			Advance();
		}
	}
	int _previewLineIndex = 0;

	List<StageLine> LoadTimeline()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file is not set");
			return new();
		}

		var currentEndState = StageSnapshot.Empty;
		var lines = new List<StageLine>();

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

		return lines;
	}

	public override void _Ready()
	{
		lines = LoadTimeline();
		isTimelineLoaded = true;
		InputCover.GuiInput += _UnhandledInput;
		SeekTo(_previewLineIndex - 1);
		Advance();
	}

	public override void _Process(double delta)
	{
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
			SeekBy(-1);
		}
		if (@event.IsActionPressed(InputActionName.DialogNext))
		{
			SeekBy(1);
		}
	}

	void PlayLineAt(int index)
	{
		CurrentLine?.Cancel();
		CurrentLineIndex = index;
		Stage.Dialog.Clear();
		CurrentLine?.Play();
		_previewLineIndex = index;
	}

	void Advance()
	{
		if (CurrentLine?.IsPlaying() == true)
		{
			CurrentLine.Cancel();
			Stage.ApplySnapshot(CurrentLine.endState);
		}
		else
		{
			PlayLineAt(CurrentLineIndex + 1);
		}
	}

	void SeekTo(int index)
	{
		CurrentLine?.Cancel();
		CurrentLineIndex = index;
		Stage.ApplySnapshot(CurrentLine?.endState ?? StageSnapshot.Empty);
		_previewLineIndex = index;
	}

	void SeekBy(int delta)
	{
		SeekTo(CurrentLineIndex + delta);
	}
}
