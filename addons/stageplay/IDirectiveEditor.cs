using Godot;

public interface IDirectiveEditor
{
	public Control AsControl();
	public TimelineData.IDirective GetData();
}
