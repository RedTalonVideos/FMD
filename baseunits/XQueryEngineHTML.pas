unit XQueryEngineHTML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, xquery, xquery_json, simplehtmltreeparser;

type

  { TXQueryEngineHTML }

  TXQueryEngineHTML = class
  private
    FEngine: TXQueryEngine;
    FTreeParser: TTreeParser;
    function Eval(const Expression: String; const isCSS: Boolean = False;
      const ContextItem: IXQValue = nil; const Tree: TTreeNode = nil): IXQValue;
    function EvalStringAll(const Expression: String; const isCSS: Boolean;
      const Separator: String = ', '; const ContextItem: IXQValue = nil): String; overload;
    function EvalStringAll(const Expression: String; const isCSS: Boolean;
      const Exc: array of String; const Separator: String = ', ';
      const ContextItem: IXQValue = nil): String; overload;
    procedure EvalStringAll(const Expression: String; const isCSS: Boolean;
      const TheStrings: TStrings; ContextItem: IXQValue = nil); overload;
  public
    constructor Create(const HTML: String = ''); overload;
    constructor Create(const HTMLStream: TStream); overload;
    destructor Destroy; override;
    procedure ParseHTML(const HTML: String); overload;
    procedure ParseHTML(const HTMLStream: TStream); overload;
    // xpath
    function XPath(const Expression: String; const Tree: TTreeNode = nil): IXQValue; inline;
    function XPath(const Expression: String; const ContextItem: IXQValue): IXQValue; inline;
    function XPathString(const Expression: String; const Tree: TTreeNode = nil): String; inline;
    function XPathString(const Expression: String; const ContextItem: IXQValue): String; inline;
    function XPathStringAll(const Expression: String; const Separator: String = ', ';
      const ContextItem: IXQValue = nil): String; overload; inline;
    function XPathStringAll(const Expression: String; const Exc: array of String;
      const Separator: String = ', '; const ContextItem: IXQValue = nil): String; overload; inline;
    procedure XPathStringAll(const Expression: String; const TheStrings: TStrings;
      const ContextItem: IXQValue = nil); overload; inline;
    // css
    function CSS(const Expression: String; const Tree: TTreeNode = nil): IXQValue; inline;
    function CSS(const Expression: String; const ContextItem: IXQValue): IXQValue; inline;
    function CSSString(const Expression: String; const Tree: TTreeNode = nil): String; inline;
    function CSSString(const Expression: String; const ContextItem: IXQValue): String; inline;
    function CSSStringAll(const Expression: String; const Separator: String = ', ';
      const ContextItem: IXQValue = nil): String; overload; inline;
    function CSSStringAll(const Expression: String; const Exc: array of String;
      const Separator: String = ', '; const ContextItem: IXQValue = nil): String; overload; inline;
    procedure CSSStringAll(const Expression: String; const TheStrings: TStrings;
      const ContextItem: IXQValue = nil); overload; inline;

    property Engine: TXQueryEngine read FEngine;
    property TreeParser: TTreeParser read FTreeParser;
  end;

  IXQValue = xquery.IXQValue;
  TTreeNode = simplehtmltreeparser.TTreeNode;

function XPathString(const Expression, HTMLString: String): String; overload;
function XPathString(const Expression: String; const HTMLStream: TStream): String; overload;

implementation

function StreamToString(const Stream: TStream): String;
var
  p, x: Int64;
begin
  p := Stream.Position;
  Stream.Position := 0;
  Setlength(Result, Stream.Size);
  x := Stream.Read(PChar(Result)^, Stream.Size);
  SetLength(Result, x);
  Stream.Position := p;
end;

procedure AddSeparatorString(var Dest: String; const S: String; const Separator: String = ', ');
begin
  if Trim(S) <> '' then
    if Trim(Dest) = '' then
      Dest := Trim(S)
    else
      Dest := Trim(Dest) + Separator + Trim(S);
end;

function StringInArray(const S: String; const SS: array of String): Boolean;
var
  i: Integer;
begin
  Result := True;
  if Length(SS) > 0 then
    for i := Low(SS) to High(SS) do
      if SameText(S, SS[i]) then
        Exit;
  Result := False;
end;

function XPathString(const Expression, HTMLString: String): String;
begin
  Result := '';
  with TXQueryEngineHTML.Create(HTMLString) do
    try
      Result := XPath(Expression).toString;
    finally
      Free;
    end;
end;

function XPathString(const Expression: String; const HTMLStream: TStream): String;
begin
  Result := XPathString(Expression, StreamToString(HTMLStream));
end;

{ TXQueryEngineHTML }

function TXQueryEngineHTML.Eval(const Expression: String; const isCSS: Boolean;
  const ContextItem: IXQValue; const Tree: TTreeNode): IXQValue;
begin
  Result := xqvalue();
  try
    if Assigned(ContextItem) then
    begin
      if isCSS then
        Result := FEngine.evaluateCSS3(Expression, ContextItem)
      else
        Result := FEngine.evaluateXPath3(Expression, ContextItem);
    end
    else if Assigned(Tree) then
    begin
      if isCSS then
        Result := FEngine.evaluateCSS3(Expression, Tree)
      else
        Result := FEngine.evaluateXPath3(Expression, Tree);
    end
    else
    begin
      if isCSS then
        Result := FEngine.evaluateCSS3(Expression, FTreeParser.getLastTree)
      else
        Result := FEngine.evaluateXPath3(Expression, FTreeParser.getLastTree);
    end;
  except
  end;
