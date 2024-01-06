using Godot;

namespace StagePlay
{
	public interface IDirectiveEditor
	{
		Control AsControl();
		IDirective GetData();
	}
}
