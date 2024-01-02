using System.Collections.Generic;
using Godot;

public partial class Stage : Node
{
	#region Backgrounds
	static readonly PackedScene backgroundScene = GD.Load<PackedScene>(
		"res://engine/Background.tscn"
	);

	readonly Dictionary<string, Background> backgrounds = new();

	Node? _backgroundLayer;
	Node BackgroundLayer => _backgroundLayer ??= GetNode<Node>("%BackgroundLayer");

	public void AddBackground(string name, Texture2D texture)
	{
		if (backgrounds.ContainsKey(name))
		{
			return;
		}

		var background = backgroundScene.Instantiate<Background>();
		background.Name = name;
		// background.Texture = texture;
		backgrounds.Add(name, background);
		BackgroundLayer.AddChild(background);
	}

	public void ShowBackground(string? name, double fadeDuration = 1.0)
	{
		foreach (var (backgroundName, background) in backgrounds)
		{
			if (backgroundName == name)
			{
				background.FadeIn(fadeDuration);
			}
			else
			{
				background.FadeOut(fadeDuration);
			}
		}
	}
	#endregion

	#region Characters
	readonly Dictionary<string, Character> characters = new();

	Node? _characterLayer;
	Node CharacterLayer => _characterLayer ??= GetNode<Node>("%CharacterLayer");

	public (Character? character, string? error) AddCharacter(string characterName)
	{
		if (characters.TryGetValue(characterName, out Character? value))
		{
			return (value, null);
		}

		var scenePath = $"res://content/characters/{characterName}.tscn";
		if (!ResourceLoader.Exists(scenePath))
		{
			return (null, $"Resource path {scenePath} does not exist");
		}

		var node = GD.Load<PackedScene>(scenePath).Instantiate();
		if (node is not Character character)
		{
			return (null, $"Resource path {scenePath} is not a valid character");
		}

		character.CharacterName = characterName;
		characters.Add(characterName, character);
		CharacterLayer.AddChild(character);

		return (character, "");
	}

	public Character? GetCharacter(string name)
	{
		return characters.TryGetValue(name, out var character) ? character : null;
	}
	#endregion

	Dialog? _dialog;
	public Dialog Dialog => _dialog ??= GetNode<Dialog>("%Dialog");

	public void ApplySnapshot(StageSnapshot snapshot)
	{
		Dialog.Speaker = snapshot.DialogSpeaker;
		Dialog.Text = snapshot.DialogText;
		Dialog.Skip();

		ShowBackground(snapshot.Background, 0);

		foreach (var (name, character) in characters)
		{
			if (snapshot.Characters.ContainsKey(name))
			{
				character.StagePosition = snapshot.Characters[name].position;
				character.FadeIn(0);
			}
			else
			{
				character.FadeOut(0);
			}
		}
	}
}
