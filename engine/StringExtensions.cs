using System.Text.RegularExpressions;
using Godot;

public static class StringExtensions
{
	public static string Replace(this string str, RegEx regex, string replacement) =>
		regex.Sub(str, replacement);

	public static string ReplaceAll(this string str, RegEx regex, string replacement) =>
		regex.Sub(str, replacement, true);
}
