using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

namespace StagePlay
{
	public record Timeline(IEnumerable<StageLine> Lines)
	{
		readonly JsonSerializerOptions jsonSerializerOptions = new() { WriteIndented = true };

		public byte[] Serialize() =>
			JsonSerializer.SerializeToUtf8Bytes(this, jsonSerializerOptions);

		public static Timeline? FromSerialized(byte[] serialized)
		{
			try
			{
				return JsonSerializer.Deserialize<Timeline>(serialized);
			}
			catch (JsonException e)
			{
				GD.PushError($"Error parsing file: {e.Message}");
				return null;
			}
		}

		public void Save(string path)
		{
			var file = FileAccess.Open(path, FileAccess.ModeFlags.Write);
			if (file is null)
			{
				var error = FileAccess.GetOpenError();
				GD.PushError($"Error opening file: {error}");
				return;
			}
			try
			{
				file.StoreBuffer(Serialize());
			}
			finally
			{
				file.Close();
			}
		}

		public static Timeline? FromFile(string path)
		{
			var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);
			if (file is null)
			{
				var error = FileAccess.GetOpenError();
				GD.PushError($"Error opening file: {error}");
				return null;
			}

			var content = FileAccess.GetFileAsBytes(path);
			if (content.IsEmpty())
			{
				GD.PushError("File is empty");
				return null;
			}

			return FromSerialized(content);
		}

		public static Timeline Mock()
		{
			return new(
				[
					new("Ryder", new DialogDirective("What's it like to die?")),
					new(
						"Reina",
						// new DialogSpeedDirective(0.1),
						// new DialogDirective("..."),
						// new WaitDirective(1),
						new DialogDirective("Ryder, what?")
					),
					new("Ryder", new DialogDirective("I'm just curious.")),
				]
			);
		}
	}

	public record StageLine
	{
		public string Speaker { get; set; }
		public IEnumerable<IDirective> Directives { get; set; }

		[JsonConstructor]
		public StageLine(string speaker, IEnumerable<IDirective> directives)
		{
			Speaker = speaker;
			Directives = directives;
		}

		public StageLine(string speaker, params IDirective[] directives)
			: this(speaker, directives.AsEnumerable()) { }

		public StageLine(IEnumerable<IDirective> directives)
			: this("", directives) { }

		public StageLine(params IDirective[] directives)
			: this(directives.AsEnumerable()) { }
	}

	[
		JsonDerivedType(typeof(DialogDirective), "Dialog"),
		JsonDerivedType(typeof(DialogSpeedDirective), "DialogSpeed"),
		JsonDerivedType(typeof(WaitDirective), "Wait"),
		JsonDerivedType(typeof(ActorDirective), "Actor")
	]
	public interface IDirective
	{
		internal IDirectiveEditor CreateEditor();
	}

	public record DialogDirective(string Text) : IDirective
	{
		public IDirectiveEditor CreateEditor() => DialogDirectiveEditor.Create(Text);
	}

	public record DialogSpeedDirective(double Speed) : IDirective
	{
		IDirectiveEditor IDirective.CreateEditor()
		{
			throw new System.NotImplementedException();
		}
	}

	public record WaitDirective(double Duration) : IDirective
	{
		IDirectiveEditor IDirective.CreateEditor()
		{
			throw new System.NotImplementedException();
		}
	}

	public record ActorDirective : IDirective
	{
		public required string ActorName { get; set; }
		public double? Position { get; set; }
		public double? Rotation { get; set; }
		public double? Scale { get; set; }
		public double? Opacity { get; set; }
		public double Duration { get; set; } = 0;

		IDirectiveEditor IDirective.CreateEditor()
		{
			throw new System.NotImplementedException();
		}
	}

	public static class ModuleInitializer
	{
		// workaround https://github.com/godotengine/godot/issues/78513#issuecomment-1625004361
#pragma warning disable CA2255 // The 'ModuleInitializer' attribute should not be used in libraries
		[System.Runtime.CompilerServices.ModuleInitializer]
#pragma warning restore CA2255 // The 'ModuleInitializer' attribute should not be used in libraries
		public static void Initialize()
		{
			System
				.Runtime.Loader.AssemblyLoadContext.GetLoadContext(
					System.Reflection.Assembly.GetExecutingAssembly()
				)!
				.Unloading += alc =>
			{
				var assembly = typeof(JsonSerializerOptions).Assembly;
				var updateHandlerType = assembly.GetType(
					"System.Text.Json.JsonSerializerOptionsUpdateHandler"
				);
				var clearCacheMethod = updateHandlerType?.GetMethod(
					"ClearCache",
					System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.Public
				);
				clearCacheMethod?.Invoke(null, [null]);

				// Unload any other unloadable references
			};
		}
	}
}
