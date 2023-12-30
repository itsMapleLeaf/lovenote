using System;
using Godot;

public partial class Character : Control
{
	const double DEFAULT_TWEEN_DUTATION = 0.5;

	double stagePosition = 0.5;

	[Export(PropertyHint.Range, "0, 1, 0.05")]
	public double StagePosition
	{
		get => stagePosition;
		set
		{
			stagePosition = value;
			AnchorLeft = (float)stagePosition;
			AnchorRight = (float)stagePosition;
		}
	}

	Vector2 spriteOffset = Vector2.Zero;

	[Export]
	public Vector2 SpriteOffset
	{
		get => spriteOffset;
		set
		{
			spriteOffset = value;
			this.AfterReady(() => Sprite!.Position = spriteOffset);
		}
	}

	public string CharacterName = "";

	Tween? tween;
	Tween Tween =>
		tween ??= CreateTween()
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Quad)
			.SetParallel();

	Control Sprite => GetNode<Control>("%Sprite");

	public void MoveTo(double position, double? duration)
	{
		Tween.TweenProperty(
			this,
			PropertyName.StagePosition.ToString(),
			position,
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void MoveBy(double amount, double? duration)
	{
		MoveTo(StagePosition + amount, duration);
	}

	public void FadeIn(double? duration)
	{
		Tween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			Colors.White,
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void FadeOut(double? duration)
	{
		Tween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			Colors.Transparent,
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void FinishTween()
	{
		Tween.CustomStep(double.PositiveInfinity);
	}
}
