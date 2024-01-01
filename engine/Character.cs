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

	Tween? positionTween;
	Tween? modulateTween;

	Control Sprite => GetNode<Control>("%Sprite");

	public override void _Ready()
	{
		if (CharacterName == "")
		{
			GD.PrintErr("Character name is not set");
		}
	}

	public void MoveTo(double position, double? duration)
	{
		positionTween?.Pause();
		positionTween = CreateTween()
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Quad);
		positionTween.TweenProperty(
			this,
			PropertyName.StagePosition.ToString(),
			position,
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void MoveBy(double amount, double? duration)
	{
		positionTween?.CustomStep(double.PositiveInfinity);
		MoveTo(StagePosition + amount, duration);
	}

	public void FadeIn(double? duration)
	{
		modulateTween?.Pause();
		modulateTween = CreateTween()
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Quad);
		modulateTween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			Colors.White,
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void FadeOut(double? duration)
	{
		modulateTween?.Pause();
		modulateTween = CreateTween()
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Quad);
		modulateTween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			new Color(Modulate, 0),
			duration ?? DEFAULT_TWEEN_DUTATION
		);
	}

	public void FinishTweens()
	{
		positionTween?.CustomStep(double.PositiveInfinity);
		modulateTween?.CustomStep(double.PositiveInfinity);
	}
}
