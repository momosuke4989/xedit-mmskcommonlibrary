unit xEdit_mmskCommonLibrary;

interface

function GetBoolSLValue(const key: string): Boolean;
function ShowCheckboxForm(const options, disableOpts: TStringList; caption: string): Boolean;
function FormIDInputValidation(const s: string): Boolean;
function EditorIDInputValidation(const s: string; useUnderScore: boolean): Boolean;
function IsOfficialMaster(fileName: string): boolean;
function ExtractLocalFormIDHex(const fullFormIDHex: string): string;
function RemoveLeadingZeros(const s: string): string;
function PadLeftZero(const s: string; targetLength: Integer): string;
function FindRecordByRecordID(const recordID, signature: string; useFormID: boolean): IwbMainRecord;
function CreateSLValueFromRecordID(const editorID, formID, fileName: string): string;
function CreateSLValueFromRecordIDWithName(const editorID, formID, fileName, NPCName: string): string;
function ExtractStringListValue(const valueString: string; const key: string): string;
function IsNPCFemale(npc: IInterface): boolean;
function IsNPCUsingTraits(npc: IInterface): boolean;
function GetLinkedMasterRecord(const sourceRecord: IInterface; const path: string): IwbMainRecord;

implementation

function GetBoolSLValue(const s: string): Boolean;
var
  value: string;
begin
  value := LowerCase(s);
  Result := (value = 'true') or (value = '1') or (value = 'yes');
end;

function CreateSLValueFromRecordID(const editorID, formID, fileName: string): string;
begin
  // EditorIDをName、FormIDとFileNameをValueとして登録
  // 各値の読み出しはExtractStringListValue関数を利用する
  Result := editorID + '=FormID=' + formID + ';FileName=' + fileName;
end;

function CreateSLValueFromRecordIDWithName(const editorID, formID, fileName, NPCName: string): string;
begin
  // EditorIDをName、FormIDとFileNameをValueとして登録
  // 各値の読み出しはExtractStringListValue関数を利用する
  Result := editorID + '=FormID=' + formID + ';FileName=' + fileName + ';NPCName=' + NPCName;
end;

function ExtractStringListValue(const valueString: string; const key: string): string;
var
  searchStr: string;
  startPos, endPos: Integer;
begin
  Result := '';

  // "Key="形式で検索
  searchStr := key + '=';
  startPos := Pos(searchStr, valueString);

  if startPos = 0 then Exit;

  // 値の開始位置
  startPos := startPos + Length(searchStr);

  // 次の;を探す（値の終わり）
  endPos := Pos(';', Copy(valueString, startPos, Length(valueString)));

  if endPos > 0 then
    // ;が見つかった場合、そこまでを取得
    Result := Copy(valueString, startPos, endPos - 1)
  else
    // ;が見つからない場合、最後まで取得
    Result := Copy(valueString, startPos, Length(valueString));
end;

function ShowCheckboxForm(const options, disableOpts: TStringList; caption: string): Boolean;
var
  form: TForm;
  checklist: TCheckListBox;
  btnOK, btnCancel: TButton;
  i: Integer;
  shouldDisable: Boolean;
