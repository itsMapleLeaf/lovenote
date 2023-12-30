using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class Stage : Node
{
	static readonly PackedScene backgroundScene = GD.Load<PackedScene>(
		"res://engine/Background.tscn"
	);

	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export]
	double backgroundFadeDuration = 1.0;

	readonly List<StageLine> lines = new();
	int currentLineIndex = 0;
	readonly Dictionary<string, Background> backgrounds = new();
	readonly Dictionary<string, Character> characters = new();

	StageLine? CurrentLine => currentLineIndex < lines.Count ? lines[currentLineIndex] : null;

	Node? _backgroundLayer;
	Node BackgroundLayer => _backgroundLayer ??= GetNode<Node>("%BackgroundLayer");

	Node? _characterLayer;
	Node CharacterLayer => _characterLayer ??= GetNode<Node>("%CharacterLayer");

	Dialog? _dialog;
	public Dialog Dialog => _dialog ??= GetNode<Dialog>("%Dialog");

	Control? _inputCover;
	Control InputCover => _inputCover ??= GetNode<Control>("%InputCover");

	public override void _Ready()
	{
		LoadTimeline();
		InputCover.GuiInput += _UnhandledInput;
		CurrentLine?.Reset();
	}

	void LoadTimeline()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file is not set");
			return;
		}

		foreach (var sourceLine in new TimelineFile(timelineFilePath).Lines())
		{
			var line = new StageLine(sourceLine, this);
			if (!line.IsEmpty())
			{
				lines.Add(line);
			}
		}
	}

	public override void _Process(double delta)
	{
		CurrentLine?.Process(delta);
		Dialog.AdvanceIndicatorVisible = CurrentLine?.IsPlaying() != true;
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed("dialog_advance"))
		{
			Advance();
		}
	}

	void Advance()
	{
		if (CurrentLine?.IsPlaying() == true)
		{
			CurrentLine?.Skip();
		}
		else if (currentLineIndex < lines.Count - 1)
		{
			currentLineIndex += 1;
			CurrentLine?.Reset();
		}
	}

	public void AddBackground(string name, Texture2D texture)
	{
		if (backgrounds.ContainsKey(name))
		{
			return;
		}

		var background = backgroundScene.Instantiate<Background>();
		background.Name = name;
		background.Texture = texture;
		backgrounds.Add(name, background);
		BackgroundLayer.AddChild(background);
	}

	public void ShowBackground(string name)
	{
		foreach (var (backgroundName, background) in backgrounds)
		{
			if (backgroundName == name)
			{
				background.FadeIn();
			}
			else
			{
				background.FadeOut();
			}
		}
	}

	public void AddCharacter(Character character)
	{
		characters.Add(character.CharacterName, character);
		CharacterLayer.AddChild(character);
	}

	public Character? GetCharacter(string name)
	{
		return characters.TryGetValue(name, out var character) ? character : null;
	}
}
