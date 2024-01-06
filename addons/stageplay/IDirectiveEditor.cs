using Godot;

namespace StagePlay
{
	public interface IDirectiveEditor
	{
		public Control AsControl();
		public IDirective GetData();
	}
}
