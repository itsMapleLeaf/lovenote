using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class TimelinePlayer : Node
{
	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export(PropertyHint.Range, "0,999999,1")]
	int PreviewLineIndex
	{
		get => currentLineIndex;
		set
		{
			if (timeline is null)
			{
				currentLineIndex = value;
			}
			else
			{
				PlayLineAt(value, PlayMode.Play);
			}
		}
	}

	Timeline? timeline;
	int currentLineIndex = 0;
	StageLine? CurrentLine => timeline?.LineAt(currentLineIndex);

	Stage? _stage;
	Stage Stage => _stage ??= GetNode<Stage>("%Stage");

	Control? _inputCover;
	Control InputCover => _inputCover ??= GetNode<Control>("%InputCover");

	public override void _Ready()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file not set");
			return;
		}

		timeline = Timeline.FromFile(timelineFilePath, Stage);
		InputCover.GuiInput += _UnhandledInput;
		PlayLineAt(currentLineIndex, PlayMode.Play);
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
			PlayLineAt(currentLineIndex - 1, PlayMode.Skip);
		}
		if (@event.IsActionPressed(InputActionName.DialogNext))
		{
			PlayLineAt(currentLineIndex + 1, PlayMode.Skip);
		}
		if (@event.IsActionPressed(InputActionName.ReloadTimeline))
		{
			timeline = Timeline.FromFile(timelineFilePath, Stage);
			PlayLineAt(currentLineIndex, PlayMode.Play);
		}
	}

	enum PlayMode
	{
		Play,
		Skip,
	}

	void PlayLineAt(int index, PlayMode mode)
	{
		if (timeline is null)
		{
			return;
		}

		CurrentLine?.Cancel();
		currentLineIndex = Mathf.Clamp(index, 0, timeline?.Lines.Count ?? 0);

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
	}

	void Advance()
	{
		if (CurrentLine?.IsPlaying() == true)
		{
			PlayLineAt(currentLineIndex, PlayMode.Skip);
		}
		else
		{
			PlayLineAt(currentLineIndex + 1, PlayMode.Play);
		}
	}
}
