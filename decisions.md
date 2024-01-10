# Decisions

This document details decisions to guide the development of the game.

## Goals / Wishes / Ideals

- Develop the game's script in parallel with whatever underlying systems are being coded
- The timeline scripts should be cross-compatible between changes in the underlying systems
- Reduce development overhead without sacrificing the safety of underlying systems, hopefully
- Add many warnings and sanity checks at compile time if possible, otherwise at the time of parsing the script

## GDScript vs. C#

Decision: **GDScript**

- GDScript has live updates while the game is running, + no rebuilds required for plugins
- C# support is flaky and crash-prone
- Long build times and required rebuilds to test changes
- Separate editor is basically required for C#, experience is clunky and disjointed
- Explosion of concepts leads to distractions and overthinking
- Translating Godot concepts to C# is a pain sometimes

## Timeline Data Structure: Nested vs. Flat

Decision: **Flat**

### Option 1: Directives nested in lines

```
Timeline
- Line
  - BackgroundDirective
  - WaitDirective
  - EnterDirective
  - DialogDirective
- Line
  - DialogDirective
  - WaitDirective
  - DialogDirective
```

Advantages:

- Can easily know when a line of dialog ends without any explicit signal (when the next line starts)

Disadvantages:

- Bigger when saved
- When using Godot Resources, every resource has to be a separate file, resulting in lots of files

### Option 2: Flat list of timeline events/actions/commands/etc.

```
Timeline
- BackgroundEvent
- WaitEvent
- EnterEvent
- DialogEvent
- DialogPause
- DialogEvent
- WaitEvent
- DialogEvent
```

Advantages:

- Smaller when saved
- Fewer files when using Godot Resources
- Arguably more flexible
- Easier to implement

Disadvantages:

- Need to explicitly signal when a line of dialog ends

## Directive Shape: Nullable Properties vs. Polymorphic Types

Decision: **Nullable Properties**

### Nullable properties

```gd
class Directive:
  var background: Resource
  var enter: Resource
  var dialog: String
  var wait: float
```

Advantages:

- Simple
- Significantly fewer files
- Easier to implement

Disadvantages:

- Directives can have more than one property set at a time

### Polymorphic types

```gd
class Directive:
	pass

class BackgroundDirective extends Directive:
  var background: Resource

class EnterDirective extends Directive:
  var actor: Resource

class DialogDirective extends Directive:
  var dialog: String

class WaitDirective extends Directive:
  var duration: float
```

Advantages:

- A directive can only represent a single command at a time

Disadvantages:

- Each directive type requires its own file
- GDScript doesn't have good type narrowing for instance checks

## Timeline Authoring Format

Decision: **GDScript Plugin (?)**

I'm not set on this, but it feels like the best direction so far.

### Custom editor as GDScript plugin

- ✔️ can tailor an editing experience that _could_ be nicer than in a text editor, with live preview and such
- ✔️ cannot have invalid data
- ❌ requires a lot of work to make it look and feel nice, even if just for myself

#### ...as a Godot editor plugin

- ✔️ get experience with making a GDScript plugin
- ❌ the experience of editing GDScript plugins is not that great
- ❌ Godot for UIs is mostly good, but not great

#### ...as a web app

- ✔️ I know web development really well and vibe with it
- ❌ requires a decent amount of work to make it look and feel nice, even if just for myself (but less than with a GDScript plugin)
- ❌ mismatch between web and Godot UIs can lead to bugs
- ❌ lack of code reuse and type safety

### GDScript

- ✔️ flexible: I can just Call Functions™
- ✔️ cannot have invalid data
- ❌ verbose and ugly

### Dialogic 2 / Ink

- ✔️ works, and supports a lot of features
- ❌ need to learn how to use it and deal with its quirks

### Custom markdown-like language

- ✔️ pretty and concise
- ✔️ can make it exactly how I want it
- ✔️ can easily use scripts written elsewhere
- ❌ making a language parser is hell
- ❌ language design generally is hell
- ❌ edge case city
- ❌ no real autocomplete or additional tooling support (let's be real, I'm not making that lol)
