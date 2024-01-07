using System;

namespace StagePlay
{
	static class Extensions
	{
		internal static Out? Perform<In, Out>(this In? subject, Func<In, Out> func)
			where In : class
		{
			return subject is not null ? func(subject) : default;
		}
	}
}
