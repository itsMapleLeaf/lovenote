using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class Stage : Node
{
	[Export]
	public double BackgroundFadeDuration = 1.0;

	public Dialog Dialog => GetNode<Dialog>("%Dialog");

	Background? background;
	Node BackgroundLayer => GetNode<Node>("%BackgroundLayer");

	readonly Dictionary<string, Character> characters = new();
	Node CharacterLayer => GetNode<Node>("%CharacterLayer");

	public override void _Ready() { }

	public void SetBackground(Texture2D texture)
	{
		background?.Leave(BackgroundFadeDuration);

		background = GD.Load<PackedScene>("res://engine/Background.tscn").Instantiate<Background>();
		BackgroundLayer.AddChild(background);
		background.Enter(texture, BackgroundFadeDuration);
	}

	public void AddCharacter(Character character)
	{
		characters.Add(character.CharacterName, character);
		CharacterLayer.AddChild(character);
	}

	public void RemoveCharacter(string name)
	{
		characters.Remove(name);
	}

	public Character? GetCharacter(string name)
	{
		return characters.TryGetValue(name, out var character) ? character : null;
	}
}
