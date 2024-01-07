using System.Text.Json;

namespace StagePlay
{
	static class ModuleInitializer
	{
		// workaround https://github.com/godotengine/godot/issues/78513#issuecomment-1625004361
#pragma warning disable CA2255 // The 'ModuleInitializer' attribute should not be used in libraries
		[System.Runtime.CompilerServices.ModuleInitializer]
#pragma warning restore CA2255 // The 'ModuleInitializer' attribute should not be used in libraries
		internal static void Initialize()
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
