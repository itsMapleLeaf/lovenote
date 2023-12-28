using System;
using Godot;

public static class NodeExtensions
{
	public static void AfterReady(this Node node, Action callback)
	{
		if (node.IsNodeReady())
		{
			callback();
		}
		else
		{
			node.Ready += callback;
		}
	}
}