begin
  Result := False;

  // デバッグ: 入力内容を確認
{  AddMessage('=== Debug Info ===');
  AddMessage('Options count: ' + IntToStr(options.Count));
  AddMessage('DisableOpts count: ' + IntToStr(disableOpts.Count));
}
  form := TForm.Create(nil);
  try
    form.Caption := caption;
    form.Width := 350;
    form.Height := 300;
    form.Position := poScreenCenter;

    checklist := TCheckListBox.Create(form);
    checklist.Parent := form;
    checklist.Align := alTop;
    checklist.Height := 200;

    for i := 0 to options.Count - 1 do begin
      checklist.Items.Add(options.Names[i]);

      shouldDisable := false;

      // このオプションを無効化すべきか判定
      shouldDisable := (disableOpts.Count > 0) and (disableOpts.IndexOf(options.Names[i]) >= 0);

      // デバッグ: 各項目の判定結果
{      AddMessage('Item ' + IntToStr(i) + ': ' + options.ValueFromIndex[i]);

      if shouldCheck then
        AddMessage('  shouldCheck: True')
      else
        AddMessage('  shouldCheck: False');

      if shouldDisable then
        AddMessage('  shouldDisable: True')
      else
        AddMessage('  shouldDisable: False');
}

      // このオプションをチェックすべきか判定
      if GetBoolSLValue(options.ValueFromIndex[i]) then
        checklist.Checked[i] := true;

      // 注意：ItemEnabledはtrue:無効化、false:有効化となる
      // 一般的な論理イメージと逆転している。
      if shouldDisable then begin
        checklist.Checked[i] := false;
        checklist.ItemEnabled[i] := true;
      end;

    end;

    btnOK := TButton.Create(form);
    btnOK.Parent := form;
    btnOK.Caption := 'OK';
    btnOK.ModalResult := mrOk;
    btnOK.Width := 75;
    btnOK.Top := checklist.Top + checklist.Height + 10;
    btnOK.Left := (form.ClientWidth div 2) - btnOK.Width - 10;

    btnCancel := TButton.Create(form);
    btnCancel.Parent := form;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Width := 75;
    btnCancel.Top := btnOK.Top;
    btnCancel.Left := (form.ClientWidth div 2) + 10;

    form.BorderStyle := bsDialog;
    form.Position := poScreenCenter;

    if form.ShowModal = mrOk then
    begin
      Result := True;
      for i := 0 to checklist.Items.Count - 1 do
        if checklist.Checked[i] then
          options.ValueFromIndex[i] := 'True'
        else
          options.ValueFromIndex[i] := 'False';
    end;
  finally
    form.Free;
  end;
end;

function FormIDInputValidation(const s: string): Boolean;
var
  i: Integer;
  ch: Char;
begin
  Result := true;
  for i := 1 to Length(s) do
  begin
    ch := s[i];
    if not ((ch >= 'A') and (ch <= 'F') or
            (ch >= 'a') and (ch <= 'f') or
            (ch >= '0') and (ch <= '9')) then
    begin
      Result := false;
      Break;
    end;
  end;
end;


function EditorIDInputValidation(const s: string; useUnderScore: boolean): Boolean;
var
  i: Integer;
  ch: Char;
begin
  Result := true;
  for i := 1 to Length(s) do
  begin
    ch := s[i];
    if useUnderScore then begin
      if not ((ch >= 'A') and (ch <= 'Z') or
              (ch >= 'a') and (ch <= 'z') or
              (ch >= '0') and (ch <= '9') or
              (ch = '_')) then
      begin
        Result := false;
        Break;
      end;
    end
    else begin
      if not ((ch >= 'A') and (ch <= 'Z') or
              (ch >= 'a') and (ch <= 'z') or
              (ch >= '0') and (ch <= '9')) then
      begin
        Result := false;
        Break;
      end;
    end;
  end;
end;

function IsOfficialMaster(fileName: string): boolean;
begin
  Result :=
    SameText(fileName, 'Skyrim.esm') or
    SameText(fileName, 'Update.esm') or
    SameText(fileName, 'Dawnguard.esm') or
    SameText(fileName, 'HearthFires.esm') or
    SameText(fileName, 'Dragonborn.esm') or
    SameText(fileName, '_ResourcePack.esl') or
    SameText(fileName, 'ccBGSSSE001-Fish.esm') or
    SameText(fileName, 'ccBGSSSE025-AdvDSGS.esm')or
    SameText(fileName, 'ccBGSSSE037-Curios.esl') or
    SameText(fileName, 'ccQDRSSE001-SurvivalMode.esl');
end;

// フルFormID(8桁hex文字列。先頭2桁はロードオーダーindexまたはFEフラグ)から、
// ファイル内ローカルなFormID部分(ゼロ詰めのまま)を抽出する
// ESL/ESPFEフラグ付き(先頭2桁が'FE')の場合は下3桁を、通常のESP/ESMの場合は下6桁を返す
// 先頭ゼロの除去が必要な場合は別途RemoveLeadingZerosを呼ぶこと
function ExtractLocalFormIDHex(const fullFormIDHex: string): string;
begin
  if UpperCase(Copy(fullFormIDHex, 1, 2)) = 'FE' then
    Result := Copy(fullFormIDHex, 6, 8)
  else
    Result := Copy(fullFormIDHex, 3, 8);
