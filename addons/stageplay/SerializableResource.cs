using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using Godot;

public partial class SerializableResource : Resource
{
	static readonly JsonSerializerOptions s_options = new() { WriteIndented = true };

	public override string ToString() => JsonSerializer.Serialize(ToDictionary(), s_options);

	Dictionary<string, object?> ToDictionary() =>
		GetType()
			.GetProperties(BindingFlags.Instance | BindingFlags.Public)
			.Where(
				x =>
					x.PropertyType != typeof(nint)
					&& x.PropertyType != typeof(nuint)
					&& x.GetIndexParameters() is []
					&& x.CustomAttributes.Any(x => x.AttributeType.Name is nameof(ExportAttribute))
			)
			.ToDictionary(
				x => x.Name,
				x =>
				{
					var value = x.GetValue(this);
					return value switch
					{
						SerializableResource resource => resource.ToDictionary(),
						IEnumerable<SerializableResource> resources
							=> resources.Select(x => x.ToDictionary()),
						_ => value
					};
				},
				StringComparer.Ordinal
			);
}
