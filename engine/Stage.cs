using System.Collections.Generic;
using Godot;

public partial class Stage : Node
{
	static readonly PackedScene backgroundScene = GD.Load<PackedScene>(
		"res://engine/Background.tscn"
	);

	[Export(PropertyHint.File, "*.md")]
	string timelineFilePath = "";

	[Export]
	int PreviewLineIndex
	{
		get => _previewLineIndex;
		set
		{
			if (lines.Count == 0)
			{
				_previewLineIndex = value;
				return;
			}

			_previewLineIndex = Mathf.Clamp(value, 0, lines.Count - 1);
			SeekTo(_previewLineIndex);
		}
	}
	int _previewLineIndex = 0;

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
		SeekTo(PreviewLineIndex);
	}

	void LoadTimeline()
	{
		if (timelineFilePath == "")
		{
			GD.PrintErr("Timeline file is not set");
			return;
		}

		var currentEndState = StageSnapshot.Empty;

		foreach (var sourceLine in TimelineFile.Lines(timelineFilePath))
		{
			var line = new StageLine(sourceLine, this, currentEndState);
			if (!line.IsEmpty())
			{
				lines.Add(line);
				currentEndState = line.endState;
			}
		}

		GD.PrintRich(
			$"[color=gray]Loaded timeline with [color=white]{lines.Count}[/color] lines[/color]"
		);
	}

	public override void _Process(double delta)
	{
		CurrentLine?.Process(delta);
		Dialog.AdvanceIndicatorVisible = CurrentLine?.IsPlaying() != true;
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed(InputActionName.DialogAdvance))
		{
			Advance();
		}
		if (@event.IsActionPressed(InputActionName.DialogBack))
		{
			Back();
		}
		if (@event.IsActionPressed(InputActionName.DialogNext))
		{
			Next();
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

	void Next()
	{
		if (currentLineIndex < lines.Count - 1)
		{
			currentLineIndex += 1;
		}
		if (CurrentLine is not null)
		{
			CurrentLine.Skip();
			ApplySnapshot(CurrentLine.endState);
		}
	}

	void Back()
	{
		if (currentLineIndex > 0)
		{
			currentLineIndex -= 1;
		}
		if (CurrentLine is not null)
		{
			CurrentLine.Skip();
			ApplySnapshot(CurrentLine.endState);
		}
	}

	void SeekTo(int index)
	{
		while (currentLineIndex < index)
		{
			Next();
		}
		while (currentLineIndex > index)
		{
			Back();
		}
	}

	void ApplySnapshot(StageSnapshot snapshot)
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
