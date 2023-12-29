using System;
using Godot;

public partial class Character : Control
{
	private double stagePosition = 0.5;

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

	private Vector2 spriteOffset = Vector2.Zero;

	[Export]
	public Vector2 SpriteOffset
	{
		get => spriteOffset;
		set
		{
			spriteOffset = value;
			this.AfterReady(() => sprite!.Position = spriteOffset);
		}
	}

	public string CharacterName = "";

	private Tween? tween;
	private Control? sprite;

	public override void _Ready()
	{
		sprite = GetNode<Control>("%Sprite");
	}

	/// <param name="fromPosition">The position to start from, relative to toPosition</param>
	/// <param name="toPosition">The position to end at</param>
	/// <param name="duration">The duration of the tween</param>
	public void EnterTweened(double fromPosition, double toPosition, double duration)
	{
		PauseTween();

		StagePosition = toPosition + fromPosition;

		tween = CreateTween()
			.SetParallel(true)
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Quad);

		tween.TweenProperty(this, PropertyName.StagePosition.ToString(), toPosition, duration);
		tween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			new Color(Modulate, 1),
			duration
		);
	}

	/// <param name="byPosition">The amount to move by while leaving</param>
	/// <param name="duration">The duration of the tween</param>
	public async void LeaveTweened(double byPosition, double duration)
	{
		PauseTween();

		tween = CreateTween()
			.SetParallel(true)
			.SetEase(Tween.EaseType.In)
			.SetTrans(Tween.TransitionType.Quad);

		tween.TweenProperty(this, PropertyName.StagePosition.ToString(), byPosition, duration);
		tween.TweenProperty(
			this,
			Character.PropertyName.Modulate.ToString(),
			new Color(Modulate, 0),
			duration
		);

		await ToSignal(tween, Tween.SignalName.Finished);

		QueueFree();
	}

	public void PauseTween()
	{
		tween?.Pause();
	}
}
