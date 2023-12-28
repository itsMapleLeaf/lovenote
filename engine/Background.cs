using System;
using Godot;

public partial class Background : TextureRect
{
	public override void _Ready()
	{
		Modulate = new Color(Modulate, 0);
	}

	public void Enter(Texture2D texture, double fadeDuration)
	{
		Texture = texture;

		var tween = CreateTween();
		tween
			.TweenProperty(
				this,
				CanvasItem.PropertyName.Modulate.ToString(),
				new Color(Modulate, 1),
				fadeDuration
			)
			.From(new Color(Modulate, 0));
	}

	public async void Leave(double fadeDuration)
	{
		var tween = CreateTween();
		tween
			.TweenProperty(
				this,
				CanvasItem.PropertyName.Modulate.ToString(),
				new Color(Modulate, 0),
				fadeDuration
			)
			.From(new Color(Modulate, 1));
		await ToSignal(tween, Tween.SignalName.Finished);
		QueueFree();
	}
}
