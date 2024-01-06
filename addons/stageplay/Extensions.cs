using System;

namespace StagePlay
{
	public static class Extensions
	{
		public static void Perform<T>(this T? subject, Action<T> action)
			where T : class
		{
			if (subject is not null)
				action(subject);
		}
	}
}
