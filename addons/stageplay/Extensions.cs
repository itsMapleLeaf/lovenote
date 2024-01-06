using System;

namespace StagePlay
{
	static class Extensions
	{
		internal static void Perform<T>(this T? subject, Action<T> action)
			where T : class
		{
			if (subject is not null)
				action(subject);
		}
	}
}
