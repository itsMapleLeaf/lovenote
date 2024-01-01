using System.Collections.Immutable;

public readonly record struct StageSnapshot(
	string DialogSpeaker,
	string DialogText,
	string? Background,
	// todo: this should just be <string, (double position)>
	ImmutableDictionary<string, (string name, double position)> Characters
)
{
	public static StageSnapshot Empty { get; } =
		new("", "", null, ImmutableDictionary<string, (string name, double position)>.Empty);
}
