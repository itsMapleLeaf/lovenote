using System;
using Godot;

public partial class Dialog : Control
{
	private static readonly RegEx extraSpaces = RegEx.CreateFromString(@"\s{2,}");

	PanelContainer? _speakerPanel;
	PanelContainer SpeakerPanel => _speakerPanel ??= GetNode<PanelContainer>("%SpeakerPanel");

	Label? _speakerLabel;
	Label SpeakerLabel => _speakerLabel ??= GetNode<Label>("%SpeakerLabel");

	RichTextLabel? _dialogLabel;
	RichTextLabel DialogLabel => _dialogLabel ??= GetNode<RichTextLabel>("%DialogLabel");

	Control? _advanceIndicator;
	Control AdvanceIndicator => _advanceIndicator ??= GetNode<Control>("%AdvanceIndicator");

	[Export]
	public string Speaker
	{
		get => SpeakerLabel.Text;
		set
		{
			SpeakerLabel.Text = value;
			SpeakerPanel.Visible = value != "";
		}
	}

	[Export]
	public string Text
	{
		get => DialogLabel.Text;
		set
		{
			DialogLabel.Text = extraSpaces.Sub(value, " ", all: true).Trim();
			Visible = value != "";
		}
	}

	[Export]
	public bool AdvanceIndicatorVisible
	{
		get => AdvanceIndicator.Visible;
		set => AdvanceIndicator.Visible = value;
	}

	[Export]
	public int RevealSpeed = 50;

	Tween? tween;

	public void Clear()
	{
		Speaker = "";
		Text = "";
	}

	public Tween PlayText(string text)
	{
		var currentLength = Text.Length;
		Text += " " + text;
		var targetLength = Text.Length;

		DialogLabel.VisibleCharacters = currentLength;

		tween = CreateTween();
		tween.TweenProperty(
			DialogLabel,
			RichTextLabel.PropertyName.VisibleCharacters.ToString(),
			targetLength,
			(targetLength - currentLength) / (double)RevealSpeed
		);

		return tween;
	}

	public void Skip()
	{
		tween?.Kill();
		DialogLabel.VisibleCharacters = Text.Length;
	}
}
