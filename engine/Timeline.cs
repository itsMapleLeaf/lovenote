using System.Collections.Generic;
using System.Linq;
using Godot;

public class Timeline(List<StageLine> lines)
{
	public List<StageLine> Lines => lines;

	public static Timeline FromFile(string filePath, Stage stage)
	{
		return new Timeline(GetStageLines(filePath, stage).ToList());
	}

	static IEnumerable<StageLine> GetStageLines(string filePath, Stage stage)
	{
		var currentEndState = StageSnapshot.Empty;
		foreach (var sourceLine in TimelineFile.Lines(filePath))
		{
			var line = new StageLine(sourceLine, stage, currentEndState);
			if (!line.IsEmpty())
			{
				yield return line;
				currentEndState = line.endState;
			}
		}
	}

	public StageLine? LineAt(int index)
	{
		return Lines.ElementAtOrDefault(index);
	}
}
