#if TOOLS
using System;
using Godot;

namespace StagePlay
{
	[Tool]
	public partial class Plugin : EditorPlugin
	{
		Control? mainPanelNode;

		public override string _GetPluginName()
		{
			return "StagePlay";
		}

		public override Texture2D _GetPluginIcon()
		{
			return EditorInterface
				.Singleton.GetEditorTheme()
				.GetIcon("AnimationMixer", "EditorIcons");
		}

		public override bool _HasMainScreen()
		{
			return true;
		}

		public override void _EnterTree()
		{
			mainPanelNode = GD.Load<PackedScene>("res://addons/stageplay/Editor.tscn")
				.Instantiate<Control>();
			EditorInterface.Singleton.GetEditorMainScreen().AddChild(mainPanelNode);
			_MakeVisible(false);
		}

		public override void _ExitTree()
		{
			mainPanelNode?.QueueFree();
			mainPanelNode = null;
		}

		public override void _MakeVisible(bool visible)
		{
			if (mainPanelNode == null)
			{
				return;
			}

			mainPanelNode.Visible = visible;
		}
	}
}
#endif
