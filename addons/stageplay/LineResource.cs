using Godot;

[Tool]
public partial class LineResource : Resource
{
	[Export]
	public string Speaker { get; set; } = "";

	[Export]
	public DialogDirectiveResource[] Directives { get; set; } = [];
}
