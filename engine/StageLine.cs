using System;
using System.Collections.Generic;
using System.Linq;

public class StageLine
{
	readonly Stage stage;
	public readonly StageSnapshot startState;
	public readonly StageSnapshot endState;
	public List<StageDirective> directives = new();
	Action? currentCancelAction;

	public StageLine(TimelineFile.Line sourceLine, Stage stage, StageSnapshot previousEndState)
	{
		this.stage = stage;
		endState = startState = previousEndState with { DialogSpeaker = "", DialogText = "" };

		foreach (var (text, directive) in sourceLine.Parts())
		{
			if (text is not null)
			{
				var dialogDirective = new StageDirective.DialogDirective(text);
				AddDirective(dialogDirective);
				endState = dialogDirective.UpdateSnapshot(endState);
			}

			if (directive is null)
			{
				continue;
			}

			var stageDirective = StageDirective.FromSourceDirective(directive, stage);
			if (stageDirective is not null)
			{
				AddDirective(stageDirective);
				endState = stageDirective.UpdateSnapshot(endState);
			}
		}
	}

	public void AddDirective(StageDirective directive)
	{
		directives.Add(directive);
	}

	public bool IsEmpty()
	{
		return !directives.Any();
	}

	public void Play()
	{
		RunDirectiveAt(0);
	}

	void RunDirectiveAt(int index)
	{
		var directive = directives.ElementAtOrDefault(index);
		if (directive is null)
		{
			currentCancelAction = null;
		}
		else
		{
			currentCancelAction = directive.Run(stage, () => RunDirectiveAt(index + 1));
		}
	}

	public bool IsPlaying()
	{
		return currentCancelAction is not null;
	}

	public void Cancel()
	{
		currentCancelAction?.Invoke();
		currentCancelAction = null;
	}
}
