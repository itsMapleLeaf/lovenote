using System;
using System.Linq;
using Godot;

public partial class Stage : Node
{
	[Export]
	public double BackgroundFadeDuration = 1.0;

	public Dialog Dialog => GetNode<Dialog>("%Dialog");

	private Background? background;
	private Node BackgroundLayer => GetNode<Node>("%BackgroundLayer");
	private Node CharacterLayer => GetNode<Node>("%CharacterLayer");

	public override void _Ready() { }

	public void SetBackground(Texture2D texture)
	{
		background?.Leave(BackgroundFadeDuration);

		background = GD.Load<PackedScene>("res://engine/Background.tscn").Instantiate<Background>();
		BackgroundLayer.AddChild(background);
		background.Enter(texture, BackgroundFadeDuration);
	}

	public void EnterCharacter(string name, double fromPosition, double toPosition, double duration)
	{
		string scenePath = $"res://content/characters/{name}.tscn";
		var scene = GD.Load(scenePath);
		if (scene is not PackedScene packedScene)
		{
			GD.PushError($"Character {name} not found - file {scenePath} does not exist");
			return;
		}

		var node = packedScene.Instantiate();
		if (node is not Character character)
		{
			GD.PushError($"Scene file {scenePath} is not a Character");
			return;
		}

		CharacterLayer.AddChild(character);
		character.CharacterName = name;
		character.EnterTweened(fromPosition, toPosition, duration);
	}

	public void LeaveCharacter(string name, double distance, double duration)
	{
		CharacterLayer
			.GetChildren()
			.Cast<Character>()
			.FirstOrDefault(c => c.CharacterName == name)
			?.LeaveTweened(distance, duration);
	}
}
