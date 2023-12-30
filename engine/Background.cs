using System;
using Godot;

public partial class Background : TextureRect
{
	Tween? tween;

	public override void _Ready()
	{
		Modulate = new Color(Modulate, 0);
	}

	public void FadeIn()
	{
		tween?.Pause();
		tween = CreateTween().SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Quad);
		tween.TweenProperty(
			this,
			CanvasItem.PropertyName.Modulate.ToString(),
			new Color(Modulate, 1),
			1.0
		);
	}

	public void FadeOut()
	{
		tween?.Pause();
		tween = CreateTween().SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Quad);
		tween.TweenProperty(
			this,
			CanvasItem.PropertyName.Modulate.ToString(),
			new Color(Modulate, 0),
			1.0
		);
	}
}
