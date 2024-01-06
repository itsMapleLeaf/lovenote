using Godot;

namespace StagePlay
{
	public static partial class NodeExtensions
	{
		public static void RemoveAllChildren(this Node node)
		{
			foreach (var child in node.GetChildren())
			{
				child.QueueFree();
			}
		}
	}
}
