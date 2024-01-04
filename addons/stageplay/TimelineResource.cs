using Godot;

[Tool]
public partial class TimelineResource : Resource
{
	[Export]
	public LineResource[] Lines { get; set; } = [];
}
