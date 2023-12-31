using System;
using Godot;

public partial class Background : TextureRect
{
	Tween? tween;

	public override void _Ready()
	{
		Modulate = new Color(Modulate, 0);
	}

	public void FadeIn(double duration = 1.0)
	{
		tween?.Pause();

		if (duration == 0)
		{
			Modulate = new Color(Modulate, 1);
			return;
		}

		tween = CreateTween().SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Quad);
		tween.TweenProperty(
			this,
			CanvasItem.PropertyName.Modulate.ToString(),
			new Color(Modulate, 1),
			duration
		);
	}

	public void FadeOut(double duration = 1.0)
	{
		tween?.Pause();

		if (duration == 0)
		{
			Modulate = new Color(Modulate, 0);
			return;
		}

		tween = CreateTween().SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Quad);
		tween.TweenProperty(
			this,
			CanvasItem.PropertyName.Modulate.ToString(),
			new Color(Modulate, 0),
			duration
		);
	}
}