end;

function RemoveLeadingZeros(const s: string): string;
var
  i: Integer;
begin
  i := 1;
  // 先頭の '0' をスキップ
  while (i <= Length(s)) and (Copy(s, i, 1) = '0') do
    Inc(i);
  // すべてが '0' の場合は '0' を返す
  if i > Length(s) then
    Result := '0'
  else
    Result := Copy(s, i, Length(s) - i + 1);
end;

function PadLeftZero(const s: string; targetLength: Integer): string;
var
  padded: string;
begin
  padded := s;
  while Length(padded) < targetLength do
    padded := '0' + padded;
  Result := padded;
end;

function FindRecordByRecordID(const recordID, signature: string; useFormID: boolean): IwbMainRecord;
var
  formID, i: cardinal;
  editorID: string;
  f:  IwbFile;
  rec: IwbMainRecord;
  npcRecordGroup: IwbGroupRecord;
begin
  Result := nil;

  if useFormID then begin
    // StrToIntでは負数になってしまうので、StrToInt64で変換し、Cardinal型で受け取る。
    formID := StrToInt64('$' + recordID);
  //  AddMessage('Converted Form ID: ' + IntToStr(formID));
  end
  else
    editorID := recordID;

  // 0始まりに加えて、Skyrim.exeの分も足してループ回数を減らす。
  for i := 0 to FileCount - 2 do begin
    f := FileByLoadOrder(i);
//    AddMessage('Searching file name: ' + GetFileName(f));
    if useFormID then begin
      rec := RecordByFormID(f, formID, True);
  //    AddMessage('Record Form ID: ' + IntToStr(GetLoadOrderFormID(rec)));
      // Form IDを取得する関数はいくつかあるが、ロードオーダーを含めたForm IDを取得できるのはGetLoadOrderFormID
      if Assigned(rec) and (GetLoadOrderFormID(rec) = formID) then begin
        AddMessage('Record is found by Form ID');
        if (Signature(rec) = signature) then begin
          AddMessage('Record signature is correct.');
          Result := rec;
        end
        else
          AddMessage('Record signature is incorrect.');
        break;
      end;
    end
    else begin
      npcRecordGroup := GroupBySignature(f, signature);
      rec := MainRecordByEditorID(npcRecordGroup, editorID);
      if Assigned(rec) then begin
        AddMessage('Record is found by Editor ID');
        if (Signature(rec) = signature)  then begin
          AddMessage('Record signature is correct.');
          Result := rec;
        end
        else
          AddMessage('Record signature is incorrect.');
        break;
      end;
    end;
  end;
  if Assigned(Result) then
    AddMessage('Target Record is found')
  else
    AddMessage('No target record found for the entered ID. Check the entered ID is correct and target file is loaded.');

end;

function IsNPCFemale(npc: IInterface): boolean;
var
  npcFlags: IInterface;
begin
  Result := False;
  if Assigned(npc) then begin
    npcFlags := ElementByPath(npc, 'ACBS - Configuration');
    if GetElementEditValues(npcFlags, 'Flags\Female') = 1 then
      Result := True;
  end;
end;

function IsNPCUsingTraits(npc: IInterface): boolean;
var
  templateFlags: IInterface;
begin
  Result := False;
  if Assigned(npc) then begin
    templateFlags := ElementByPath(npc, 'ACBS - Configuration\Template Flags');
    if Assigned(templateFlags) then
      if GetElementNativeValues(templateFlags, 'Use Traits') <> 0 then
        Result := True;
  end;
end;

// 指定パスの要素が参照するリンク先のマスターレコードを取得する
// 参照が設定されていない、またはオーバーライドの場合はマスターレコードを返す
// 要素自体が存在しない場合はNilを返す
function GetLinkedMasterRecord(const sourceRecord: IInterface; const path: string): IwbMainRecord;
var
  elem: IInterface;
begin
  Result := nil;
  elem := ElementByPath(sourceRecord, path);
  if not Assigned(elem) then
    Exit;
  Result := MasterOrSelf(LinksTo(elem));
end;

end.
