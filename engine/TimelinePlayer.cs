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
			PlayLineAt(_previewLineIndex, PlayMode.Play);
		}
	}
	int _previewLineIndex = 0;

	IEnumerable<StageLine> LoadTimeline()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file is not set");
			yield break;
		}

		var currentEndState = StageSnapshot.Empty;
		var lines = new List<StageLine>();

		foreach (var sourceLine in TimelineFile.Lines(timelineFilePath))
		{
			var line = new StageLine(sourceLine, Stage, currentEndState);
			if (!line.IsEmpty())
			{
				yield return line;
				currentEndState = line.endState;
			}
		}

		GD.PrintRich(
			$"[color=gray]Loaded timeline with [color=white]{lines.Count}[/color] lines[/color]"
		);
	}

	public override void _Ready()
	{
		lines = LoadTimeline().ToList();
		isTimelineLoaded = true;
		InputCover.GuiInput += _UnhandledInput;
		PlayLineAt(PreviewLineIndex, PlayMode.Play);
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
			PlayLineAt(CurrentLineIndex - 1, PlayMode.Skip);
		}
		if (@event.IsActionPressed(InputActionName.DialogNext))
		{
			PlayLineAt(CurrentLineIndex + 1, PlayMode.Skip);
		}
	}

	enum PlayMode
	{
		Play,
		Skip,
	}

	void PlayLineAt(int index, PlayMode mode)
	{
		CurrentLine?.Cancel();
		CurrentLineIndex = index;

		Stage.Dialog.Reset();

		if (mode == PlayMode.Skip)
		{
			Stage.ApplySnapshot(CurrentLine?.endState ?? StageSnapshot.Empty);
		}
		else
		{
			Stage.ApplySnapshot(CurrentLine?.startState ?? StageSnapshot.Empty);
			CurrentLine?.Play();
		}

		_previewLineIndex = index;
	}

	void Advance()
	{
		if (CurrentLine?.IsPlaying() == true)
		{
			PlayLineAt(CurrentLineIndex, PlayMode.Skip);
		}
		else
		{
			PlayLineAt(CurrentLineIndex + 1, PlayMode.Play);
		}
	}
}
