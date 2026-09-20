# xedit-mmskcommonlibrary

A common function library for xEdit (TES5Edit-family) scripts, targeting Skyrim Special Edition / Anniversary Edition.

It collects utility functions — validated input dialogs, record lookup, string helpers, and NPC-record checks — that tend to be duplicated across multiple xEdit scripts.

## Requirements

- xEdit (SSEEdit / TES5Edit family)
- Primarily written for and tested against Skyrim Special Edition / Anniversary Edition

xEdit scripts run on a custom scripting engine (JvInterpreter) that implements a Pascal-like syntax, but with a number of differences from standard Delphi/Pascal. This library is written with those constraints in mind:

- `out` parameters do not work correctly in xEdit (they always receive the default value), so `var` parameters are used instead wherever a value needs to be passed back
- Procedural types (passing a function as a value/callback) are not supported, which limits how far input-validation helpers below can be generalized — see the note in the Input / UI section
- Boolean expressions are not short-circuited, so `until conditionA or conditionB` always evaluates both sides
- A `repeat...until` loop that contains a bare `Break`/`Exit` statement immediately followed by another `if` statement can corrupt the parser, producing a misleading `Expression expected but '...' found` error on an unrelated, syntactically valid line. Every loop in this library avoids `Break`/`Exit` inside `repeat...until` for this reason, using `if`/`else` to skip the remaining logic instead
- Function-local `const` declarations do not behave as static constants; they act as ordinary local variables that lose their value after the function returns
- String indexing (`s[i]`) can be unreliable in some cases, so `Copy` is used instead

## Installation

1. Place `xEdit_mmskCommonLibrary/xEdit_mmskCommonLibrary.pas` under your xEdit `Edit Scripts` folder, keeping the same relative path (or any folder of your choice, as long as the `uses` clause below matches it)
2. Add a `uses` clause at the top of the script that needs it

```pascal
unit userscript;

uses 'xEdit_mmskCommonLibrary\xEdit_mmskCommonLibrary';

function Initialize: integer;
var
  prefix: string;
begin
  Result := 0;

  if not AskEditorIDPrefix('New Editor ID Prefix Input',
       'Enter the prefix. Only letters (a-z, A-Z), digits (0-9), and underscore (_) are allowed:',
       true, prefix) then begin
    MessageDlg('Cancel was pressed, aborting the script.', mtInformation, [mbOK], 0);
    Result := -1;
    Exit;
  end;

  AddMessage('Prefix set to: ' + prefix);
end;
```

## Function reference

### Input / UI

| Function | Description |
|---|---|
| `ShowCheckboxForm(options, disableOpts: TStringList; caption: string): Boolean` | Shows a checkbox selection dialog. `options` is a `TStringList` in `Name=Value` form; the selection result is written back into the same list. Any item name listed in `disableOpts` is greyed out |
| `AskInputDialog(const title, prompt: string; var resultStr: string): boolean` | A generic single-line text input dialog. Handles UI display only (auto-sizes the dialog to fit multi-line prompts); does not perform any validation. Returns `True` on OK, `False` on Cancel |
| `AskFormID(const title, prompt: string; requiredLength: integer; var resultStr: string): boolean` | Prompts for a FormID string, re-prompting automatically until the input passes `FormIDInputValidation` (and, if `requiredLength > 0`, matches that exact digit count) or the dialog is cancelled |
| `AskEditorIDPrefix(const title, prompt: string; useUnderScore: boolean; var resultStr: string): boolean` | Prompts for an EditorID-safe string, re-prompting automatically until the input passes `EditorIDInputValidation` or the dialog is cancelled |
| `GetBoolSLValue(const key: string): Boolean` | Returns `True` for `'True'` / `'1'` / `'Yes'` (case-insensitive) |

`AskFormID` and `AskEditorIDPrefix` share the same retry-loop structure (prompt → validate → re-prompt on failure) but are kept as separate functions rather than one generic helper, because xEdit's scripting engine does not support procedural types — a validation function cannot be passed in as a parameter. Any future input helper that needs its own validation rule will follow the same copy-and-adapt pattern.

### Validation

| Function | Description |
|---|---|
| `FormIDInputValidation(const s: string): Boolean` | Checks whether a string consists only of hexadecimal characters (0-9, A-F, a-f) |
| `EditorIDInputValidation(const s: string; useUnderScore: boolean): Boolean` | Checks whether a string consists only of alphanumeric characters, optionally allowing underscores |

### Record lookup / checks

| Function | Description |
|---|---|
| `FindRecordByRecordID(const recordID, signature: string; useFormID: boolean): IwbMainRecord` | Finds a record by FormID or EditorID across every currently loaded file |
| `GetLinkedMasterRecord(const sourceRecord: IInterface; const path: string): IwbMainRecord` | Resolves the element at `path`, follows its link (`LinksTo`), and returns the master record (`MasterOrSelf`) it points to. Returns `Nil` if the element itself does not exist |
| `IsOfficialMaster(fileName: string): boolean` | Checks whether a file name belongs to an official master (Bethesda ESM or Creation Club ESL) |
| `IsNPCFemale(npc: IInterface): boolean` | Checks the Female flag on an NPC record |
| `IsNPCUsingTraits(npc: IInterface): boolean` | Checks whether an NPC record has the "Use Traits" template flag set |

### String helpers

| Function | Description |
|---|---|
| `ExtractLocalFormIDHex(const fullFormIDHex: string): string` | Extracts the file-local portion of an 8-digit hex FormID string, accounting for the ESL/ESPFE prefix (`FE`). Leading zeros are preserved — combine with `RemoveLeadingZeros` if needed |
| `RemoveLeadingZeros(const s: string): string` | Strips leading `'0'` characters (returns a single `'0'` if the string is all zeros) |
| `PadLeftZero(const s: string; targetLength: Integer): string` | Pads a string with leading `'0'` characters up to the given length |
| `CreateSLValueFromRecordID(const editorID, formID, fileName: string): string` | Builds a `EditorID=FormID=xxx;FileName=yyy` style string, meant to be stored as one entry in a `TStringList` |
| `CreateSLValueFromRecordIDWithName(const editorID, formID, fileName, NPCName: string): string` | Same as above, with an additional NPC name field |
| `ExtractStringListValue(const valueString: string; const key: string): string` | Extracts the value for `key` from a string built with the two functions above |

## Distribution

- [Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/192332)

## License

MPL-2.0. See `LICENSE`.

## Author

mmsk4989

---

This README was generated with Claude.
