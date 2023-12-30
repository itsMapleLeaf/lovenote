using System.Collections.Generic;
using Godot;

public partial class Stage : Node
{
	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export]
	double backgroundFadeDuration = 1.0;

	readonly List<StageLine> lines = new();
	int currentLineIndex = 0;
	Background? background;
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

	public void SetBackground(Texture2D texture)
	{
		background?.Leave(backgroundFadeDuration);

		background = GD.Load<PackedScene>("res://engine/Background.tscn").Instantiate<Background>();
		BackgroundLayer.AddChild(background);
		background.Enter(texture, backgroundFadeDuration);
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