end;

function TXQueryEngineHTML.EvalStringAll(const Expression: String; const isCSS: Boolean;
  const Separator: String; const ContextItem: IXQValue): String;
var
  v: IXQValue;
begin
  Result := '';
  for v in Eval(Expression, isCSS, ContextItem) do
    AddSeparatorString(Result, v.toString, Separator);
end;

function TXQueryEngineHTML.EvalStringAll(const Expression: String; const isCSS: Boolean;
  const Exc: array of String; const Separator: String; const ContextItem: IXQValue
  ): String;
var
  v: IXQValue;
begin
  Result := '';
  for v in Eval(Expression, isCSS, ContextItem) do
    if StringInArray(Trim(v.toString), Exc) = False then
      AddSeparatorString(Result, v.toString, Separator);
end;

procedure TXQueryEngineHTML.EvalStringAll(const Expression: String; const isCSS: Boolean;
  const TheStrings: TStrings; ContextItem: IXQValue);
var
  v: IXQValue;
begin
  for v in Eval(Expression, isCSS, ContextItem) do
    TheStrings.Add(v.toString);
end;

constructor TXQueryEngineHTML.Create(const HTML: String);
begin
  FEngine := TXQueryEngine.Create;
  FTreeParser := TTreeParser.Create;
  with FTreeParser do
  begin
    parsingModel := pmHTML;
    repairMissingStartTags := True;
    repairMissingEndTags := True;
    trimText := False;
    readComments := False;
    readProcessingInstructions := False;
    autoDetectHTMLEncoding := False;
    if HTML <> '' then
      parseTree(HTML);
  end;
end;

constructor TXQueryEngineHTML.Create(const HTMLStream: TStream);
begin
  if Assigned(HTMLStream) then
    Create(StreamToString(HTMLStream))
  else
    Create('');
end;

destructor TXQueryEngineHTML.Destroy;
begin
  FEngine.Free;
  FTreeParser.Free;
  inherited Destroy;
end;

procedure TXQueryEngineHTML.ParseHTML(const HTML: String);
begin
  if HTML <> '' then
    FTreeParser.parseTree(HTML);
end;

procedure TXQueryEngineHTML.ParseHTML(const HTMLStream: TStream);
begin
  ParseHTML(StreamToString(HTMLStream));
end;

function TXQueryEngineHTML.XPath(const Expression: String; const Tree: TTreeNode): IXQValue;
begin
  Result := Eval(Expression, False, nil, Tree);
end;

function TXQueryEngineHTML.XPath(const Expression: String; const ContextItem: IXQValue
  ): IXQValue;
begin
  Result := Eval(Expression, False, ContextItem);
end;

function TXQueryEngineHTML.XPathString(const Expression: String; const Tree: TTreeNode): String;
begin
  Result := Eval(Expression, False, nil, Tree).toString;
end;

function TXQueryEngineHTML.XPathString(const Expression: String;
  const ContextItem: IXQValue): String;
begin
  Result := Eval(Expression, False, ContextItem).toString;
end;

function TXQueryEngineHTML.XPathStringAll(const Expression: String;
  const Separator: String; const ContextItem: IXQValue): String;
begin
  Result := EvalStringAll(Expression, False, Separator, ContextItem);
end;

function TXQueryEngineHTML.XPathStringAll(const Expression: String;
  const Exc: array of String; const Separator: String; const ContextItem: IXQValue
  ): String;
begin
  Result := EvalStringAll(Expression, False, Exc, Separator, ContextItem);
end;

procedure TXQueryEngineHTML.XPathStringAll(const Expression: String;
  const TheStrings: TStrings; const ContextItem: IXQValue);
begin
  EvalStringAll(Expression, False, TheStrings, ContextItem);
end;

function TXQueryEngineHTML.CSS(const Expression: String; const Tree: TTreeNode): IXQValue;
begin
  Result := Eval(Expression, True, nil, Tree);
end;

function TXQueryEngineHTML.CSS(const Expression: String; const ContextItem: IXQValue
  ): IXQValue;
begin
  Result := Eval(Expression, True, ContextItem);
end;

function TXQueryEngineHTML.CSSString(const Expression: String; const Tree: TTreeNode): String;
begin
  Result := Eval(Expression, True, nil, Tree).toString;
end;

function TXQueryEngineHTML.CSSString(const Expression: String;
  const ContextItem: IXQValue): String;
begin
  Result := Eval(Expression, True, ContextItem).toString;
end;

function TXQueryEngineHTML.CSSStringAll(const Expression: String;
  const Separator: String; const ContextItem: IXQValue): String;
begin
  Result := EvalStringAll(Expression, True, Separator, ContextItem);
end;

function TXQueryEngineHTML.CSSStringAll(const Expression: String;
  const Exc: array of String; const Separator: String; const ContextItem: IXQValue
  ): String;
begin
  Result := EvalStringAll(Expression, True, Exc, Separator, ContextItem);
end;

procedure TXQueryEngineHTML.CSSStringAll(const Expression: String;
  const TheStrings: TStrings; const ContextItem: IXQValue);
begin
  EvalStringAll(Expression, True, TheStrings, ContextItem);
end;

end.
