using System.Text.Json.Nodes;
using Godot;

namespace StagePlay
{
	public interface IDirectiveEditor
	{
		internal Control AsControl();
		internal EditorData.Directive Pack();
		internal static abstract IDirectiveEditor Unpack(EditorData.Directive data);
	}
}
