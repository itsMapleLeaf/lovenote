using System.Collections.Generic;
using System.Linq;
using Godot;

namespace StagePlay
{
	internal record EditorData(IEnumerable<EditorData.Line> Lines)
	{
		internal record Line(string Speaker, IEnumerable<Directive> Directives);

		internal record Directive
		{
			internal string? Dialog { get; set; }
			internal double? DialogSpeed { get; set; }
			internal double? Wait { get; set; }
			internal ActorUpdate? ActorUpdate { get; set; }
		}

		internal record ActorUpdate(string ActorName)
		{
			internal double Duration { get; set; }
			internal Vector2? Position { get; set; }
			internal double? Rotation { get; set; }
			internal double? Scale { get; set; }
			internal double? Opacity { get; set; }
		}
	}
}
