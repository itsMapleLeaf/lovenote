using System.Collections.Generic;
using System.Linq;

public class StageLine
{
	public List<StageDirective> Directives = new();
	public int CurrentDirectiveIndex = 0;

	readonly Stage stage;

	internal StageLine(TimelineFile.Line sourceLine, Stage stage)
	{
		this.stage = stage;

		foreach (var (text, directive) in sourceLine.Parts())
		{
			if (text is not null)
			{
				AddDirective(new StageDirective.DialogDirective(text));
			}

			if (directive is null)
			{
				continue;
			}

			var stageDirective = StageDirective.FromSourceDirective(directive, stage);
			if (stageDirective is not null)
			{
				AddDirective(stageDirective);
			}
		}
	}

	internal bool IsEmpty()
	{
		return !Directives.Any();
	}

	public void Reset()
	{
		CurrentDirectiveIndex = 0;
		foreach (var directive in Directives)
		{
			directive.Reset();
		}
		stage.Dialog.Reset();
	}

	public void Process(double delta)
	{
		while (CurrentDirectiveIndex < Directives.Count)
		{
			var directive = Directives[CurrentDirectiveIndex];
			directive.Process(stage, delta);
			if (directive.IsPlaying(stage))
			{
				break;
			}
			else
			{
				CurrentDirectiveIndex += 1;
			}
		}
	}

	public bool IsPlaying()
	{
		return CurrentDirectiveIndex < Directives.Count;
	}

	public void Skip()
	{
		while (CurrentDirectiveIndex < Directives.Count)
		{
			Directives[CurrentDirectiveIndex].Skip(stage);
			CurrentDirectiveIndex += 1;
		}
	}

	internal void AddDirective(StageDirective directive)
	{
		Directives.Add(directive);
	}
}
