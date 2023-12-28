using System;
using Godot;

public partial class Dialog : Control
{
	[Export]
	public string Speaker = "";

	[Export]
	public string Text = "";

	[Export]
	public bool AdvanceIndicatorVisible = false;

	[Export]
	public int RevealSpeed = 50;

	private double visibleCharacters = 0.0f;

	private static readonly RegEx extraSpaces = RegEx.CreateFromString(@"\s{2,}");

	public void Reset()
	{
		Speaker = "";
		Text = "";
		visibleCharacters = 0;
	}

	public void Skip()
	{
		visibleCharacters = Text.Length;
	}

	public bool IsPlaying()
	{
		return visibleCharacters < Text.Length;
	}

	public override void _Process(double delta)
	{
		if (visibleCharacters < Text.Length)
		{
			visibleCharacters = Mathf.MoveToward(
				visibleCharacters,
				Text.Length,
				RevealSpeed * delta
			);
		}
		else
		{
			visibleCharacters = Text.Length;
		}

		Visible = Text != "";

		var speakerPanel = GetNode<PanelContainer>("%SpeakerPanel");
		speakerPanel.Visible = Speaker != "";

		var speakerLabel = GetNode<Label>("%SpeakerLabel");
		speakerLabel.Text = Speaker;

		var dialogLabel = GetNode<RichTextLabel>("%DialogLabel");
		dialogLabel.Text = extraSpaces.Sub(Text.StripEdges(), " ", true);
		dialogLabel.VisibleCharacters = (int)Math.Ceiling(visibleCharacters);

		var advanceIndicator = GetNode<Control>("%AdvanceIndicator");
		advanceIndicator.Visible = AdvanceIndicatorVisible;
	}
}
