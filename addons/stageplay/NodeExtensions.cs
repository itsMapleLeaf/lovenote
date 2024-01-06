using Godot;

namespace StagePlay
{
	static partial class NodeExtensions
	{
		internal static void RemoveAllChildren(this Node node)
		{
			foreach (var child in node.GetChildren())
			{
				child.QueueFree();
			}
		}
	}
}
